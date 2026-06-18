import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_enums.dart';
import '../domain/models.dart';
import '../services/audit_service.dart';
import 'ivra_repository.dart';

/// Classifies errors thrown while talking to Supabase/the network so the
/// repository can decide when to fall back to cached data.
///
/// Detection is based on concrete exception types instead of matching against
/// `error.toString()`, which is fragile across locales and library versions.
class _NetworkErrorClassifier {
  const _NetworkErrorClassifier._();

  /// Returns true when [error] represents a connectivity failure (the device
  /// is offline or the host is unreachable), meaning a cache fallback is safe.
  static bool isOffline(Object error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;
    // `package:http` throws ClientException on transport-level failures.
    // On web, a failed fetch surfaces as a ClientException as well.
    if (error is ClientException) return true;
    // Supabase wraps transport failures; treat ones without an HTTP status
    // (i.e. the request never reached the server) as offline.
    if (error is PostgrestException && error.code == null) return true;
    return false;
  }

  /// Returns true when [error] is transient and the request is worth retrying
  /// once (expired JWT pending auto-refresh, or a connectivity blip).
  static bool isRetriable(Object error) {
    if (isOffline(error)) return true;
    // A momentarily expired/!refreshed session token.
    if (error is AuthException) return true;
    if (error is PostgrestException) {
      // PGRST301: JWT expired. Anything without a status is a transport error.
      return error.code == 'PGRST301' || error.code == null;
    }
    return false;
  }
}

class SupabaseIvraRepository implements IvraRepository {
  SupabaseIvraRepository(this._client) {
    _auditService = AuditService(_client);
  }

  final SupabaseClient _client;
  late final AuditService _auditService;

  Future<T> _fetchWithCache<T>(String key, Future<T> Function() fetcher) async {
    try {
      final data = await fetcher();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_$key', jsonEncode(data));
      return data;
    } catch (e) {
      if (_NetworkErrorClassifier.isOffline(e)) {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_$key');
        if (cached != null) {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            return List<Map<String, dynamic>>.from(
                decoded.map((x) => Map<String, dynamic>.from(x as Map))) as T;
          } else if (decoded is Map) {
            return Map<String, dynamic>.from(decoded) as T;
          }
          return decoded as T;
        } else {
          // If the cache is completely empty but we are offline,
          // gracefully return an empty list if this query expects a list!
          // This prevents terrifying red crash screens on un-cached pages.
          if (T.toString().startsWith('List<')) {
            return <Map<String, dynamic>>[] as T;
          }
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
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
    // A genuine "no profile row" (PGRST116) is not retriable.
    if (error is PostgrestException && error.code == 'PGRST116') {
      return false;
    }
    return _NetworkErrorClassifier.isRetriable(error);
  }

  @override
  Future<void> updateCurrentUserProfile({required String fullName}) async {
    await _client.rpc('update_current_profile', params: {
      'p_full_name': fullName,
    });
      _auditService.logAction('Updated current user profile', details: {'full_name': fullName});
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
  }) async {
    await _client.from('profiles').update({
      'full_name': fullName,
    }).eq('id', userId);
      _auditService.logAction('Updated user profile', details: {'user_id': userId, 'full_name': fullName});
  }

  @override
  Future<void> changeCurrentUserPassword({required String password}) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> switchDemoUser({required String userId}) {
    throw UnsupportedError('Demo user switching is not available.');
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
    );

    return DashboardMetrics(
      hotelCount: data['hotel_count'] as int,
      roomCount: data['room_count'] as int,
      pendingApprovals: data['pending_approvals'] as int,
      openAlerts: data['open_alerts'] as int,
      bottlesToReplace: data['bottles_to_replace'] as int,
      lowStockProducts: data['low_stock_products'] as int,
    );
  }

  @override
  Future<List<Hotel>> hotels() async {
    final rows = await _fetchWithCache(
      'hotels',
      () => _client.from('hotel_summaries').select().order('name'),
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
    );
    return rows.map<InventoryItem>(_inventoryFromMap).toList();
  }

