import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/export_file_service.dart';
import '../data/ivra_repository.dart';
import '../data/mock_ivra_repository.dart';
import '../data/offline/offline_sync_service.dart';
import '../data/report_export_service.dart';
import '../data/supabase_ivra_repository.dart';
import '../domain/app_enums.dart';
import '../domain/models.dart';

final useSupabaseProvider = Provider<bool>((ref) => false);

final supabaseAuthStateProvider = StreamProvider<AuthState?>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (!useSupabase) return const Stream<AuthState?>.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final localeProvider = StateProvider<Locale>((ref) {
  ref.listenSelf((previous, next) async {
    if (previous != null && previous != next) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_language', next.languageCode);
      } catch (e) {
        debugPrint('Error saving language selection: $e');
      }
    }
  });

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      return Locale(savedLang);
    }
  }
  return resolveInitialLocale();
});

/// Resolves the initial app [Locale] from the device/OS locales, falling back
/// to French only when none of the device locales is supported. Previously the
/// app always started in French regardless of the user's device language.
Locale resolveInitialLocale() {
  return const Locale('fr');
}

final offlineModeProvider = StateProvider<bool>((ref) => false);

final precisionScanWindowEnabledProvider = StateProvider<bool>((ref) {
  ref.listenSelf((previous, next) async {
    if (previous != null && previous != next) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('precision_scan_window', next);
      } catch (e) {
        debugPrint('Error saving precision scan window: $e');
      }
    }
  });

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return prefs.getBool('precision_scan_window') ?? true;
  }
  return true;
});

final tapToScanEnabledProvider = StateProvider<bool>((ref) {
  ref.listenSelf((previous, next) async {
    if (previous != null && previous != next) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tap_to_scan', next);
      } catch (e) {
        debugPrint('Error saving tap to scan selection: $e');
      }
    }
  });

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return prefs.getBool('tap_to_scan') ?? true;
  }
  return true;
});

final percentageRefillEnabledProvider = StateProvider<bool>((ref) {
  ref.listenSelf((previous, next) async {
    if (previous != null && previous != next) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('percentage_refill_enabled', next);
      } catch (e) {
        debugPrint('Error saving percentage refill enabled selection: $e');
      }
    }
  });

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return prefs.getBool('percentage_refill_enabled') ?? true;
  }
  return true;
});

/// Set to true after the invited user successfully sets their password.
/// This prevents the router from redirecting back to SetPasswordScreen
/// during the brief window where userMetadata hasn't propagated yet.
final passwordSetProvider = StateProvider<bool>((ref) => false);

/// Set to true when the user clicks a password recovery link.
/// This forces the router to show the SetPasswordScreen.
final isPasswordRecoveryProvider = StateProvider<bool>((ref) => false);

final repositoryProvider = Provider<IvraRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase) {
    return SupabaseIvraRepository(Supabase.instance.client);
  }
  return MockIvraRepository();
});

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService();
});

final exportFileServiceProvider = Provider<ExportFileService>((ref) {
  return ExportFileService();
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService();
});

final offlineActionsProvider = FutureProvider<List<OfflineAction>>((ref) {
  return ref.watch(offlineSyncServiceProvider).pendingActions();
});

final selectedHotelIdProvider = StateProvider<String?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.hotelId;
});

/// When an app admin chooses "View as" another user, the target's profile is
/// stored here. While set, [currentUserProvider] returns this profile instead
/// of the real authenticated user, so navigation, route gating and every
/// role/hotel-scoped permission check reflect the impersonated user.
///
/// This is a client-side view only: it does NOT change the authenticated
/// session, so any write still executes as the real admin on the backend.
final impersonatedUserProvider = StateProvider<UserProfile?>((ref) => null);

/// The real authenticated user, ignoring any active "View as" impersonation.
/// Use this (not [currentUserProvider]) when you need to know who is actually
/// signed in, e.g. to decide whether the "View as" feature is available.
final realCurrentUserProvider = FutureProvider<UserProfile>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase) {
    ref.watch(supabaseAuthStateProvider);
  }
  return ref.watch(repositoryProvider).currentUser();
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final impersonated = ref.watch(impersonatedUserProvider);
  if (impersonated != null) return impersonated;
  return ref.watch(realCurrentUserProvider.future);
});

