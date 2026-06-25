import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';

void main() {
  group('Inventory Enforcement Tests', () {
    late MockIvraRepository repository;

    setUp(() {
      repository = MockIvraRepository();
    });

    test('replaceBottle fails when stock is 0 and autoAdjust is false', () async {
      // 1. Find a room product
      final roomProducts = await repository.roomProducts();
      expect(roomProducts.isNotEmpty, true);
      final rp = roomProducts.first;

      // 2. Set its product inventory to 0 full bottles
      final inventory = await repository.inventory(hotelId: rp.hotelId);
      final stockIndex = inventory.indexWhere((stock) => stock.product.id == rp.product.id);
      if (stockIndex != -1) {
        final stock = inventory[stockIndex];
        // Modify the private state in mock repository by recordStockAdjustment
        final adjustment = -stock.fullBottles;
        await repository.recordStockAdjustment(
          hotelId: rp.hotelId,
          productId: rp.product.id,
          fullBottlesDelta: adjustment,
          reason: 'Set to zero for test',
        );
      }

      // Verify stock is now 0
      final updatedInventory = await repository.inventory(hotelId: rp.hotelId);
      final finalStock = updatedInventory.firstWhere((stock) => stock.product.id == rp.product.id);
      expect(finalStock.fullBottles, 0);

      // 3. Calling replaceBottle without auto-adjust should throw a StateError
      expect(
        () => repository.replaceBottle(
          roomProductId: rp.id,
          notes: 'Test replacement',
          autoAdjustInventory: false,
        ),
        throwsStateError,
      );
    });

    test('replaceBottle succeeds and auto-adjusts when stock is 0 and autoAdjust is true', () async {
      final roomProducts = await repository.roomProducts();
      final rp = roomProducts.first;

      // Set stock to 0
      final inventory = await repository.inventory(hotelId: rp.hotelId);
      final stock = inventory.firstWhere((stock) => stock.product.id == rp.product.id);
      await repository.recordStockAdjustment(
        hotelId: rp.hotelId,
        productId: rp.product.id,
        fullBottlesDelta: -stock.fullBottles,
        reason: 'Set to zero for test',
      );

      // Call replaceBottle with autoAdjustInventory: true
      await repository.replaceBottle(
        roomProductId: rp.id,
        notes: 'Test replacement with auto adjust',
        autoAdjustInventory: true,
      );

      // Stock should have been increased by 1 (auto-adjusted) and then decremented by 1 (replacement)
      // Resulting in 0 full bottles, but 1 extra empty bottle
      final updatedInventory = await repository.inventory(hotelId: rp.hotelId);
      final finalStock = updatedInventory.firstWhere((stock) => stock.product.id == rp.product.id);
      expect(finalStock.fullBottles, 0);
      expect(finalStock.emptyBottles, stock.emptyBottles + 1);

      // Verify that the inventory events log includes the auto-adjustment
      final events = await repository.recentInventoryEvents(hotelId: rp.hotelId);
      expect(events.any((e) => e.reason == 'Auto-adjusted for replacement' && e.fullBottlesDelta == 1), true);
    });

    test('createRoomsFromTemplate enforces inventory stock checks', () async {
      final hotels = await repository.hotels();
      expect(hotels.isNotEmpty, true);
      final hotel = hotels.first;

      final products = await repository.products();
      expect(products.isNotEmpty, true);
      final product = products.first;

      // Set stock to 0
      final inventory = await repository.inventory(hotelId: hotel.id);
      final stockIndex = inventory.indexWhere((stock) => stock.product.id == product.id);
      if (stockIndex != -1) {
        final stock = inventory[stockIndex];
        await repository.recordStockAdjustment(
          hotelId: hotel.id,
          productId: product.id,
          fullBottlesDelta: -stock.fullBottles,
          reason: 'Set to zero for test',
        );
      }

      // createRoomsFromTemplate with 5 rooms and no auto-adjust should throw a StateError
      expect(
        () => repository.createRoomsFromTemplate(
          hotelId: hotel.id,
          floorNumber: 9,
          firstRoomNumber: 901,
          roomCount: 5,
          productIds: [product.id],
          autoAdjustInventory: false,
        ),
        throwsStateError,
      );

      // createRoomsFromTemplate with 5 rooms and auto-adjust should succeed
      await repository.createRoomsFromTemplate(
        hotelId: hotel.id,
        floorNumber: 9,
        firstRoomNumber: 901,
        roomCount: 5,
        productIds: [product.id],
        autoAdjustInventory: true,
      );

      // Verify that the inventory events log includes the auto-adjustment
      final events = await repository.recentInventoryEvents(hotelId: hotel.id);
      expect(events.any((e) => e.reason == 'Auto-adjusted for room creation template' && e.fullBottlesDelta == 5), true);
    });
  });
}