  @override
  Future<List<SuggestedOrder>> suggestedOrders({String? hotelId}) async {
    var query = _client.from('suggested_order_quantities').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'suggested_orders_${hotelId ?? 'all'}',
      () => query.order('product_name'),
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
    );
    return rows.map<AlertItem>(_alertFromMap).toList();
  }

  @override
  Future<List<RefillEvent>> recentRefillEvents({String? hotelId}) async {
    var query = _client.from('refill_events').select();
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await _fetchWithCache(
      'recent_refill_events_${hotelId ?? 'all'}',
      () => query.order('occurred_at', ascending: false).limit(500),
    );
    return rows.map<RefillEvent>(_refillEventFromMap).toList();
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
        );
        for (final row in rows) {
          final value = row['client_request_id'];
          if (value is String && value.isNotEmpty) ids.add(value);
        }
      } catch (_) {
        // Reconciliation is best-effort. If we cannot reach the server (e.g.
        // genuinely offline), fall back to overlaying everything so the
        // offline-first UX is preserved.
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
    _auditService.logAction('Created hotel', details: {'name': name});
  }

  @override
  Future<void> deleteHotel(String hotelId) async {
    await _client.from('hotels').delete().eq('id', hotelId);
    _auditService.logAction('Deleted hotel', details: {'hotel_id': hotelId});
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('id', roomId);
    _auditService.logAction('Deleted room', details: {'room_id': roomId});
  }

  @override
  Future<void> deleteFloor(String floorId) async {
    await _client.from('floors').delete().eq('id', floorId);
    _auditService.logAction('Deleted floor', details: {'floor_id': floorId});
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _client.rpc('delete_user', params: {'target_user_id': userId});
    _auditService.logAction('Deleted user', details: {'user_id': userId});
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    await _client.from('alerts').delete().eq('id', alertId);
    _auditService.logAction('Deleted alert', details: {'alert_id': alertId});
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
    _auditService.logAction('Deleted product', details: {'product_id': productId});
  }

  @override
  Future<void> createRoomsFromTemplate({
    required String hotelId,
    required int floorNumber,
    required int firstRoomNumber,
    required int roomCount,
    required List<String> productIds,
  }) async {
    await _client.rpc('create_rooms_from_template', params: {
      'p_hotel_id': hotelId,
      'p_floor_number': floorNumber,
      'p_first_room_number': firstRoomNumber,
      'p_room_count': roomCount,
      'p_product_ids': productIds,
    });
    _auditService.logAction('Created rooms from template', details: {'hotel_id': hotelId, 'floor_number': floorNumber, 'room_count': roomCount});
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
    
    _auditService.logAction('Invited team member', details: {
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
    await _client.rpc('accept_team_invitation', params: {
      'p_token': token,
    });
    _auditService.logAction('Accepted team invitation', details: {});
  }

  @override
  Future<void> cancelTeamInvitation({required String invitationId}) async {
    await _client.rpc('cancel_team_invitation', params: {
      'p_invitation_id': invitationId,
    });
    _auditService.logAction('Canceled team invitation', details: {'invitation_id': invitationId});
  }

  @override
  Future<void> resendTeamInvitation({required String invitationId}) async {
    await _client.rpc('resend_team_invitation', params: {
      'p_invitation_id': invitationId,
    });
    _auditService.logAction('Resent team invitation', details: {'invitation_id': invitationId});
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
    
    _auditService.logAction('Set team member active status', details: {
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
    });
    _auditService.logAction('Created product', details: {'sku': sku});
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
    }).eq('id', productId);
    _auditService.logAction('Updated product', details: {'product_id': productId});
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
    _auditService.logAction('Recorded refill', details: {'room_product_id': roomProductId});
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
    _auditService.logAction('Undid refill', details: {'refill_event_id': refillEventId});
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
    _auditService.logAction('Requested stock correction', details: {'refill_event_id': refillEventId});
  }

  @override
  Future<void> replaceBottle({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
  }) async {
    await _client.rpc('replace_bottle', params: {
      'p_room_product_id': roomProductId,
      'p_notes': notes,
      'p_client_request_id': clientRequestId,
    });
    _auditService.logAction('Replaced bottle', details: {'room_product_id': roomProductId});
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
    _auditService.logAction('Submitted change request', details: {
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
    _auditService.logAction('Recorded stock adjustment', details: {'hotel_id': hotelId, 'product_id': productId});
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
    
    _auditService.logAction('Approved change request', details: {
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
    _auditService.logAction('Rejected change request', details: {'request_id': approvalRequestId});
  }

  @override
  Future<int> refreshSmartAlerts({String? hotelId}) async {
    final result = await _client.rpc('refresh_smart_alerts', params: {
      'p_hotel_id': hotelId,
    });
    if (result is int) return result;
    if (result is num) return result.toInt();
    return int.tryParse('$result') ?? 0;
  }

  @override
  Future<void> resolveAlert({required String alertId}) async {
    await _client.rpc('resolve_alert', params: {
      'p_alert_id': alertId,
    });
    
    _auditService.logAction('Resolved alert', details: {
      'alert_id': alertId,
    });
  }

  @override
  Future<List<Hotel>> userHotels({required String userId}) async {
    final rows = await _client.rpc('get_user_hotels', params: {
      'p_user_id': userId,
    });
    if (rows is! List) return [];
    return rows.map<Hotel>((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return Hotel(
        id: map['hotel_id'] as String,
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
    _auditService.logAction('Assigned user to hotel', details: {'user_id': userId, 'hotel_id': hotelId});
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
    _auditService.logAction('Unassigned user from hotel', details: {'user_id': userId, 'hotel_id': hotelId});
  }

  RoomProduct _roomProductFromMap(Map<String, dynamic> map) {
    return RoomProduct(
      id: map['id'] as String,
      hotelId: map['hotel_id'] as String,
      roomId: map['room_id'] as String,
      roomNumber: (map['room_number'] ?? '') as String,
      floorNumber: (map['floor_number'] ?? 0) as int,
      product: _joinedProductFromMap(map),
      refillCount: (map['refill_count'] ?? 0) as int,
      lastRefillAt: map['last_refill_at'] == null
          ? null
          : DateTime.parse(map['last_refill_at'] as String),
      bottleStartedAt: DateTime.parse(map['bottle_started_at'] as String),
      status: BottleStatus.values.firstWhere(
        (item) => item.value == map['status'],
        orElse: () => BottleStatus.active,
      ),
    );
  }

  InventoryItem _inventoryFromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      hotelId: map['hotel_id'] as String,
      product: _joinedProductFromMap(map),
      fullBottles: (map['full_bottles'] ?? 0) as int,
      emptyBottles: (map['empty_bottles'] ?? 0) as int,
      fullBidons: (map['full_bidons'] ?? 0) as int,
      openBidons: (map['open_bidons'] ?? 0) as int,
      emptyBidons: (map['empty_bidons'] ?? 0) as int,
    );
  }

  SuggestedOrder _suggestedOrderFromMap(Map<String, dynamic> map) {
    return SuggestedOrder(
      hotelId: map['hotel_id'] as String,
      product: _joinedProductFromMap(map),
      bottlesToOrder: (map['bottles_to_order'] ?? 0) as int,
      bidonsToOrder: (map['bidons_to_order'] ?? 0) as int,
      bottlesToRecycle: (map['bottles_to_recycle'] ?? 0) as int,
    );
  }

  ApprovalRequest _approvalFromMap(Map<String, dynamic> map) {
    return ApprovalRequest(
      id: map['id'] as String,
      hotelId: map['hotel_id'] as String,
      title: (map['title'] ?? '') as String,
      targetId: map['target_id'] as String?,
      targetTable: (map['target_table'] ?? '') as String,
      status: ApprovalStatus.values.firstWhere(
        (item) => item.value == map['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      requestedByName: (map['requested_by_name'] ?? '') as String,
      requestedAt: DateTime.parse(map['requested_at'] as String),
      oldValue: (map['old_value'] ?? '') as String,
      newValue: (map['new_value'] ?? '') as String,
      oldData: Map<String, dynamic>.from((map['old_data'] ?? const {}) as Map),
      newData: Map<String, dynamic>.from((map['new_data'] ?? const {}) as Map),
    );
  }

  AlertItem _alertFromMap(Map<String, dynamic> map) {
    return AlertItem(
      id: map['id'] as String,
      hotelId: map['hotel_id'] as String,
      roomProductId: map['room_product_id'] as String?,
      productId: map['product_id'] as String?,
      type: AlertType.values.firstWhere(
        (item) => item.value == map['alert_type'],
        orElse: () => AlertType.pendingApproval,
      ),
      severity: (map['severity'] ?? 1) as int,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isResolved: (map['is_resolved'] ?? false) as bool,
    );
  }

  RefillEvent _refillEventFromMap(Map<String, dynamic> map) {
    return RefillEvent(
      id: map['id'] as String,
      roomProductId: map['room_product_id'] as String,
      type: RefillEventType.values.firstWhere(
        (item) => item.value == map['event_type'],
        orElse: () => RefillEventType.refill,
      ),
      previousRefillCount: (map['previous_refill_count'] ?? 0) as int,
      newRefillCount: (map['new_refill_count'] ?? 0) as int,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      performedBy: map['performed_by'] as String,
      notes: map['notes'] as String?,
      clientRequestId: map['client_request_id'] as String?,
    );
  }

  Product _joinedProductFromMap(Map<String, dynamic> map) {
    return Product(
      id: map['product_id'] as String,
      sku: (map['sku'] ?? '') as String,
      nameEn: (map['name_en'] ?? '') as String,
      nameFr: (map['name_fr'] ?? '') as String,
      nameAr: (map['name_ar'] ?? '') as String,
      nameIt: (map['name_it'] ?? map['name_en'] ?? '') as String,
      bottleVolumeMl: (map['bottle_volume_ml'] ?? 1000) as int,
      bidonVolumeMl: (map['bidon_volume_ml'] ?? 5000) as int,
      maxRefillCount: (map['max_refill_count'] ?? 0) as int,
      maxBottleAgeDays: (map['max_bottle_age_days'] ?? 0) as int,
      lowBottleThreshold: (map['low_bottle_threshold'] ?? 0) as int,
      lowBidonThreshold: (map['low_bidon_threshold'] ?? 0) as int,
      imageUrl: map['image_url'] as String?,
    );
  }
}
