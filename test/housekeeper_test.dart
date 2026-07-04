import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';

void main() {
  group('Housekeeper Role & Allocations Tests', () {
    late MockIvraRepository repository;
    late String hotelId;
    late String housekeeperId;
    late String productId;

    setUp(() async {
      repository = MockIvraRepository();

      // 1. Find standard hotel and product
      final hotels = await repository.hotels();
      expect(hotels.isNotEmpty, true);
      hotelId = hotels.first.id;

      final products = await repository.products();
      expect(products.isNotEmpty, true);
      productId = products.first.id;

      // 2. Invite and accept a housekeeper team member
      const housekeeperEmail = 'housekeeper@seaside.example';
      const housekeeperName = 'Fatima Diop';

      await repository.inviteTeamMember(
        email: housekeeperEmail,
        fullName: housekeeperName,
        role: 'housekeeper',
        hotelId: hotelId,
      );

      final invites = await repository.teamInvitations(hotelId: hotelId);
      final invite = invites.firstWhere((inv) => inv.email == housekeeperEmail);
      await repository.acceptTeamInvitation(token: invite.inviteToken!);

      final team = await repository.teamMembers(hotelId: hotelId);
      final housekeeper = team.firstWhere((member) => member.email == housekeeperEmail);
      housekeeperId = housekeeper.id;
    });

    test('Housekeeper checkout stock successfully transfers central stock to allocations', () async {
      // Get initial central inventory
      final initialInventory = await repository.inventory(hotelId: hotelId);
      final initialProductStock = initialInventory.firstWhere((stock) => stock.product.id == productId);

      final int checkoutBottles = 5;
      final int checkoutBidons = 2;

      expect(initialProductStock.fullBottles >= checkoutBottles, true);
      expect(initialProductStock.fullBidons >= checkoutBidons, true);

      // Perform checkout
      await repository.checkoutHousekeeperStock(
        housekeeperId: housekeeperId,
        productId: productId,
        fullBottles: checkoutBottles,
        fullBidons: checkoutBidons,
      );

      // Verify central inventory is decremented
      final updatedInventory = await repository.inventory(hotelId: hotelId);
      final updatedProductStock = updatedInventory.firstWhere((stock) => stock.product.id == productId);
      expect(updatedProductStock.fullBottles, initialProductStock.fullBottles - checkoutBottles);
      expect(updatedProductStock.fullBidons, initialProductStock.fullBidons - checkoutBidons);

      // Verify housekeeper allocations are populated correctly
      final allocations = await repository.fetchHousekeeperAllocations(
        housekeeperId: housekeeperId,
        hotelId: hotelId,
      );
      final alloc = allocations.firstWhere((a) => a.product.id == productId);
      expect(alloc.fullBottles, checkoutBottles);
      expect(alloc.fullBidons, checkoutBidons);
      expect(alloc.emptyBottles, 0);
      expect(alloc.openBidons, 0);
      expect(alloc.emptyBidons, 0);
      expect(alloc.openBidonVolumeLeftMl, 0.0);
    });

    test('Housekeeper checkout stock fails if insufficient central stock', () async {
      final initialInventory = await repository.inventory(hotelId: hotelId);
      final initialProductStock = initialInventory.firstWhere((stock) => stock.product.id == productId);

      // Attempt to checkout more than available central stock
      final excessiveBottles = initialProductStock.fullBottles + 10;
      expect(
        () => repository.checkoutHousekeeperStock(
          housekeeperId: housekeeperId,
          productId: productId,
          fullBottles: excessiveBottles,
          fullBidons: 0,
        ),
        throwsException,
      );
    });

    test('Room refill as housekeeper deducts from checked-out allocations rather than central inventory', () async {
      // 1. Checkout some stock for housekeeper first
      await repository.checkoutHousekeeperStock(
        housekeeperId: housekeeperId,
        productId: productId,
        fullBottles: 0,
        fullBidons: 1, // Let's checkout 1 full bidon (e.g. 5000ml capacity)
      );

      // Switch active user to the housekeeper
      await repository.switchDemoUser(userId: housekeeperId);

      // Find a room product associated with our product and hotel
      final roomProducts = await repository.roomProducts();
      final rp = roomProducts.firstWhere((item) => item.hotelId == hotelId && item.product.id == productId);

      final initialInventory = await repository.inventory(hotelId: hotelId);
      final initialProductStock = initialInventory.firstWhere((stock) => stock.product.id == productId);

      // Record room refill
      await repository.recordRefill(
        roomProductId: rp.id,
        notes: 'Housekeeper refill test',
      );

      // Verify central inventory remains absolutely untouched
      final postRefillInventory = await repository.inventory(hotelId: hotelId);
      final postRefillProductStock = postRefillInventory.firstWhere((stock) => stock.product.id == productId);
      expect(postRefillProductStock.fullBidons, initialProductStock.fullBidons);
      expect(postRefillProductStock.openBidonVolumeLeftMl, initialProductStock.openBidonVolumeLeftMl);

      // Verify housekeeper allocations are decremented
      final allocations = await repository.fetchHousekeeperAllocations(
        housekeeperId: housekeeperId,
        hotelId: hotelId,
      );
      final alloc = allocations.firstWhere((a) => a.product.id == productId);

      // Checked out 1 full bidon (5000ml). RecordRefill took standard bottle volume (usually 1000ml).
      // So full bidons decreases by 1 (to 0), openBidons becomes 1, and volume left becomes 5000 - 1000 = 4000ml.
      expect(alloc.fullBidons, 0);
      expect(alloc.openBidons, 1);
      expect(alloc.openBidonVolumeLeftMl, 4000.0);
    });

    test('Room bottle replacement as housekeeper deducts from allocations and tracks empty bottles', () async {
      // 1. Checkout 2 full bottles
      await repository.checkoutHousekeeperStock(
        housekeeperId: housekeeperId,
        productId: productId,
        fullBottles: 2,
        fullBidons: 0,
      );

      // Switch active user to housekeeper
      await repository.switchDemoUser(userId: housekeeperId);

      // Find room product
      final roomProducts = await repository.roomProducts();
      final rp = roomProducts.firstWhere((item) => item.hotelId == hotelId && item.product.id == productId);

      // Perform bottle replacement
      await repository.replaceBottle(
        roomProductId: rp.id,
        notes: 'Replace bottle test',
        autoAdjustInventory: false,
      );

      // Verify housekeeper allocations update
      final allocations = await repository.fetchHousekeeperAllocations(
        housekeeperId: housekeeperId,
        hotelId: hotelId,
      );
      final alloc = allocations.firstWhere((a) => a.product.id == productId);
      expect(alloc.fullBottles, 1); // 2 -> 1
      expect(alloc.emptyBottles, 1); // 0 -> 1
    });

    test('Housekeeper returning remaining stock merges and aggregates volumes back to central inventory', () async {
      // 1. Set up a housekeeper allocation with some remaining stock manually or via operations
      await repository.checkoutHousekeeperStock(
        housekeeperId: housekeeperId,
        productId: productId,
        fullBottles: 2,
        fullBidons: 2,
      );

      // Switch to housekeeper to perform refills to get empty/open containers
      await repository.switchDemoUser(userId: housekeeperId);

      final roomProducts = await repository.roomProducts();
      final rp = roomProducts.firstWhere((item) => item.hotelId == hotelId && item.product.id == productId);

      // Replace 1 bottle to get 1 empty bottle
      await repository.replaceBottle(
        roomProductId: rp.id,
        notes: 'Create empty bottle',
        autoAdjustInventory: false,
      );

      // Refill 2 times (2000ml total) to convert 1 full bidon (5000ml) to open bidon with 3000ml remaining
      await repository.recordRefill(roomProductId: rp.id);
      await repository.recordRefill(roomProductId: rp.id);

      // Switch back to admin or any user (not strictly needed but good to show return works for targets)
      await repository.switchDemoUser(userId: 'demo-admin');

      // Verify current allocations state before returning
      final allocsBefore = await repository.fetchHousekeeperAllocations(housekeeperId: housekeeperId, hotelId: hotelId);
      final alloc = allocsBefore.firstWhere((a) => a.product.id == productId);
      expect(alloc.fullBottles, 1);
      expect(alloc.emptyBottles, 1);
      expect(alloc.fullBidons, 1);
      expect(alloc.openBidons, 1);
      expect(alloc.openBidonVolumeLeftMl, 3000.0);

      // Get central inventory before returning
      final centralBefore = await repository.inventory(hotelId: hotelId);
      final centralStockBefore = centralBefore.firstWhere((stock) => stock.product.id == productId);

      // Perform Return Stock
      await repository.returnHousekeeperStock(
        housekeeperId: housekeeperId,
        productId: productId,
        fullBottles: 1,
        emptyBottles: 1,
        fullBidons: 1,
        openBidons: 1,
        emptyBidons: 0,
        openBidonVolumeLeftMl: 3000.0,
      );

      // Verify housekeeper allocations are cleared/reduced accordingly
      final allocsAfter = await repository.fetchHousekeeperAllocations(housekeeperId: housekeeperId, hotelId: hotelId);
      final allocAfter = allocsAfter.firstWhere((a) => a.product.id == productId);
      expect(allocAfter.fullBottles, 0);
      expect(allocAfter.emptyBottles, 0);
      expect(allocAfter.fullBidons, 0);
      expect(allocAfter.openBidons, 0);
      expect(allocAfter.openBidonVolumeLeftMl, 0.0);

      // Verify central inventory is updated and merged symmetrically
      final centralAfter = await repository.inventory(hotelId: hotelId);
      final centralStockAfter = centralAfter.firstWhere((stock) => stock.product.id == productId);

      expect(centralStockAfter.fullBottles, centralStockBefore.fullBottles + 1);
      expect(centralStockAfter.emptyBottles, centralStockBefore.emptyBottles + 1);

      // Symmetrical Volume Merging:
      // Suppose central inventory already had some open bidon volume, say V_central.
      // After returning Fatima's 3000ml remaining volume:
      // new_V = V_central + 3000.
      // If new_V >= 5000 (bidon capacity), it increases fullBidons by floor(new_V/5000),
      // and sets central open volume to new_V % 5000.
      final expectedTotalOpenVolume = centralStockBefore.openBidonVolumeLeftMl + 3000.0;
      final expectedExtraFullBidons = (expectedTotalOpenVolume / 5000.0).floor();
      final expectedRemainingOpenVolume = expectedTotalOpenVolume - (expectedExtraFullBidons * 5000.0);

      expect(centralStockAfter.fullBidons, centralStockBefore.fullBidons + 1 + expectedExtraFullBidons);
      expect(centralStockAfter.openBidonVolumeLeftMl, expectedRemainingOpenVolume);
      if (expectedRemainingOpenVolume > 0) {
        expect(centralStockAfter.openBidons, 1);
      }
    });

    test('Can add product to room and remove product from room on repository', () async {
      final initialRoomProducts = await repository.roomProducts();
      final r101ProductsBefore = initialRoomProducts.where((rp) => rp.roomId == 'room-101').toList();
      final initialCount = r101ProductsBefore.length;

      expect(r101ProductsBefore.any((rp) => rp.product.id == 'prod-conditioner'), false);

      await repository.addProductToRoom(
        hotelId: hotelId,
        floor: '1',
        roomNumber: '101',
        productSku: 'IVR-CON-1L',
        autoAdjustInventory: true,
      );

      final roomProductsAfterAdd = await repository.roomProducts();
      final r101ProductsAfterAdd = roomProductsAfterAdd.where((rp) => rp.roomId == 'room-101').toList();
      expect(r101ProductsAfterAdd.length, initialCount + 1);

      final addedProduct = r101ProductsAfterAdd.firstWhere((rp) => rp.product.id == 'prod-conditioner');
      expect(addedProduct.roomNumber, '101');

      await repository.removeProductFromRoom(roomProductId: addedProduct.id);

      final roomProductsAfterRemove = await repository.roomProducts();
      final r101ProductsAfterRemove = roomProductsAfterRemove.where((rp) => rp.roomId == 'room-101').toList();
      expect(r101ProductsAfterRemove.length, initialCount);
      expect(r101ProductsAfterRemove.any((rp) => rp.product.id == 'prod-conditioner'), false);
    });
  });
}