final isLoggedInProvider = Provider<bool>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase) {
    ref.watch(supabaseAuthStateProvider);
    return Supabase.instance.client.auth.currentSession != null;
  }
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => true,
    error: (_, __) => false,
    loading: () => true,
  );
});

/// True while an app admin is viewing the app as another user.
final isImpersonatingProvider = Provider<bool>((ref) {
  return ref.watch(impersonatedUserProvider) != null;
});

/// Starts a "View as" session for [target]. Only an app admin may impersonate,
/// and an admin can never impersonate themselves. Switching the effective user
/// invalidates all account-scoped data so the impersonated user's hotels,
/// dashboard, etc. are fetched immediately.
void startImpersonation(WidgetRef ref, UserProfile target) {
  final realUser = ref.read(realCurrentUserProvider).valueOrNull;
  if (realUser == null || realUser.role != UserRole.appAdmin) return;
  if (realUser.id == target.id) return;
  ref.read(impersonatedUserProvider.notifier).state = target;
  ref.read(selectedHotelIdProvider.notifier).state = target.hotelId;
  invalidateAccountScopedData(ref);
}

/// Ends the active "View as" session and restores the admin's own view.
void stopImpersonation(WidgetRef ref) {
  if (ref.read(impersonatedUserProvider) == null) return;
  ref.read(impersonatedUserProvider.notifier).state = null;
  ref.read(selectedHotelIdProvider.notifier).state = null;
  invalidateAccountScopedData(ref);
}

final dashboardProvider = FutureProvider<DashboardMetrics>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).dashboardMetrics(hotelId: hotelId);
});

final hotelsProvider = FutureProvider<List<Hotel>>((ref) {
  return ref.watch(repositoryProvider).hotels();
});

final activeHotelNameProvider = Provider<String?>((ref) {
  final hotels = ref.watch(hotelsProvider).valueOrNull ?? [];
  final selectedHotelId = ref.watch(selectedHotelIdProvider);
  if (selectedHotelId == null || hotels.isEmpty) return null;
  final matches = hotels.where((h) => h.id == selectedHotelId);
  if (matches.isEmpty) return null;
  return matches.first.name;
});

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(repositoryProvider).products();
});

final auditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) {
  return ref.watch(repositoryProvider).fetchAuditLogs();
});

final teamMembersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final members = await ref.watch(repositoryProvider).teamMembers(hotelId: hotelId);
  final invitations = await ref.watch(repositoryProvider).teamInvitations(hotelId: hotelId);
  
  // Filter out members who are still in the "Pending Invitations" list
  return members.where((m) {
    return !invitations.any((i) => i.email.toLowerCase() == m.email.toLowerCase());
  }).toList();
});

final demoUsersProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(repositoryProvider).teamMembers();
});

final teamInvitationsProvider = FutureProvider.autoDispose<List<TeamInvitation>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).teamInvitations(hotelId: hotelId);
});

final roomsProvider = FutureProvider<List<RoomInfo>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).rooms(hotelId: hotelId);
});

/// Reconciles the locally-queued [OfflineAction]s against the idempotency keys
/// the server has already applied.
///
/// Each action's [OfflineAction.id] is passed to the server as the
/// `client_request_id`, so an action whose id appears in [appliedIds] has
/// already landed on the server and is reflected in the freshly fetched rows.
/// Such actions are:
///   * removed from the returned list so the optimistic overlay does NOT
///     double-count them, and
///   * pruned from the offline queue so the UI and queue stay consistent
///     without waiting for a manual refresh.
///
/// Actions that are genuinely not-yet-synced are returned unchanged so the
/// offline-first overlay keeps working.
Future<List<OfflineAction>> _reconcilePendingActions(
  Ref ref,
  List<OfflineAction> pendingActions,
  Set<String> appliedIds,
) async {
  if (pendingActions.isEmpty || appliedIds.isEmpty) return pendingActions;

  final service = ref.watch(offlineSyncServiceProvider);
  final stillPending = <OfflineAction>[];
  for (final action in pendingActions) {
    if (appliedIds.contains(action.id)) {
      // Confirmed synced on the server already; drop it from the queue.
      await service.remove(action.id);
    } else {
      stillPending.add(action);
    }
  }
  return stillPending;
}

