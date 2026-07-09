import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_enums.dart';
import '../domain/models.dart';
import '../services/audit_service.dart';
import '../utils/app_logger.dart';
import '../utils/parse_utils.dart';
import '../version.dart';
import 'ivra_repository.dart';
import 'offline/network_error_classifier.dart';

class SupabaseIvraRepository implements IvraRepository {
  SupabaseIvraRepository(this._client) {
    _auditService = AuditService(_client);
  }

  final SupabaseClient _client;
  late final AuditService _auditService;

  /// Schema version stamped into every cache envelope. Bump this whenever the
  /// shape of any cached payload changes so entries written by older app
  /// versions are treated as a miss instead of being misinterpreted.
  ///
  /// The effective cache version also incorporates the running [appVersion]
  /// (see [_effectiveCacheVersion]): any app upgrade automatically invalidates
  /// previously cached payloads, so a forgotten manual bump can no longer cause
  /// a new build to misread an old cache shape.
  static const int _cacheSchemaVersion = 1;

  /// Per-resource schema versions. Each cached resource family carries its own
  /// version so that changing the shape of ONE payload only invalidates that
  /// resource's cache, instead of wiping every cached entry. Bump the integer
  /// for a family whenever the shape of its cached payload changes.
  ///
  /// The key is the resource family derived from the cache key by
  /// [_resourceFamily] (the cache key with any trailing `_<id>` suffix
  /// stripped). Families not listed here fall back to [_cacheSchemaVersion].
  static const Map<String, int> _resourceSchemaVersions = <String, int>{
    // 'hotels': 1,
    // 'current_user': 1,
  };

  /// Derives the resource family from a cache [key] by stripping a trailing
  /// `_<id>` segment (e.g. `current_user_<uuid>` -> `current_user`). Keys with
  /// no id suffix are returned unchanged. This lets per-resource versioning
  /// apply across all rows of the same resource.
  static String _resourceFamily(String key) {
    final lastUnderscore = key.lastIndexOf('_');
    if (lastUnderscore <= 0 || lastUnderscore == key.length - 1) return key;
    // Treat the trailing segment as an id only when it is non-trivial (uuids,
    // numeric ids, etc.). A short alpha suffix is kept as part of the family.
    final suffix = key.substring(lastUnderscore + 1);
    final looksLikeId = suffix.length >= 3 &&
        RegExp(r'^[0-9a-fA-F-]+$').hasMatch(suffix);
    return looksLikeId ? key.substring(0, lastUnderscore) : key;
  }

  /// The effective cache version for a given [key]. Combines the resource's own
  /// schema version (falling back to [_cacheSchemaVersion]) with the build's
  /// [appVersion]. Because the app version is still folded in, an app upgrade
  /// is always safe; per-resource versions let a single payload-shape change be
  /// invalidated in isolation without bumping the global namespace.
  static String _effectiveCacheVersionFor(String key) {
    final family = _resourceFamily(key);
    final schema = _resourceSchemaVersions[family] ?? _cacheSchemaVersion;
    return '$schema@$family@$appVersion';
  }

  /// Back-compat global cache version. Retained for call sites/tests that are
  /// not scoped to a specific resource (e.g. the cache-envelope unit tests).
  static String get _cacheVersion => '$_cacheSchemaVersion@$appVersion';

  /// How long a cached offline read remains usable. Past this age the entry is
  /// treated as a miss so we never serve arbitrarily stale data.
  static const Duration _cacheMaxAge = Duration(hours: 24);
  static const Duration _cacheOfflineMaxAge = Duration(days: 30);

