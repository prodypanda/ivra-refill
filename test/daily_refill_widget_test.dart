import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/state/app_state.dart';

void main() {
  group('dailyRefillProgressProvider Tests', () {
    test('returns null if hotelId is not selected', () {
      final container = ProviderContainer(
        overrides: [
          selectedHotelIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final progress = container.read(dailyRefillProgressProvider);
      expect(progress, isNull);
    });

    test('correctly calculates refill progress and next priority room', () {
      final hotelId = 'hotel-1';
      final now = DateTime.now();

      // Define some products
      const p1 = Product(
        id: 'prod-1',
        sku: 'SKU1',
        nameFr: 'Produit 1',
        nameEn: 'Product 1',
        nameAr: 'المنتج 1',
        nameIt: 'Prodotto 1',
        maxRefillCount: 5,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 2,
        lowBidonThreshold: 1,
        bottleVolumeMl: 1000,
        bidonVolumeMl: 5000,
      );

      // Define room products:
      // Room 101: Floor 1. Has 1 active product. No refill event today.
      final rp101 = RoomProduct(
        id: 'rp-1',
        hotelId: hotelId,
        roomId: 'room-101',
        roomNumber: '101',
        floorNumber: 1,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.active,
        lastRefillAt: null,
      );

      // Room 102: Floor 1. Has 1 warning product. No refill event today.
      final rp102 = RoomProduct(
        id: 'rp-2',
        hotelId: hotelId,
        roomId: 'room-102',
        roomNumber: '102',
        floorNumber: 1,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.needsRefill,
        lastRefillAt: null,
      );

      // Room 103: Floor 1. Has 1 active product. Refilled today!
      final rp103 = RoomProduct(
        id: 'rp-3',
        hotelId: hotelId,
        roomId: 'room-103',
        roomNumber: '103',
        floorNumber: 1,
        product: p1,
        refillCount: 1,
        bottleStartedAt: now,
        status: BottleStatus.refilled,
        lastRefillAt: now,
      );

      // Room 201: Floor 2. Has 1 critical product. No refill event today.
      final rp201 = RoomProduct(
        id: 'rp-4',
        hotelId: hotelId,
        roomId: 'room-201',
        roomNumber: '201',
        floorNumber: 2,
        product: p1,
        refillCount: 5,
        bottleStartedAt: now,
        status: BottleStatus.refillLimitReached,
        lastRefillAt: null,
      );

      // Define refill events:
      // Event 1: Refill event for rp103 occurred today.
      final ev1 = RefillEvent(
        id: 'ev-1',
        roomProductId: 'rp-3',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now,
        performedBy: 'user-1',
      );

      // Event 2: Refill event for rp101 occurred yesterday.
      final ev2 = RefillEvent(
        id: 'ev-2',
        roomProductId: 'rp-1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now.subtract(const Duration(days: 1)),
        performedBy: 'user-1',
      );

      final container = ProviderContainer(
        overrides: [
          selectedHotelIdProvider.overrideWith((ref) => hotelId),
          roomProductsProvider.overrideWith((ref) => [rp101, rp102, rp103, rp201]),
          refillEventsProvider.overrideWith((ref) => [ev1, ev2]),
        ],
      );
      addTearDown(container.dispose);

      final progress = container.read(dailyRefillProgressProvider);

      expect(progress, isNotNull);
      // Total rooms: 101, 102, 103, 201 (4 rooms total)
      expect(progress!.totalRoomsCount, equals(4));
      // Refilled rooms today: only room 103 had a refill event today
      expect(progress.refilledRoomsCount, equals(1));
      // Next priority room: Remaining rooms are 101, 102, 201.
      // - 201 is critical (refillLimitReached).
      // - 102 is warning (needsRefill).
      // - 101 is normal (active).
      // So 201 must be the next priority room.
      expect(progress.nextPriorityRoom, equals('Room 201'));
    });

    test('picks warning room if no critical rooms are left', () {
      final hotelId = 'hotel-1';
      final now = DateTime.now();
      const p1 = Product(
        id: 'prod-1',
        sku: 'SKU1',
        nameFr: 'P1',
        nameEn: 'P1',
        nameAr: 'P1',
        nameIt: 'P1',
        maxRefillCount: 5,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 2,
        lowBidonThreshold: 1,
        bottleVolumeMl: 1000,
        bidonVolumeMl: 5000,
      );

      final rp101 = RoomProduct(
        id: 'rp-1',
        hotelId: hotelId,
        roomId: 'room-101',
        roomNumber: '101',
        floorNumber: 1,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.active,
        lastRefillAt: null,
      );

      final rp102 = RoomProduct(
        id: 'rp-2',
        hotelId: hotelId,
        roomId: 'room-102',
        roomNumber: '102',
        floorNumber: 1,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.needsRefill,
        lastRefillAt: null,
      );

      final container = ProviderContainer(
        overrides: [
          selectedHotelIdProvider.overrideWith((ref) => hotelId),
          roomProductsProvider.overrideWith((ref) => [rp101, rp102]),
          refillEventsProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

      final progress = container.read(dailyRefillProgressProvider);

      expect(progress, isNotNull);
      expect(progress!.totalRoomsCount, equals(2));
      expect(progress.refilledRoomsCount, equals(0));
      // Next priority room: Remaining rooms are 101, 102.
      // - 102 is warning.
      // - 101 is normal.
      // So 102 is the priority.
      expect(progress.nextPriorityRoom, equals('Room 102'));
    });

    test('sorts by floor and room number within priority groups', () {
      final hotelId = 'hotel-1';
      final now = DateTime.now();
      const p1 = Product(
        id: 'prod-1',
        sku: 'SKU1',
        nameFr: 'P1',
        nameEn: 'P1',
        nameAr: 'P1',
        nameIt: 'P1',
        maxRefillCount: 5,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 2,
        lowBidonThreshold: 1,
        bottleVolumeMl: 1000,
        bidonVolumeMl: 5000,
      );

      final rp102 = RoomProduct(
        id: 'rp-1',
        hotelId: hotelId,
        roomId: 'room-102',
        roomNumber: '102',
        floorNumber: 1,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.needsRefill,
        lastRefillAt: null,
      );

      final rp101 = RoomProduct(
        id: 'rp-2',
        hotelId: hotelId,
        roomId: 'room-101',
        roomNumber: '101',
        floorNumber: 1,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.needsRefill,
        lastRefillAt: null,
      );

      final rp201 = RoomProduct(
        id: 'rp-3',
        hotelId: hotelId,
        roomId: 'room-201',
        roomNumber: '201',
        floorNumber: 2,
        product: p1,
        refillCount: 0,
        bottleStartedAt: now,
        status: BottleStatus.needsRefill,
        lastRefillAt: null,
      );

      final container = ProviderContainer(
        overrides: [
          selectedHotelIdProvider.overrideWith((ref) => hotelId),
          roomProductsProvider.overrideWith((ref) => [rp102, rp101, rp201]),
          refillEventsProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

      final progress = container.read(dailyRefillProgressProvider);

      expect(progress, isNotNull);
      // All are warning rooms. Sorting order:
      // Floor 1, Room 101
      // Floor 1, Room 102
      // Floor 2, Room 201
      // So Room 101 should be next.
      expect(progress!.nextPriorityRoom, equals('Room 101'));
    });
  });
}