final roomProductsProvider = FutureProvider<List<RoomProduct>>((ref) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final repository = ref.watch(repositoryProvider);
  final items = await repository.roomProducts(hotelId: hotelId);
  var pendingActions =
      await ref.watch(offlineSyncServiceProvider).pendingActions();

  if (pendingActions.isEmpty) return items;

  final appliedIds = await repository.appliedClientRequestIds(hotelId: hotelId);
  pendingActions =
      await _reconcilePendingActions(ref, pendingActions, appliedIds);

  if (pendingActions.isEmpty) return items;

  return items.map((item) {
    var updated = item;
    for (final action in pendingActions) {
      if (action.type == SyncActionType.refill &&
          action.payload['roomProductId'] == updated.id) {
        final newCount = updated.refillCount + 1;
        updated = updated.copyWith(
          refillCount: newCount,
          lastRefillAt: DateTime.now(),
          status: newCount >= updated.product.maxRefillCount
              ? BottleStatus.refillLimitReached
              : updated.status,
        );
      } else if (action.type == SyncActionType.bottleReplacement &&
          action.payload['roomProductId'] == updated.id) {
        updated = updated.copyWith(
          refillCount: 0,
          status: BottleStatus.active,
          lastRefillAt: DateTime.now(),
        );
      }
    }
    return updated;
  }).toList();
});

/// Unscoped room products – returns ALL products regardless of the user's
/// hotel assignment. Used by [QrActionScreen] so it can resolve any scanned
/// QR code and then apply its own authorization gate.
final allRoomProductsProvider = FutureProvider<List<RoomProduct>>((ref) async {
  return ref.watch(repositoryProvider).roomProducts();
});

final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final repository = ref.watch(repositoryProvider);
  final items = await repository.inventory(hotelId: hotelId);
  var pendingActions =
      await ref.watch(offlineSyncServiceProvider).pendingActions();

  if (pendingActions.isEmpty) return items;

  final appliedIds = await repository.appliedClientRequestIds(hotelId: hotelId);
  pendingActions =
      await _reconcilePendingActions(ref, pendingActions, appliedIds);

  if (pendingActions.isEmpty) return items;

  // Fetch room products to map roomProductId to product/productId
  final roomProducts = await repository.roomProducts(hotelId: hotelId);
  final Map<String, Product> roomProductMap = {
    for (final rp in roomProducts) rp.id: rp.product
  };

  // Local tracker for active volume left of the open bidon per product
  final Map<String, double> localVolumeLeft = {};
  for (final item in items) {
    localVolumeLeft[item.product.id] = item.openBidonVolumeLeftMl;
  }

  return items.map((item) {
    var updated = item;
    for (final action in pendingActions) {
      if (action.type == SyncActionType.stockAdjustment &&
          action.payload['productId'] == updated.product.id) {
        updated = updated.copyWith(
          fullBottles: updated.fullBottles +
              (action.payload['fullBottlesDelta'] as int? ?? 0),
          emptyBottles: updated.emptyBottles +
              (action.payload['emptyBottlesDelta'] as int? ?? 0),
          fullBidons: updated.fullBidons +
              (action.payload['fullBidonsDelta'] as int? ?? 0),
          openBidons: updated.openBidons +
              (action.payload['openBidonsDelta'] as int? ?? 0),
          emptyBidons: updated.emptyBidons +
              (action.payload['emptyBidonsDelta'] as int? ?? 0),
        );
      } else if (action.type == SyncActionType.refill) {
        final roomProductId = action.payload['roomProductId'] as String?;
        final product = roomProductMap[roomProductId];
        if (product != null && product.id == updated.product.id && product.isRefillable) {
          final notes = action.payload['notes'] as String?;
          int percentageVal = 100;
          if (notes != null) {
            final percentageMatch = RegExp(r'\[Refill:\s*(\d+)%\]').firstMatch(notes);
            if (percentageMatch != null) {
              percentageVal = int.parse(percentageMatch.group(1)!);
            }
          }
          final double bottleVol = product.bottleVolumeMl > 0 ? product.bottleVolumeMl.toDouble() : 1000.0;
          final double bidonVolume = product.bidonVolumeMl > 0 ? product.bidonVolumeMl.toDouble() : 5000.0;
          final double volumeAdded = (percentageVal / 100.0) * bottleVol;

          int fullBidons = updated.fullBidons;
          int openBidons = updated.openBidons;
          int emptyBidons = updated.emptyBidons;
          double currentVolumeLeft = localVolumeLeft[updated.product.id] ?? updated.openBidonVolumeLeftMl;

          if (openBidons > 0 && currentVolumeLeft == 0.0) {
            currentVolumeLeft = bidonVolume;
          }

          currentVolumeLeft -= volumeAdded;

          while (currentVolumeLeft <= 0) {
            if (fullBidons > 0) {
              if (openBidons > 0) {
                emptyBidons++;
              }
              fullBidons--;
              openBidons = 1;
              currentVolumeLeft += bidonVolume;
            } else {
              if (openBidons > 0) {
                emptyBidons++;
              }
              currentVolumeLeft = 0.0;
              openBidons = 0;
              break;
            }
          }

          localVolumeLeft[updated.product.id] = currentVolumeLeft;
          updated = updated.copyWith(
            fullBidons: fullBidons,
            openBidons: openBidons,
            emptyBidons: emptyBidons,
            openBidonVolumeLeftMl: currentVolumeLeft,
          );
        }
      }
    }
    return updated;
  }).toList();
});