  /// Fetches [key] via [fetcher], caching successful results so they can be
  /// served when the device is offline.
  ///
  /// Callers MUST provide a [decode] callback that turns the JSON-decoded cache
  /// payload back into the expected `T`, and may provide [emptyFallback] to
  /// return a safe default (e.g. an empty list) when the device is offline and
  /// nothing has been cached yet. This replaces the previous, fragile approach
  /// of inspecting `T.toString()`, which broke under minification/obfuscation
  /// and with nested generics.
  Future<T> _fetchWithCache<T>(
    String key,
    Future<T> Function() fetcher, {
    required T Function(Object? decoded) decode,
    T Function()? emptyFallback,
  }) async {
    try {
      final data = await fetcher();
      final prefs = await SharedPreferences.getInstance();
      // Wrap the payload in a versioned, timestamped envelope so stale data can
      // be expired and entries from incompatible schema versions can be
      // discarded after an app upgrade.
      final envelope = <String, dynamic>{
        'v': _effectiveCacheVersionFor(key),
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString('cache_$key', jsonEncode(envelope));
      return data;
    } catch (e) {
      if (NetworkErrorClassifier.isOffline(e)) {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_$key');
        final payload = _readCacheEnvelope(
          cached,
          expectedVersion: _effectiveCacheVersionFor(key),
          maxAge: _cacheOfflineMaxAge,
        );
        if (payload != null) {
          return decode(payload);
        }
        // The cache is missing/expired/incompatible but we are offline. Return
        // a safe default when the caller provided one (typically an empty list)
        // to avoid crash screens on un-cached pages.
        if (emptyFallback != null) {
          return emptyFallback();
        }
      }
      rethrow;
    }
  }

  /// Parses a stored cache string and returns the inner payload only when the
  /// envelope is present, the schema version matches [expectedVersion]
  /// (defaulting to the global [_cacheVersion]), and the entry is no older than
  /// [maxAge] (defaulting to [_cacheMaxAge]). Returns `null` for a cache miss:
  /// missing entry, legacy format, version mismatch, or expired entry.
  static Object? _readCacheEnvelope(String? cached,
      {String? expectedVersion, Duration? maxAge}) {
    final wantVersion = expectedVersion ?? _cacheVersion;
    if (cached == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(cached);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    if (!decoded.containsKey('v') ||
        !decoded.containsKey('ts') ||
        !decoded.containsKey('data')) {
      return null;
    }
    final version = decoded['v'];
    if (version is! String || version != wantVersion) return null;
    final ts = decoded['ts'];
    if (ts is! int) return null;
    final ageMillis = DateTime.now().millisecondsSinceEpoch - ts;
    final limit = maxAge ?? _cacheMaxAge;
    if (ageMillis < 0 || ageMillis > limit.inMilliseconds) return null;
    return decoded['data'];
  }

  /// Schema version stamped into cache envelopes. Exposed for tests so they can
  /// construct version-matching (and mismatching) envelopes.
  @visibleForTesting
  static String get cacheVersion => _cacheVersion;

  /// Maximum age of a usable cache entry. Exposed for tests.
  @visibleForTesting
  static Duration get cacheMaxAge => _cacheMaxAge;

  /// Maximum age of a usable offline cache entry. Exposed for tests.
  @visibleForTesting
  static Duration get cacheOfflineMaxAge => _cacheOfflineMaxAge;

  /// Test-only wrapper around [_readCacheEnvelope].
  @visibleForTesting
  static Object? readCacheEnvelopeForTest(String? cached,
          {String? expectedVersion, Duration? maxAge}) =>
      _readCacheEnvelope(cached, expectedVersion: expectedVersion, maxAge: maxAge);

  /// Test-only accessor for the per-resource effective cache version.
  @visibleForTesting
  static String effectiveCacheVersionForTest(String key) =>
      _effectiveCacheVersionFor(key);

  /// Decodes a cached JSON payload into a `List<Map<String, dynamic>>`.
  static List<Map<String, dynamic>> _decodeMapList(Object? decoded) {
    if (decoded is List) {
      return decoded
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList(growable: false);
    }
    throw StateError('Cached JSON payload is not a List (got ${decoded.runtimeType}).');
  }

  /// Decodes a cached JSON payload into a `Map<String, dynamic>`.
  static Map<String, dynamic> _decodeMap(Object? decoded) {
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw StateError('Cached JSON payload is not a Map (got ${decoded.runtimeType}).');
  }

  @override
  Future<void> clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _clearRefillEventsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_recent_refill_events_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _clearInventoryCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_inventory_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _clearRoomProductsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) =>
      k.startsWith('cache_room_products_') ||
      k.startsWith('cache_rooms_') ||
      k.startsWith('cache_dashboard_metrics_')
    ).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  @override
  Future<UserProfile> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    final data = await _fetchCurrentUserProfile(user.id);
    final profile = UserProfile.fromMap(data);
    if (!profile.isActive) {
      throw StateError('This account has been deactivated.');
    }
    return profile;
  }

  Future<Map<String, dynamic>> _fetchCurrentUserProfile(String userId) async {
    try {
      // Automatically accept any pending team invitations for this user's email.
      // This allows users (especially Google Auth users) to seamlessly join their
      // team immediately upon their first sign-in, without needing to click
      // through an email link if their email matches a pending invite.
      await _client.rpc('auto_accept_invitations');
    } catch (_) {}

    Future<Map<String, dynamic>> fetch() => _fetchWithCache(
          'current_user_$userId',
          () => _client.from('profiles').select().eq('id', userId).single(),
          decode: _decodeMap,
        );
    try {
      return await fetch();
    } catch (e) {
      // On a cold start the saved access token can be momentarily expired, so
      // the first profile request fails with a transient JWT/network error
      // before Supabase auto-refreshes the session. Give the refresh a beat
      // and retry once before surfacing the failure to the UI.
      if (_isRetriableProfileError(e)) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        return await fetch();
      }
      rethrow;
    }
  }

  bool _isRetriableProfileError(Object error) {
    if (error is PostgrestException && error.code == 'PGRST116') {
      // If a user is logged in, a temporary RLS propagation delay can make the profile query
      // return 0 rows (PGRST116) right after login. Allowing a single retry solves this race condition.
      return _client.auth.currentUser != null;
    }
    return NetworkErrorClassifier.isRetriable(error);
  }

  @override
  Future<void> updateCurrentUserProfile({required String fullName}) async {
    await _client.rpc('update_current_profile', params: {
      'p_full_name': fullName,
    });
    await _auditService.logAction(
      'Updated current user profile',
      details: {'full_name': fullName},
    );
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    UserRole? role,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName,
    };
    if (role != null) {
      payload['role'] = role.value;
    }

    await _client.from('profiles').update(payload).eq('id', userId);
    await _auditService.logAction('Updated user profile', details: {'user_id': userId, 'full_name': fullName, 'role': role?.value});
  }

  @override
  Future<void> changeCurrentUserPassword({required String password}) async {
    await _client.auth.updateUser(UserAttributes(password: password));
    await _auditService.logAction('Changed current user password');
  }

  @override
  Future<String> updateUserAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final path = '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(imageBytes),
          fileOptions: FileOptions(
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    // Permission enforcement (self / hotel manager same hotel / app admin or
    // manager) happens inside this SECURITY DEFINER RPC.
    await _client.rpc('update_user_avatar', params: {
      'p_user_id': userId,
      'p_avatar_url': publicUrl,
    });

    await _auditService.logAction(
      'Updated user avatar',
      details: {'user_id': userId},
    );
    return publicUrl;
  }

  @override
  Future<DashboardMetrics> dashboardMetrics({String? hotelId}) async {
    final Map<String, dynamic> params = {};
    if (hotelId != null) {
      params['p_hotel_id'] = hotelId;
    }
    final data = await _fetchWithCache(
      'dashboard_metrics_${hotelId ?? 'all'}',
      () => _client
          .rpc('dashboard_metrics', params: params.isNotEmpty ? params : null)
          .single(),
      decode: _decodeMap,
    );

    return DashboardMetrics(
      hotelCount: asInt(data['hotel_count']),
      roomCount: asInt(data['room_count']),
      pendingApprovals: asInt(data['pending_approvals']),
      openAlerts: asInt(data['open_alerts']),
      bottlesToReplace: asInt(data['bottles_to_replace']),
      lowStockProducts: asInt(data['low_stock_products']),
    );
  }

  @override
  Future<List<Hotel>> hotels() async {
    final rows = await _fetchWithCache(
      'hotels',
      () => _client.from('hotel_summaries').select().order('name'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<Hotel>((row) => Hotel.fromMap(row)).toList();
  }

  @override
  Future<List<UserProfile>> teamMembers({String? hotelId}) async {
    var query = _client.from('profiles').select();
    if (hotelId != null) {
      query = query.or('hotel_id.eq.$hotelId,hotel_id.is.null');
    }
    final rows = await _fetchWithCache(
      'team_members_${hotelId ?? 'all'}',
      () => query.order('full_name'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<UserProfile>((row) => UserProfile.fromMap(row)).toList();
  }

  @override
  Future<List<TeamInvitation>> teamInvitations({String? hotelId}) async {
    var query = _client.from('team_invitation_summaries').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'team_invitations_${hotelId ?? 'all'}',
      () => query.eq('status', 'pending').order('created_at', ascending: false),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows
        .map<TeamInvitation>((row) => TeamInvitation.fromMap(row))
        .toList();
  }

  @override
  Future<List<AuditLog>> fetchAuditLogs() async {
    final rows = await _fetchWithCache(
      'audit_logs',
      () => _client.from('audit_logs').select().order('created_at', ascending: false).limit(200),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<AuditLog>((row) => AuditLog.fromMap(row)).toList();
  }

  @override
  Future<void> clearAuditLogs() async {
    await _client.rpc('clear_audit_logs');
    await _auditService.logAction('Cleared audit logs');
  }

  @override
  Future<List<Product>> products() async {
    final rows = await _fetchWithCache(
      'products',
      () => _client.from('products').select().order('default_name'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<Product>((row) => Product.fromMap(row)).toList();
  }

  @override
  Future<List<RoomInfo>> rooms({String? hotelId}) async {
    var query = _client.from('room_summaries').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'rooms_${hotelId ?? 'all'}',
      () => query.order('floor_number').order('room_number'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<RoomInfo>((row) => RoomInfo.fromMap(row)).toList();
  }

  @override
  Future<List<RoomProduct>> roomProducts({
    String? hotelId,
    String? roomId,
  }) async {
    var query = _client.from('room_product_summaries').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    if (roomId != null) query = query.eq('room_id', roomId);
    final rows = await _fetchWithCache(
      'room_products_${hotelId ?? 'all'}_${roomId ?? 'all'}',
      () => query.order('room_number'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<RoomProduct>(_roomProductFromMap).toList();
  }

  @override
  Future<List<InventoryItem>> inventory({String? hotelId}) async {
    var query = _client.from('inventory_summaries').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'inventory_${hotelId ?? 'all'}',
      () => query.order('product_name'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<InventoryItem>(_inventoryFromMap).toList();
  }

  @override
  Future<List<HousekeeperAllocation>> fetchHousekeeperAllocations({String? housekeeperId, String? hotelId}) async {
    var query = _client.from('housekeeper_allocations').select('*, products(*)');
    if (housekeeperId != null) {
      query = query.eq('housekeeper_id', housekeeperId);
    }
    if (hotelId != null) {
      query = query.eq('hotel_id', hotelId);
    }
    final rows = await query;
    return rows.map<HousekeeperAllocation?>((row) {
      if (row['products'] == null) {
        AppLogger.error('Missing product in housekeeper allocation row: $row');
        return null;
      }
      final productMap = row['products'] as Map<String, dynamic>? ?? {};
      final flattened = Map<String, dynamic>.from(row);
      productMap.forEach((key, val) {
        if (key == 'id') {
          flattened['product_id'] = val;
        } else {
          flattened[key] = val;
        }
      });
      return HousekeeperAllocation(
        id: asString(flattened['id']),
        housekeeperId: asString(flattened['housekeeper_id']),
        hotelId: asString(flattened['hotel_id']),
        product: _joinedProductFromMap(flattened),
        fullBottles: asInt(flattened['full_bottles']),
        emptyBottles: asInt(flattened['empty_bottles']),
        fullBidons: asInt(flattened['full_bidons']),
        openBidons: asInt(flattened['open_bidons']),
        emptyBidons: asInt(flattened['empty_bidons']),
        openBidonVolumeLeftMl: asDouble(flattened['open_bidon_volume_left_ml']),
      );
    }).whereType<HousekeeperAllocation>().toList();
  }

  @override
  Future<List<HousekeeperStockEvent>> fetchHousekeeperStockEvents({
    String? housekeeperId,
    String? productId,
    String? hotelId,
    int limit = 100,
  }) async {
    var query = _client
        .from('housekeeper_stock_events')
        // room_number lives on rooms, reached through room_products.room_id.
        .select('*, products(*), room_products(rooms(room_number))');
    if (housekeeperId != null) {
      query = query.eq('housekeeper_id', housekeeperId);
    }
    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    if (hotelId != null) {
      query = query.eq('hotel_id', hotelId);
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return rows.map<HousekeeperStockEvent?>((row) {
      if (row['products'] == null) {
        AppLogger.error('Missing product in housekeeper stock event row: $row');
        return null;
      }
      final productMap = row['products'] as Map<String, dynamic>? ?? {};
      final flattened = Map<String, dynamic>.from(row);
      productMap.forEach((key, val) {
        if (key == 'id') {
          flattened['product_id'] = val;
        } else {
          flattened[key] = val;
        }
      });
      final roomProductMap = row['room_products'] as Map<String, dynamic>?;
      final roomMap = roomProductMap?['rooms'] as Map<String, dynamic>?;
      return HousekeeperStockEvent(
        id: asString(flattened['id']),
        hotelId: asString(flattened['hotel_id']),
        housekeeperId: asString(flattened['housekeeper_id']),
        product: _joinedProductFromMap(flattened),
        eventType: housekeeperStockEventTypeFromDb(asString(flattened['event_type'])),
        fullBottlesDelta: asInt(flattened['full_bottles_delta']),
        emptyBottlesDelta: asInt(flattened['empty_bottles_delta']),
        fullBidonsDelta: asInt(flattened['full_bidons_delta']),
        openBidonsDelta: asInt(flattened['open_bidons_delta']),
        emptyBidonsDelta: asInt(flattened['empty_bidons_delta']),
        volumeDeltaMl: asDouble(flattened['volume_delta_ml']),
        createdAt: DateTime.tryParse(asString(flattened['created_at']))?.toLocal() ?? DateTime.now(),
        roomProductId: flattened['room_product_id'] == null ? null : asString(flattened['room_product_id']),
        roomNumber: roomMap == null ? null : asString(roomMap['room_number']),
        notes: flattened['notes'] == null ? null : asString(flattened['notes']),
      );
    }).whereType<HousekeeperStockEvent>().toList();
  }

  @override
  Future<void> checkoutHousekeeperStock({
    required String housekeeperId,
    required String productId,
    required int fullBottles,
    required int fullBidons,
  }) async {
    await _client.rpc('checkout_housekeeper_stock', params: {
      'p_housekeeper_id': housekeeperId,
      'p_product_id': productId,
      'p_full_bottles': fullBottles,
      'p_full_bidons': fullBidons,
    });
    await _auditService.logAction('Checked out housekeeper stock', details: {
      'housekeeper_id': housekeeperId,
      'product_id': productId,
      'full_bottles': fullBottles,
      'full_bidons': fullBidons,
    });
  }

  @override
  Future<void> returnHousekeeperStock({
    required String housekeeperId,
    required String productId,
    required int fullBottles,
    required int emptyBottles,
    required int fullBidons,
    required int openBidons,
    required int emptyBidons,
    required double openBidonVolumeLeftMl,
  }) async {
    await _client.rpc('return_housekeeper_stock', params: {
      'p_housekeeper_id': housekeeperId,
      'p_product_id': productId,
      'p_full_bottles': fullBottles,
      'p_empty_bottles': emptyBottles,
      'p_full_bidons': fullBidons,
      'p_open_bidons': openBidons,
      'p_empty_bidons': emptyBidons,
      'p_open_bidon_volume_left_ml': openBidonVolumeLeftMl,
    });
    await _auditService.logAction('Returned housekeeper stock', details: {
      'housekeeper_id': housekeeperId,
      'product_id': productId,
      'full_bottles': fullBottles,
      'empty_bottles': emptyBottles,
      'full_bidons': fullBidons,
      'open_bidons': openBidons,
      'empty_bidons': emptyBidons,
      'open_bidon_volume_left_ml': openBidonVolumeLeftMl,
    });
  }

  @override
  Future<List<SuggestedOrder>> suggestedOrders({String? hotelId}) async {
    var query = _client.from('suggested_order_quantities').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'suggested_orders_${hotelId ?? 'all'}',
      () => query.order('product_name'),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<SuggestedOrder>(_suggestedOrderFromMap).toList();
  }

  @override
  Future<List<ApprovalRequest>> approvalRequests({String? hotelId}) async {
    var query = _client
        .from('approval_request_summaries')
        .select()
        .eq('status', 'pending');
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'approval_requests_${hotelId ?? 'all'}',
      () => query.order('requested_at', ascending: false),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<ApprovalRequest>(_approvalFromMap).toList();
  }

  @override
  Future<List<AlertItem>> alerts({String? hotelId}) async {
    var query = _client.from('alerts').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'alerts_${hotelId ?? 'all'}',
      () => query.order('created_at', ascending: false),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<AlertItem>(_alertFromMap).toList();
  }

  @override
  Future<List<RefillEvent>> recentRefillEvents({String? hotelId}) async {
    var query = _client.from('refill_events').select('*, profiles!refill_events_performed_by_profile_fkey(full_name)');
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'recent_refill_events_${hotelId ?? 'all'}',
      () => query.order('occurred_at', ascending: false).limit(500),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<RefillEvent>(_refillEventFromMap).toList();
  }

  @override
  Future<List<InventoryEvent>> recentInventoryEvents({String? hotelId}) async {
    var query = _client.from('inventory_events').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'recent_inventory_events_${hotelId ?? 'all'}',
      () => query.order('occurred_at', ascending: false).limit(500),
      decode: _decodeMapList,
      emptyFallback: () => const <Map<String, dynamic>>[],
    );
    return rows.map<InventoryEvent>(_inventoryEventFromMap).toList();
  }


  @override
  Future<Set<String>> appliedClientRequestIds({String? hotelId}) async {
    final ids = <String>{};

    Future<void> collect(String table, String cacheKey) async {
      try {
        var query = _client
            .from(table)
            .select('client_request_id')
            .not('client_request_id', 'is', null);
        if (hotelId != null) query = query.eq('hotel_id', hotelId);
        final rows = await _fetchWithCache(
          'applied_request_ids_${cacheKey}_${hotelId ?? 'all'}',
          () => query,
          decode: _decodeMapList,
          emptyFallback: () => const <Map<String, dynamic>>[],
        );
        for (final row in rows) {
          final value = row['client_request_id'];
          if (value is String && value.isNotEmpty) ids.add(value);
        }
      } catch (e, st) {
        // Reconciliation is best-effort and MUST NOT throw: if we cannot reach
        // the server (e.g. genuinely offline), we fall back to overlaying
        // everything so the offline-first UX is preserved. Persistent failures
        // are still routed to the logging sink so they are observable instead
        // of silently swallowed.
        AppLogger.error(
          e,
          stackTrace: st,
          context: 'appliedClientRequestIds reconcile failed for $table',
        );
      }
    }

    await collect('refill_events', 'refill_events');
    await collect('inventory_events', 'inventory_events');
    return ids;
  }

  @override
  Future<void> createHotel({
    required String name,
    String legalName = '',
    required String city,
    required String country,
    required String contactName,
    required String email,
    required String phone,
    String address = '',
    String notes = '',
  }) async {
    await _client.from('hotels').insert({
      'name': name,
      'legal_name': legalName,
      'city': city,
      'country': country,
      'contact_name': contactName,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
    });
    await _auditService.logAction('Created hotel', details: {'name': name});
  }

  @override
  Future<void> deleteHotel(String hotelId) async {
    await _client.from('hotels').delete().eq('id', hotelId);
    await _auditService.logAction('Deleted hotel', details: {'hotel_id': hotelId});
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('id', roomId);
    await _auditService.logAction('Deleted room', details: {'room_id': roomId});
  }

  @override
  Future<void> deleteFloor(String floorId) async {
    await _client.from('floors').delete().eq('id', floorId);
    await _auditService.logAction('Deleted floor', details: {'floor_id': floorId});
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _client.rpc('delete_user', params: {'target_user_id': userId});
    await _auditService.logAction('Deleted user', details: {'user_id': userId});
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    await _client.from('alerts').delete().eq('id', alertId);
    await _auditService.logAction('Deleted alert', details: {'alert_id': alertId});
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
    await _auditService.logAction('Deleted product', details: {'product_id': productId});
  }

  @override
  Future<void> createRoomsFromTemplate({
    required String hotelId,
    required int floorNumber,
    required int firstRoomNumber,
    required int roomCount,
    required List<String> productIds,
    bool autoAdjustInventory = false,
  }) async {
    await _client.rpc('create_rooms_from_template', params: {
      'p_hotel_id': hotelId,
      'p_floor_number': floorNumber,
      'p_first_room_number': firstRoomNumber,
      'p_room_count': roomCount,
      'p_product_ids': productIds,
      'p_auto_adjust_inventory': autoAdjustInventory,
    });
    await _auditService.logAction('Created rooms from template', details: {'hotel_id': hotelId, 'floor_number': floorNumber, 'room_count': roomCount});
  }

  @override
  Future<void> inviteTeamMember({
    required String email,
    required String fullName,
    required String role,
    String? hotelId,
  }) async {
    await _client.rpc('create_team_invitation', params: {
      'p_email': email,
      'p_full_name': fullName,
      'p_role': role,
      'p_hotel_id': hotelId,
    });
    
    await _auditService.logAction('Invited team member', details: {
      'email': email,
      'role': role,
      'hotel_id': hotelId,
    });
  }

  @override
  Future<TeamInvitation?> invitationByToken({required String token}) async {
    final result = await _client.rpc('get_team_invitation_by_token', params: {
      'p_token': token,
    });
    if (result is List && result.isNotEmpty) {
      return TeamInvitation.fromMap(
        Map<String, dynamic>.from(result.first as Map),
      );
    }
    if (result is Map) {
      return TeamInvitation.fromMap(Map<String, dynamic>.from(result));
    }
    return null;
  }

  @override
  Future<void> acceptTeamInvitation({required String token}) async {
    try {
      await _client.rpc('accept_team_invitation', params: {
        'p_token': token,
      });
    } catch (e) {
      // The auto_accept_invitations RPC (called during currentUser()) may have
      // already accepted the invitation before we got here. In that case the
      // accept_team_invitation RPC raises "Pending invitation not found".
      // Fall back to auto_accept_invitations to ensure the profile and
      // invitation are properly updated regardless of ordering.
      final message = e is PostgrestException ? e.message : e.toString();
      if (message.contains('not found')) {
        await _client.rpc('auto_accept_invitations');
      } else {
        rethrow;
      }
    }
    await _auditService.logAction('Accepted team invitation', details: {});
  }

  @override
  Future<void> cancelTeamInvitation({required String invitationId}) async {
    await _client.rpc('cancel_team_invitation', params: {
      'p_invitation_id': invitationId,
    });
    await _auditService.logAction('Canceled team invitation', details: {'invitation_id': invitationId});
  }

  @override
  Future<void> resendTeamInvitation({required String invitationId}) async {
    await _client.rpc('resend_team_invitation', params: {
      'p_invitation_id': invitationId,
    });
    await _auditService.logAction('Resent team invitation', details: {'invitation_id': invitationId});
  }

  @override
  Future<void> setTeamMemberActive({
    required String userId,
    required bool isActive,
  }) async {
    await _client.rpc('set_team_member_active', params: {
      'p_user_id': userId,
      'p_is_active': isActive,
    });
    
    await _auditService.logAction('Set team member active status', details: {
      'user_id': userId,
      'is_active': isActive,
    });
  }

  @override
  Future<void> createProduct({
    required String sku,
    required String nameEn,
    required String nameFr,
    required String nameAr,
    String nameIt = '',
    required int bottleVolumeMl,
    required int bidonVolumeMl,
    required int maxRefillCount,
    required int maxBottleAgeDays,
    required int lowBottleThreshold,
    required int lowBidonThreshold,
    String? imageUrl,
    BottleType bottleType = BottleType.withPump,
    RefillType refillType = RefillType.refillable,
  }) async {
    await _client.from('products').insert({
      'sku': sku,
      'default_name': nameEn,
      'name_en': nameEn,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'name_it': nameIt.isEmpty ? nameEn : nameIt,
      'bottle_volume_ml': bottleVolumeMl,
      'bidon_volume_ml': bidonVolumeMl,
      'max_refill_count': maxRefillCount,
      'max_bottle_age_days': maxBottleAgeDays,
      'low_bottle_threshold': lowBottleThreshold,
      'low_bidon_threshold': lowBidonThreshold,
      'image_url': imageUrl,
      'bottle_type': bottleType.value,
      'refill_type': refillType.value,
    });
    await _auditService.logAction('Created product', details: {'sku': sku});
  }

  @override
  Future<void> updateProduct({
    required String productId,
    required String sku,
    required String nameEn,
    required String nameFr,
    required String nameAr,
    String nameIt = '',
    required int bottleVolumeMl,
    required int bidonVolumeMl,
    required int maxRefillCount,
    required int maxBottleAgeDays,
    required int lowBottleThreshold,
    required int lowBidonThreshold,
    String? imageUrl,
    BottleType bottleType = BottleType.withPump,
    RefillType refillType = RefillType.refillable,
  }) async {
    await _client.from('products').update({
      'sku': sku,
      'default_name': nameEn,
      'name_en': nameEn,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'name_it': nameIt.isEmpty ? nameEn : nameIt,
      'bottle_volume_ml': bottleVolumeMl,
      'bidon_volume_ml': bidonVolumeMl,
      'max_refill_count': maxRefillCount,
      'max_bottle_age_days': maxBottleAgeDays,
      'low_bottle_threshold': lowBottleThreshold,
      'low_bidon_threshold': lowBidonThreshold,
      'image_url': imageUrl,
      'bottle_type': bottleType.value,
      'refill_type': refillType.value,
    }).eq('id', productId);
    await _auditService.logAction('Updated product', details: {'product_id': productId});
  }

  @override
  Future<void> recordRefill({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
  }) async {
    await _client.rpc('record_refill', params: {
      'p_room_product_id': roomProductId,
      'p_notes': notes,
      'p_client_request_id': clientRequestId,
    });
    await _clearRefillEventsCache();
    await _clearInventoryCache();
    await _auditService.logAction('Recorded refill', details: {'room_product_id': roomProductId});
  }

  @override
  Future<void> undoRefill({
    required String refillEventId,
    String? clientRequestId,
  }) async {
    await _client.rpc('undo_refill', params: {
      'p_refill_event_id': refillEventId,
      'p_client_request_id': clientRequestId,
    });
    await _clearRefillEventsCache();
    await _clearInventoryCache();
    await _auditService.logAction('Undid refill', details: {'refill_event_id': refillEventId});
  }

  @override
  Future<void> requestCorrection({
    required String refillEventId,
    required String reason,
    String? clientRequestId,
  }) async {
    await _client.rpc('request_refill_correction', params: {
      'p_refill_event_id': refillEventId,
      'p_reason': reason,
      'p_client_request_id': clientRequestId,
    });
    await _clearRefillEventsCache();
    await _clearInventoryCache();
    await _auditService.logAction('Requested stock correction', details: {'refill_event_id': refillEventId});
  }

  @override
  Future<void> replaceBottle({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
    bool autoAdjustInventory = false,
  }) async {
    await _client.rpc('replace_bottle', params: {
      'p_room_product_id': roomProductId,
      'p_notes': notes,
      'p_client_request_id': clientRequestId,
      'p_auto_adjust_inventory': autoAdjustInventory,
    });
    await _clearRefillEventsCache();
    await _clearInventoryCache();
    await _auditService.logAction('Replaced bottle', details: {'room_product_id': roomProductId});
  }

  @override
  Future<String?> submitChangeRequest({
    required String hotelId,
    required String title,
    required String targetTable,
    required String targetId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
    String? clientRequestId,
  }) async {
    final result = await _client.rpc('submit_change_request', params: {
      'p_hotel_id': hotelId,
      'p_title': title,
      'p_target_table': targetTable,
      'p_target_id': targetId,
      'p_action': 'update',
      'p_old_data': oldData,
      'p_new_data': newData,
      'p_client_request_id': clientRequestId,
    }).then((value) => value?.toString());
    await _auditService.logAction('Submitted change request', details: {
      'target_table': targetTable, 
      'target_id': targetId
    });
    return result;
  }

  @override
  Future<void> recordStockAdjustment({
    required String hotelId,
    required String productId,
    int fullBottlesDelta = 0,
    int emptyBottlesDelta = 0,
    int fullBidonsDelta = 0,
    int openBidonsDelta = 0,
    int emptyBidonsDelta = 0,
    String reason = '',
    String? clientRequestId,
  }) async {
    await _client.rpc('record_stock_adjustment', params: {
      'p_hotel_id': hotelId,
      'p_product_id': productId,
      'p_full_bottles_delta': fullBottlesDelta,
      'p_empty_bottles_delta': emptyBottlesDelta,
      'p_full_bidons_delta': fullBidonsDelta,
      'p_open_bidons_delta': openBidonsDelta,
      'p_empty_bidons_delta': emptyBidonsDelta,
      'p_reason': reason,
      'p_client_request_id': clientRequestId,
    });
    await _clearInventoryCache();
    await _auditService.logAction('Recorded stock adjustment', details: {'hotel_id': hotelId, 'product_id': productId});
  }

  @override
  Future<void> approveRequest({
    required String approvalRequestId,
    String? notes,
  }) async {
    await _client.rpc('approve_change_request', params: {
      'p_request_id': approvalRequestId,
      'p_notes': notes,
    });
    await _clearRefillEventsCache();
    await _clearInventoryCache();
    await _auditService.logAction('Approved change request', details: {
      'request_id': approvalRequestId,
    });
  }

  @override
  Future<void> rejectRequest({
    required String approvalRequestId,
    String? notes,
  }) async {
    await _client.rpc('reject_change_request', params: {
      'p_request_id': approvalRequestId,
      'p_notes': notes,
    });
    await _auditService.logAction('Rejected change request', details: {'request_id': approvalRequestId});
  }

  @override
  Future<int> refreshSmartAlerts({String? hotelId}) async {
    final result = await _client.rpc('refresh_smart_alerts', params: {
      'p_hotel_id': hotelId,
    });
    final created = switch (result) {
      int value => value,
      num value => value.toInt(),
      _ => int.tryParse('$result') ?? 0,
    };
    await _auditService.logAction('Refreshed smart alerts', details: {
      'hotel_id': hotelId,
      'created_count': created,
    });
    return created;
  }

  @override
  Future<void> resolveAlert({required String alertId}) async {
    await _client.rpc('resolve_alert', params: {
      'p_alert_id': alertId,
    });
    
    await _auditService.logAction('Resolved alert', details: {
      'alert_id': alertId,
    });
  }

  @override
  Future<List<Hotel>> userHotels({required String userId}) async {
    final rows = await _client.rpc('get_user_hotels', params: {
      'p_user_id': userId,
    });
    if (rows is! List) return [];

    // The RPC only returns ids/names. Enrich with the full hotel rows the app
    // already exposes via hotels() (backed by the hotel_summaries view) so
    // city/country/contact/etc. are populated, while preserving the RPC's
    // order. If an id isn't present in hotels() (or hotels() fails), fall back
    // to a minimal Hotel so nothing is dropped.
    Map<String, Hotel> fullById = const {};
    try {
      final all = await hotels();
      fullById = {for (final hotel in all) hotel.id: hotel};
    } catch (_) {
      // Best-effort enrichment: fall back to minimal Hotels below.
    }

    return rows.map<Hotel>((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['hotel_id'] as String;
      final full = fullById[id];
      if (full != null) return full;
      return Hotel(
        id: id,
        name: (map['hotel_name'] ?? '') as String,
        city: '',
        country: '',
        contactName: '',
        email: '',
        phone: '',
        roomCount: 0,
        pendingEdits: 0,
      );
    }).toList();
  }

  @override
  Future<void> assignUserHotel({
    required String userId,
    required String hotelId,
  }) async {
    await _client.rpc('assign_user_hotel', params: {
      'p_user_id': userId,
      'p_hotel_id': hotelId,
    });
    await _auditService.logAction('Assigned user to hotel', details: {'user_id': userId, 'hotel_id': hotelId});
  }

  @override
  Future<void> unassignUserHotel({
    required String userId,
    required String hotelId,
  }) async {
    await _client.rpc('unassign_user_hotel', params: {
      'p_user_id': userId,
      'p_hotel_id': hotelId,
    });
    await _auditService.logAction('Unassigned user from hotel', details: {'user_id': userId, 'hotel_id': hotelId});
  }

  RoomProduct _roomProductFromMap(Map<String, dynamic> map) {
    return RoomProduct(
      id: asString(map['id']),
      hotelId: asString(map['hotel_id']),
      roomId: asString(map['room_id']),
      roomNumber: asString(map['room_number']),
      floorNumber: asInt(map['floor_number']),
      product: _joinedProductFromMap(map),
      refillCount: asInt(map['refill_count']),
      lastRefillAt: asNullableDateTime(map['last_refill_at']),
      bottleStartedAt: asDateTime(map['bottle_started_at']),
      status: BottleStatus.values.firstWhere(
        (item) => item.value == map['status'],
        orElse: () => BottleStatus.active,
      ),
    );
  }

  InventoryItem _inventoryFromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: asString(map['id']),
      hotelId: asString(map['hotel_id']),
      product: _joinedProductFromMap(map),
      fullBottles: asInt(map['full_bottles']),
      emptyBottles: asInt(map['empty_bottles']),
      fullBidons: asInt(map['full_bidons']),
      openBidons: asInt(map['open_bidons']),
      emptyBidons: asInt(map['empty_bidons']),
      openBidonVolumeLeftMl: asDouble(map['open_bidon_volume_left_ml']),
    );
  }

  SuggestedOrder _suggestedOrderFromMap(Map<String, dynamic> map) {
    return SuggestedOrder(
      hotelId: asString(map['hotel_id']),
      product: _joinedProductFromMap(map),
      bottlesToOrder: asInt(map['bottles_to_order']),
      bidonsToOrder: asInt(map['bidons_to_order']),
      bottlesToRecycle: asInt(map['bottles_to_recycle']),
    );
  }

  ApprovalRequest _approvalFromMap(Map<String, dynamic> map) {
    return ApprovalRequest(
      id: asString(map['id']),
      hotelId: asString(map['hotel_id']),
      title: asString(map['title']),
      targetId: asNullableString(map['target_id']),
      targetTable: asString(map['target_table']),
      status: ApprovalStatus.values.firstWhere(
        (item) => item.value == map['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      requestedByName: asString(map['requested_by_name']),
      requestedAt: asDateTime(map['requested_at']),
      oldValue: asString(map['old_value']),
      newValue: asString(map['new_value']),
      oldData: asStringMap(map['old_data']),
      newData: asStringMap(map['new_data']),
    );
  }

  AlertItem _alertFromMap(Map<String, dynamic> map) {
    return AlertItem(
      id: asString(map['id']),
      hotelId: asString(map['hotel_id']),
      roomProductId: asNullableString(map['room_product_id']),
      productId: asNullableString(map['product_id']),
      type: AlertType.values.firstWhere(
        (item) => item.value == map['alert_type'],
        orElse: () => AlertType.pendingApproval,
      ),
      severity: asInt(map['severity'], fallback: 1),
      title: asString(map['title']),
      body: asString(map['body']),
      createdAt: asDateTime(map['created_at']),
      isResolved: asBool(map['is_resolved']),
    );
  }

  RefillEvent _refillEventFromMap(Map<String, dynamic> map) {
    final profileMap = map['profiles'] as Map<String, dynamic>?;
    final performedByName = profileMap?['full_name'] as String?;
    return RefillEvent(
      id: asString(map['id']),
      roomProductId: asString(map['room_product_id']),
      type: RefillEventType.values.firstWhere(
        (item) => item.value == map['event_type'],
        orElse: () => RefillEventType.refill,
      ),
      previousRefillCount: asInt(map['previous_refill_count']),
      newRefillCount: asInt(map['new_refill_count']),
      occurredAt: asDateTime(map['occurred_at']),
      performedBy: asString(map['performed_by']),
      performedByName: performedByName,
      notes: asNullableString(map['notes']),
      clientRequestId: asNullableString(map['client_request_id']),
      proofPhotoUrl: asNullableString(map['proof_photo_url']),
    );
  }

  InventoryEvent _inventoryEventFromMap(Map<String, dynamic> map) {
    return InventoryEvent(
      id: asString(map['id']),
      hotelId: asString(map['hotel_id']),
      productId: asString(map['product_id']),
      fullBottlesDelta: asInt(map['full_bottles_delta']),
      emptyBottlesDelta: asInt(map['empty_bottles_delta']),
      fullBidonsDelta: asInt(map['full_bidons_delta']),
      openBidonsDelta: asInt(map['open_bidons_delta']),
      emptyBidonsDelta: asInt(map['empty_bidons_delta']),
      reason: asString(map['reason']),
      performedBy: asString(map['performed_by']),
      occurredAt: asDateTime(map['occurred_at']),
      clientRequestId: asNullableString(map['client_request_id']),
    );
  }


  Product _joinedProductFromMap(Map<String, dynamic> map) {
    return Product(
      id: asString(map['product_id']),
      sku: asString(map['sku']),
      nameEn: asString(map['name_en']),
      nameFr: asString(map['name_fr']),
      nameAr: asString(map['name_ar']),
      nameIt: asString(map['name_it'], fallback: asString(map['name_en'])),
      bottleVolumeMl: asInt(map['bottle_volume_ml'], fallback: 1000),
      bidonVolumeMl: asInt(map['bidon_volume_ml'], fallback: 5000),
      maxRefillCount: asInt(map['max_refill_count']),
      maxBottleAgeDays: asInt(map['max_bottle_age_days']),
      lowBottleThreshold: asInt(map['low_bottle_threshold']),
      lowBidonThreshold: asInt(map['low_bidon_threshold']),
      imageUrl: asNullableString(map['image_url']),
      bottleType: BottleType.fromValue(asString(map['bottle_type'], fallback: 'with_pump')),
      refillType: RefillType.fromValue(asString(map['refill_type'], fallback: 'refillable')),
    );
  }

  @override
  Future<List<String>> fetchRoles() async {
    final List<dynamic> data = await _client
        .from('roles')
        .select('name')
        .order('name', ascending: true);
    return data.map<String>((row) => row['name'] as String).toList();
  }

  @override
  Future<Map<String, Set<String>>> fetchRolePermissions() async {
    final List<String> roles = await fetchRoles();
    final Map<String, Set<String>> matrix = {
      for (final r in roles) r: {},
    };

    final List<dynamic> data = await _client
        .from('role_permissions')
        .select('role, permission, is_enabled');
    
    for (final row in data) {
      final role = row['role'] as String;
      final permission = row['permission'] as String;
      final isEnabled = row['is_enabled'] as bool;
      if (isEnabled) {
        matrix.putIfAbsent(role, () => {}).add(permission);
      }
    }
    return matrix;
  }

  @override
  Future<List<String>> fetchAllPermissions() async {
    final List<dynamic> data = await _client
        .from('role_permissions')
        .select('permission')
        .order('permission', ascending: true);
    final permissions = data.map<String>((row) => row['permission'] as String).toSet().toList();
    permissions.sort();
    return permissions;
  }

  @override
  Future<void> updateRolePermission({
    required String role,
    required String permission,
    required bool isEnabled,
  }) async {
    await _client.from('role_permissions').upsert({
      'role': role,
      'permission': permission,
      'is_enabled': isEnabled,
    });
    await _auditService.logAction(
      'Updated role permission',
      details: {
        'role': role,
        'permission': permission,
        'is_enabled': isEnabled,
      },
    );
  }

  @override
  Future<void> createRole({
    required String name,
    String? description,
  }) async {
    await _client.from('roles').insert({
      'name': name,
      'description': description ?? '',
    });
    await _auditService.logAction(
      'Created custom role',
      details: {
        'role': name,
        'description': description ?? '',
      },
    );
  }

  @override
  Future<void> addProductToRoom({
    required String hotelId,
    required String floor,
    required String roomNumber,
    required String productSku,
    bool autoAdjustInventory = false,
    String? deductFromHousekeeperId,
  }) async {
    // 1. Fetch products to find the target product ID
    final prodList = await products();
    final product = prodList.where((p) => p.sku.toLowerCase() == productSku.toLowerCase()).firstOrNull;
    if (product == null) {
      throw Exception('Product SKU $productSku not found');
    }

    final floorNum = int.tryParse(floor) ?? 0;
    // 2. Fetch or create floor
    final floorResult = await _client.from('floors').select('id').eq('hotel_id', hotelId).eq('floor_number', floorNum).maybeSingle();
    String floorId;
    if (floorResult == null) {
      final newFloor = await _client.from('floors').insert({
        'hotel_id': hotelId,
        'floor_number': floorNum,
        'name': 'Floor $floorNum',
      }).select('id').single();
      floorId = asString(newFloor['id']);
    } else {
      floorId = asString(floorResult['id']);
    }

    // 3. Fetch or create room
    final roomResult = await _client.from('rooms').select('id').eq('hotel_id', hotelId).eq('room_number', roomNumber).maybeSingle();
    String roomId;
    if (roomResult == null) {
      final newRoom = await _client.from('rooms').insert({
        'hotel_id': hotelId,
        'floor_id': floorId,
        'room_number': roomNumber,
      }).select('id').single();
      roomId = asString(newRoom['id']);
    } else {
      roomId = asString(roomResult['id']);
    }

    // 4. Check inventory or housekeeper allocation
    if (deductFromHousekeeperId != null) {
      // Deduct atomically via SECURITY DEFINER RPC. A direct client-side
      // UPDATE on housekeeper_allocations is silently blocked by RLS
      // (only a SELECT policy exists), which left phantom stock in the cart.
      try {
        await _client.rpc('use_housekeeper_stock_for_room', params: {
          'p_housekeeper_id': deductFromHousekeeperId,
          'p_product_id': product.id,
          'p_full_bottles': 1,
        });
      } on PostgrestException catch (e) {
        if (e.message.contains('No housekeeper allocation') ||
            e.message.contains('Insufficient full bottles')) {
          throw StateError('Product not in housekeeper allocation');
        }
        rethrow;
      }
      
      await _auditService.logAction('Used housekeeper stock for room placement', details: {
        'housekeeper_id': deductFromHousekeeperId,
        'product_id': product.id,
        'room_id': roomId,
        'full_bottles_deducted': 1,
      });
    } else {
      final invResult = await _client.from('hotel_inventory').select('full_bottles').eq('hotel_id', hotelId).eq('product_id', product.id).maybeSingle();
      final currentStock = invResult != null ? asInt(invResult['full_bottles']) : 0;

      if (currentStock <= 0) {
        if (!autoAdjustInventory) {
          throw StateError('Product not in inventory');
        } else {
          // Automatically add 1 piece to inventory
          await _client.from('hotel_inventory').upsert({
            'hotel_id': hotelId,
            'product_id': product.id,
            'full_bottles': 1,
            'empty_bottles': 0,
          }, onConflict: 'hotel_id,product_id');

          // Log inventory event
          await _client.from('inventory_events').insert({
            'hotel_id': hotelId,
            'product_id': product.id,
            'full_bottles_delta': 1,
            'empty_bottles_delta': 0,
            'reason': 'Auto-added to inventory for single room placement',
            'performed_by': _client.auth.currentUser?.id,
          });
        }
      }

      // 5. Decrement central inventory by 1
      await _client.rpc('record_stock_adjustment', params: {
        'p_hotel_id': hotelId,
        'p_product_id': product.id,
        'p_full_bottles_delta': -1,
        'p_reason': 'Deducted for room placement',
      });
    }

    // 6. Insert room product
    final roomProductResult = await _client.from('room_products').insert({
      'hotel_id': hotelId,
      'room_id': roomId,
      'product_id': product.id,
      'status': 'active',
    }).select('id').single();

    final roomProductId = asString(roomProductResult['id']);

    // 7. Insert refill event (bottle_replaced)
    await _client.from('refill_events').insert({
      'hotel_id': hotelId,
      'room_product_id': roomProductId,
      'event_type': 'bottle_replaced',
      'previous_refill_count': 0,
      'new_refill_count': 0,
      'performed_by': _client.auth.currentUser?.id,
      'notes': 'Initial bottle placement',
    });

    await _clearRefillEventsCache();
    await _clearInventoryCache();
    await _clearRoomProductsCache();
  }

  @override
  Future<void> removeProductFromRoom({required String roomProductId}) async {
    // 1. Fetch room product record to get hotelId/roomNumber/nameEn for logging & audit
    final roomProd = await _client
        .from('room_product_summaries')
        .select('hotel_id, room_number, name_en, sku')
        .eq('id', roomProductId)
        .maybeSingle();

    String? hotelId;
    String? roomNumber;
    String? productName;
    String? sku;
    if (roomProd != null) {
      hotelId = roomProd['hotel_id'] != null ? asString(roomProd['hotel_id']) : null;
      roomNumber = roomProd['room_number'] != null ? asString(roomProd['room_number']) : null;
      productName = roomProd['name_en'] != null ? asString(roomProd['name_en']) : null;
      sku = roomProd['sku'] != null ? asString(roomProd['sku']) : null;
    }

    // 2. Perform DELETE query on `room_products` table
    await _client.from('room_products').delete().eq('id', roomProductId);

    // 3. Clear all relevant caches
    await _clearRefillEventsCache();
    await _clearRoomProductsCache();

    // 4. Log audit action
    await _auditService.logAction(
      'Removed product from room',
      details: {
        'roomProductId': roomProductId,
        if (hotelId != null) 'hotel_id': hotelId,
        if (roomNumber != null) 'room_number': roomNumber,
        if (productName != null) 'product_name': productName,
        if (sku != null) 'sku': sku,
      },
    );
  }

  Future<void> _clearHotelsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_hotels');
  }

  @override
  Future<void> updateHotelExpressQrEnabled({
    required String hotelId,
    required bool enabled,
  }) async {
    await _client
        .from('hotels')
        .update({'express_qr_enabled': enabled})
        .eq('id', hotelId);
    await _clearHotelsCache();
  }
}
