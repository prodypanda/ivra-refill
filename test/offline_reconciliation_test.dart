import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/data/offline/offline_sync_service.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the offline optimistic-merge reconciliation by clientRequestId.
///
/// Each queued [OfflineAction.id] is passed to the idempotent server RPCs as
/// the `client_request_id`. The providers fetch the applied set via
/// `appliedClientRequestIds` and must:
///   (a) still overlay an action that has NOT yet been applied, and
///   (b) NOT double-count an action already reflected in server data, while
///       pruning it from the queue.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer(MockIvraRepository repository) {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        selectedHotelIdProvider.overrideWith((ref) => 'hotel-seaside'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('pending refill not yet applied is overlaid exactly once', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final container = makeContainer(repository);

    final before = (await repository.roomProducts(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.canRefill);

    // Queue a refill that has NOT been applied on the server yet.
    await service.enqueue(
      type: SyncActionType.refill,
      payload: {'roomProductId': before.id},
    );

    final result = await container.read(roomProductsProvider.future);
    final overlaid = result.firstWhere((item) => item.id == before.id);

    // Overlaid exactly once.
    expect(overlaid.refillCount, before.refillCount + 1);
    // Genuinely-not-yet-synced action is kept in the queue.
    expect((await service.pendingActions()).length, 1);
  });

  test(
      'pending refill already applied on server is not double-counted and is '
      'pruned from the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final container = makeContainer(repository);

    final target = (await repository.roomProducts(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.canRefill);

    // Queue a refill action.
    await service.enqueue(
      type: SyncActionType.refill,
      payload: {'roomProductId': target.id},
    );
    final action = (await service.pendingActions()).single;

    // Simulate the server having already applied this exact action (same
    // client_request_id == action.id). The fetched room product now reflects
    // the +1, and the applied-id set contains the action id.
    await repository.recordRefill(
      roomProductId: target.id,
      clientRequestId: action.id,
    );
    final serverCount = (await repository.roomProducts(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.id == target.id)
        .refillCount;
    expect(serverCount, target.refillCount + 1);

    // The provider must reconcile and NOT overlay again.
    final result = await container.read(roomProductsProvider.future);
    final reconciled = result.firstWhere((item) => item.id == target.id);

    expect(reconciled.refillCount, serverCount); // not serverCount + 1
    // The confirmed-synced action is pruned from the queue.
    expect(await service.pendingActions(), isEmpty);
  });

  test('pending stock adjustment already applied is not double-counted and is '
      'pruned', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final container = makeContainer(repository);

    final stock = (await repository.inventory(hotelId: 'hotel-seaside')).first;

    await service.enqueue(
      type: SyncActionType.stockAdjustment,
      payload: {
        'hotelId': stock.hotelId,
        'productId': stock.product.id,
        'fullBottlesDelta': 5,
      },
    );
    final action = (await service.pendingActions()).single;

    // Server already applied this adjustment.
    await repository.recordStockAdjustment(
      hotelId: stock.hotelId,
      productId: stock.product.id,
      fullBottlesDelta: 5,
      clientRequestId: action.id,
    );
    final serverFull = (await repository.inventory(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.product.id == stock.product.id)
        .fullBottles;
    expect(serverFull, stock.fullBottles + 5);

    final result = await container.read(inventoryProvider.future);
    final reconciled =
        result.firstWhere((item) => item.product.id == stock.product.id);

    expect(reconciled.fullBottles, serverFull); // not serverFull + 5
    expect(await service.pendingActions(), isEmpty);
  });

  test('mock repository reports applied client request ids', () async {
    final repository = MockIvraRepository();
    final target = (await repository.roomProducts()).first;

    expect(await repository.appliedClientRequestIds(), isEmpty);

    await repository.recordRefill(
      roomProductId: target.id,
      clientRequestId: 'crid-123',
    );

    expect(await repository.appliedClientRequestIds(), contains('crid-123'));
  });
}