final suggestedOrdersProvider = FutureProvider<List<SuggestedOrder>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).suggestedOrders(hotelId: hotelId);
});

final approvalsProvider = FutureProvider<List<ApprovalRequest>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).approvalRequests(hotelId: hotelId);
});

final alertsProvider = FutureProvider<List<AlertItem>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).alerts(hotelId: hotelId);
});

/// Invalidates every provider that holds account-scoped data. The data
/// providers above are plain (non-autoDispose) [FutureProvider]s, so they keep
/// the previously signed-in user's results cached for the whole app session.
/// Without this, switching accounts showed the prior user's data until a manual
/// pull-to-refresh. Call this whenever the authenticated user changes so the
/// new account's data is fetched immediately.
void invalidateAccountScopedData(WidgetRef ref) {
  ref.invalidate(currentUserProvider);
  ref.invalidate(selectedHotelIdProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(productsProvider);
  ref.invalidate(teamMembersProvider);
  ref.invalidate(demoUsersProvider);
  ref.invalidate(teamInvitationsProvider);
  ref.invalidate(roomsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(suggestedOrdersProvider);
  ref.invalidate(approvalsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(inventoryEventsProvider);
  ref.invalidate(offlineActionsProvider);
  ref.invalidate(rolesProvider);
  ref.invalidate(rolePermissionsProvider);
}

final refillEventsProvider = FutureProvider<List<RefillEvent>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).recentRefillEvents(hotelId: hotelId);
});

final inventoryEventsProvider = FutureProvider<List<InventoryEvent>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).recentInventoryEvents(hotelId: hotelId);
});


class DownloadBannerNotifier extends StateNotifier<bool> {
  DownloadBannerNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool('download_banner_collapsed') ?? false;
    } catch (e) {
      debugPrint('Error loading download banner state: $e');
    }
  }

  Future<void> setCollapsed(bool collapsed) async {
    state = collapsed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('download_banner_collapsed', collapsed);
    } catch (e) {
      debugPrint('Error saving download banner state: $e');
    }
  }
}

final downloadBannerCollapsedProvider = StateNotifierProvider<DownloadBannerNotifier, bool>((ref) {
  return DownloadBannerNotifier();
});

