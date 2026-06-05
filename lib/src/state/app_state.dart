import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final localeProvider = StateProvider<Locale>((ref) => const Locale('fr'));

final offlineModeProvider = StateProvider<bool>((ref) => false);

/// Set to true after the invited user successfully sets their password.
/// This prevents the router from redirecting back to SetPasswordScreen
/// during the brief window where userMetadata hasn't propagated yet.
final passwordSetProvider = StateProvider<bool>((ref) => false);

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

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(repositoryProvider).products();
});

final teamMembersProvider = FutureProvider<List<UserProfile>>((ref) {
  final hotelId = ref.watch(selectedHotelIdProvider);
  return ref.watch(repositoryProvider).teamMembers(hotelId: hotelId);
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

final roomProductsProvider = FutureProvider<List<RoomProduct>>((ref) async {
  final hotelId = ref.watch(selectedHotelIdProvider);
  final items =
      await ref.watch(repositoryProvider).roomProducts(hotelId: hotelId);
  final pendingActions =
      await ref.watch(offlineSyncServiceProvider).pendingActions();

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
  final items = await ref.watch(repositoryProvider).inventory(hotelId: hotelId);
  final pendingActions =
      await ref.watch(offlineSyncServiceProvider).pendingActions();

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
