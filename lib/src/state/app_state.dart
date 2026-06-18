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

final localeProvider = StateProvider<Locale>((ref) => resolveInitialLocale());

/// Resolves the initial app [Locale] from the device/OS locales, falling back
/// to French only when none of the device locales is supported. Previously the
/// app always started in French regardless of the user's device language.
Locale resolveInitialLocale() {
  const supported = ['en', 'fr', 'ar', 'it'];
  const fallback = Locale('fr');
  for (final deviceLocale in PlatformDispatcher.instance.locales) {
    if (supported.contains(deviceLocale.languageCode)) {
      return Locale(deviceLocale.languageCode);
    }
  }
  return fallback;
}

final offlineModeProvider = StateProvider<bool>((ref) => false);

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

final selectedHotelIdProvider = StateProvider<String?>((ref) => null);

final currentUserProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(repositoryProvider).currentUser();
});

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

final teamMembersProvider = FutureProvider<List<UserProfile>>((ref) async {
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

final teamInvitationsProvider = FutureProvider<List<TeamInvitation>>((ref) {
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
  ref.invalidate(offlineActionsProvider);
}

final refillEventsProvider = FutureProvider<List<RefillEvent>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).recentRefillEvents(hotelId: hotelId);
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