final dailyRefillProgressProvider = Provider<DailyRefillProgress?>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  if (hotelId == null) return null;

  final roomProductsAsync = ref.watch(roomProductsProvider);
  final refillEventsAsync = ref.watch(refillEventsProvider);

  if (roomProductsAsync.isLoading || refillEventsAsync.isLoading) {
    return null;
  }
  if (roomProductsAsync.hasError || refillEventsAsync.hasError) {
    return null;
  }

  final products = roomProductsAsync.value ?? [];
  final events = refillEventsAsync.value ?? [];

  if (products.isEmpty) {
    return const DailyRefillProgress(
      refilledRoomsCount: 0,
      totalRoomsCount: 0,
      status: DailyRefillStatus.noRooms,
      nextPriorityRoomNumber: null,
    );
  }

  // Group products by room number
  final roomMap = <String, List<RoomProduct>>{};
  for (final p in products) {
    roomMap.putIfAbsent(p.roomNumber, () => []).add(p);
  }
  final totalRoomsCount = roomMap.length;

  final now = DateTime.now();
  final refilledRoomNumbers = <String>{};

  // Filter events to today's refill events
  final todayRefillEvents = events.where((e) {
    if (e.type != RefillEventType.refill) return false;
    final occurredLocal = e.occurredAt.toLocal();
    return occurredLocal.year == now.year &&
        occurredLocal.month == now.month &&
        occurredLocal.day == now.day;
  }).toList();

  final refilledProductIds = todayRefillEvents.map((e) => e.roomProductId).toSet();

  for (final entry in roomMap.entries) {
    final roomNumber = entry.key;
    final roomProducts = entry.value;
    final anyProductRefilledToday =
        roomProducts.any((p) => refilledProductIds.contains(p.id));
    if (anyProductRefilledToday) {
      refilledRoomNumbers.add(roomNumber);
    }
  }

  final refilledRoomsCount = refilledRoomNumbers.length;
  final remainingRooms = roomMap.entries
      .where((entry) => !refilledRoomNumbers.contains(entry.key))
      .toList();

  String? nextPriorityRoomNumber;
  if (remainingRooms.isNotEmpty) {
    final criticalRooms = <MapEntry<String, List<RoomProduct>>>[];
    final warningRooms = <MapEntry<String, List<RoomProduct>>>[];
    final normalRooms = <MapEntry<String, List<RoomProduct>>>[];

    for (final entry in remainingRooms) {
      final roomProducts = entry.value;
      final hasCritical = roomProducts.any((item) =>
          item.status == BottleStatus.refillLimitReached ||
          item.status == BottleStatus.tooOld ||
          item.status == BottleStatus.needsReplacement ||
          item.status == BottleStatus.damaged ||
          item.status == BottleStatus.lost);

      final hasWarning =
          roomProducts.any((item) => item.status == BottleStatus.needsRefill);

      if (hasCritical) {
        criticalRooms.add(entry);
      } else if (hasWarning) {
        warningRooms.add(entry);
      } else {
        normalRooms.add(entry);
      }
    }

    int compareRoomNumbers(
      MapEntry<String, List<RoomProduct>> a,
      MapEntry<String, List<RoomProduct>> b,
    ) {
      final aFloor = a.value.first.floorNumber;
      final bFloor = b.value.first.floorNumber;
      if (aFloor != bFloor) {
        return aFloor.compareTo(bFloor);
      }
      final aNum = int.tryParse(a.key) ?? 0;
      final bNum = int.tryParse(b.key) ?? 0;
      if (aNum != 0 && bNum != 0) {
        return aNum.compareTo(bNum);
      }
      return a.key.compareTo(b.key);
    }

    criticalRooms.sort(compareRoomNumbers);
    warningRooms.sort(compareRoomNumbers);
    normalRooms.sort(compareRoomNumbers);

    if (criticalRooms.isNotEmpty) {
      nextPriorityRoomNumber = criticalRooms.first.key;
    } else if (warningRooms.isNotEmpty) {
      nextPriorityRoomNumber = warningRooms.first.key;
    } else if (normalRooms.isNotEmpty) {
      nextPriorityRoomNumber = normalRooms.first.key;
    }
  }

  return DailyRefillProgress(
    refilledRoomsCount: refilledRoomsCount,
    totalRoomsCount: totalRoomsCount,
    status: nextPriorityRoomNumber == null
        ? DailyRefillStatus.allDone
        : DailyRefillStatus.hasPriority,
    nextPriorityRoomNumber: nextPriorityRoomNumber,
  );
});

final rolesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(repositoryProvider).fetchRoles();
});

final rolePermissionsProvider = FutureProvider<Map<String, Set<String>>>((ref) async {
  return ref.watch(repositoryProvider).fetchRolePermissions();
});

final allPermissionsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(repositoryProvider).fetchAllPermissions();
});

final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final userProfile = ref.watch(currentUserProvider).valueOrNull;
  if (userProfile == null) return false;

  final permissionsAsync = ref.watch(rolePermissionsProvider);
  final matrix = permissionsAsync.valueOrNull;

  if (matrix == null) {
    switch (userProfile.role) {
      case UserRole.appAdmin:
        return true;
      case UserRole.appManager:
        return permission != 'view_audit_logs';
      case UserRole.hotelManager:
        return permission != 'manage_products' &&
            permission != 'approve_corrections' &&
            permission != 'send_notifications' &&
            permission != 'view_audit_logs' &&
            permission != 'view_authorizations';
      case UserRole.hotelStaff:
      case UserRole.housekeeper:
        return permission == 'view_alerts' ||
            permission == 'view_rooms' ||
            permission == 'view_inventory';
    }
  }

  final rolePermissions = matrix[userProfile.roleString];
  return rolePermissions?.contains(permission) ?? false;
});

final housekeeperAllocationsProvider = FutureProvider<List<HousekeeperAllocation>>((ref) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final repository = ref.watch(repositoryProvider);
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return const [];
  return repository.fetchHousekeeperAllocations(
    housekeeperId: currentUser.id,
    hotelId: hotelId,
  );
});

/// Movement history of the current housekeeper's cart for one product
/// (checkouts, returns, room placements, refill/replace usages).
typedef HousekeeperProductParams = ({String housekeeperId, String productId});

final housekeeperStockEventsProvider =
    FutureProvider.family<List<HousekeeperStockEvent>, HousekeeperProductParams>((ref, params) async {
  final repository = ref.watch(repositoryProvider);
  return repository.fetchHousekeeperStockEvents(
    housekeeperId: params.housekeeperId,
    productId: params.productId,
  );
});

/// Full movement history of the current housekeeper's cart across ALL
/// products (used by the "All history" button on the My Basket page).
final housekeeperAllStockEventsProvider =
    FutureProvider.family<List<HousekeeperStockEvent>, String>((ref, housekeeperId) async {
  final repository = ref.watch(repositoryProvider);
  return repository.fetchHousekeeperStockEvents(
    housekeeperId: housekeeperId,
    limit: 200,
  );
});

final hotelHousekeepersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final repository = ref.watch(repositoryProvider);
  final members = await repository.teamMembers(hotelId: hotelId);
  return members
      .where((m) => m.role == UserRole.housekeeper)
      .toList();
});

/// Basket (allocations) of a specific housekeeper, viewed by managers.
final housekeeperBasketProvider = FutureProvider.family<List<HousekeeperAllocation>, String>(
    (ref, housekeeperId) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final repository = ref.watch(repositoryProvider);
  return repository.fetchHousekeeperAllocations(
    housekeeperId: housekeeperId,
    hotelId: hotelId,
  );
});

/// Full stock movement history of a specific housekeeper, viewed by managers.
final housekeeperHistoryProvider = FutureProvider.family<List<HousekeeperStockEvent>, String>(
    (ref, housekeeperId) async {
  final repository = ref.watch(repositoryProvider);
  return repository.fetchHousekeeperStockEvents(
    housekeeperId: housekeeperId,
    limit: 200,
  );
});

