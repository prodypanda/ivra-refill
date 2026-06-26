import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/data/offline/offline_sync_service.dart';
import 'package:ivra_refill/src/data/report_export_service.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // 1. ROLES AND SECURITY
  // ---------------------------------------------------------------------------
  group('Roles and Security', () {
    test('App Admin can fetch ALL hotels (both hotel-seaside and hotel-palms)',
        () async {
      final repository = MockIvraRepository();

      final user = await repository.currentUser();
      expect(user.role, UserRole.appAdmin);

      final hotels = await repository.hotels();
      expect(hotels.length, 2);

      final hotelIds = hotels.map((h) => h.id).toSet();
      expect(hotelIds, contains('hotel-seaside'));
      expect(hotelIds, contains('hotel-palms'));
    });

    test('App Admin can fetch ALL team members regardless of hotel', () async {
      final repository = MockIvraRepository();

      final members = await repository.teamMembers();
      expect(members.length, greaterThanOrEqualTo(4));

      final roles = members.map((m) => m.role).toSet();
      expect(roles, contains(UserRole.appAdmin));
      expect(roles, contains(UserRole.appManager));
      expect(roles, contains(UserRole.hotelManager));
      expect(roles, contains(UserRole.hotelStaff));
    });

    test('App Admin can fetch ALL approvals, alerts, rooms, inventory',
        () async {
      final repository = MockIvraRepository();

      final approvals = await repository.approvalRequests();
      expect(approvals.length, greaterThanOrEqualTo(2));

      final alerts = await repository.alerts();
      expect(alerts.length, greaterThanOrEqualTo(2));

      final rooms = await repository.rooms();
      expect(rooms.length, greaterThanOrEqualTo(2));

      final inventory = await repository.inventory();
      expect(inventory.length, greaterThanOrEqualTo(2));

      final products = await repository.products();
      expect(products.length, 5);
    });

    test(
        'Hotel Manager can only access their assigned hotel via scoped queries',
        () async {
      final repository = MockIvraRepository();

      await repository.switchDemoUser(userId: 'hotel-manager-seaside');
      final user = await repository.currentUser();
      expect(user.role, UserRole.hotelManager);
      expect(user.hotelId, 'hotel-seaside');

      // Hotel-scoped queries return only hotel-seaside data
      final rooms = await repository.rooms(hotelId: user.hotelId);
      for (final room in rooms) {
        expect(room.hotelId, 'hotel-seaside');
      }
      expect(rooms.length, 2);

      final roomProducts = await repository.roomProducts(hotelId: user.hotelId);
      for (final rp in roomProducts) {
        expect(rp.hotelId, 'hotel-seaside');
      }

      final inventory = await repository.inventory(hotelId: user.hotelId);
      for (final inv in inventory) {
        expect(inv.hotelId, 'hotel-seaside');
      }

      final approvals =
          await repository.approvalRequests(hotelId: user.hotelId);
      for (final apr in approvals) {
        expect(apr.hotelId, 'hotel-seaside');
      }

      final alerts = await repository.alerts(hotelId: user.hotelId);
      for (final alert in alerts) {
        expect(alert.hotelId, 'hotel-seaside');
      }
    });

    test('Hotel Staff can still record refills', () async {
      final repository = MockIvraRepository();

      await repository.switchDemoUser(userId: 'hotel-staff-seaside');
      final user = await repository.currentUser();
      expect(user.role, UserRole.hotelStaff);
      expect(user.hotelId, 'hotel-seaside');

      final before = (await repository.roomProducts()).first;
      await repository.recordRefill(roomProductId: before.id);

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      expect(after.refillCount, before.refillCount + 1);
    });

    test('App Manager can create hotels and approve requests', () async {
      final repository = MockIvraRepository();

      await repository.switchDemoUser(userId: 'demo-manager');
      final user = await repository.currentUser();
      expect(user.role, UserRole.appManager);

      // App Manager can create a hotel
      final hotelsBefore = await repository.hotels();
      await repository.createHotel(
        name: 'Manager Hotel',
        city: 'Kano',
        country: 'Nigeria',
        contactName: 'Manager Contact',
        email: 'mgr@test.example',
        phone: '+234 000 000 0000',
      );
      final hotelsAfter = await repository.hotels();
      expect(hotelsAfter.length, hotelsBefore.length + 1);

      // App Manager can approve requests
      final pendingApprovals = await repository.approvalRequests();
      expect(pendingApprovals, isNotEmpty);
      final requestId = pendingApprovals.first.id;
      await repository.approveRequest(approvalRequestId: requestId);

      final afterApproval = await repository.approvalRequests();
      expect(afterApproval.any((r) => r.id == requestId), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. APPROVAL WORKFLOW
  // ---------------------------------------------------------------------------
  group('Approval Workflow', () {
    test('hotel info edit creates pending approval with correct old/new values',
        () async {
      final repository = MockIvraRepository();
      final hotel = (await repository.hotels()).first;

      await repository.submitChangeRequest(
        hotelId: hotel.id,
        title: 'Update hotel name',
        targetTable: 'hotels',
        targetId: hotel.id,
        oldData: {'name': hotel.name},
        newData: {'name': 'Renamed Hotel'},
      );

      final request = (await repository.approvalRequests()).first;
      expect(request.status, ApprovalStatus.pending);
      expect(request.targetTable, 'hotels');
      expect(request.targetId, hotel.id);
      expect(request.oldValue, contains('name: ${hotel.name}'));
      expect(request.newValue, contains('name: Renamed Hotel'));
    });

    test('live hotel data is NOT changed by pending edit', () async {
      final repository = MockIvraRepository();
      final hotel = (await repository.hotels()).first;
      final originalName = hotel.name;

      await repository.submitChangeRequest(
        hotelId: hotel.id,
        title: 'Update hotel name',
        targetTable: 'hotels',
        targetId: hotel.id,
        oldData: {'name': hotel.name},
        newData: {'name': 'Should Not Apply Yet'},
      );

      // Live hotel name should remain unchanged
      final liveHotel =
          (await repository.hotels()).firstWhere((h) => h.id == hotel.id);
      expect(liveHotel.name, originalName);
    });

    test('approving the request applies the changes to live data', () async {
      final repository = MockIvraRepository();
      final hotel = (await repository.hotels()).first;

      await repository.submitChangeRequest(
        hotelId: hotel.id,
        title: 'Rename Seaside Hotel',
        targetTable: 'hotels',
        targetId: hotel.id,
        oldData: {'name': hotel.name, 'address': hotel.address},
        newData: {'name': 'Approved Seaside', 'address': '1 Approved St'},
      );

      final request = (await repository.approvalRequests()).first;
      await repository.approveRequest(approvalRequestId: request.id);

      final updated =
          (await repository.hotels()).firstWhere((h) => h.id == hotel.id);
      expect(updated.name, 'Approved Seaside');
      expect(updated.address, '1 Approved St');
    });

    test('rejecting a request keeps live data unchanged', () async {
      final repository = MockIvraRepository();
      final hotel = (await repository.hotels()).first;
      final originalName = hotel.name;

      await repository.submitChangeRequest(
        hotelId: hotel.id,
        title: 'Reject this edit',
        targetTable: 'hotels',
        targetId: hotel.id,
        oldData: {'name': hotel.name},
        newData: {'name': 'Rejected Name'},
      );

      final request = (await repository.approvalRequests()).first;
      await repository.rejectRequest(approvalRequestId: request.id);

      final liveHotel =
          (await repository.hotels()).firstWhere((h) => h.id == hotel.id);
      expect(liveHotel.name, originalName);
    });

    test(
        'old_value, new_value, requestedByName, requestedAt are stored correctly',
        () async {
      final repository = MockIvraRepository();
      final hotel = (await repository.hotels()).first;
      final beforeSubmit = DateTime.now();

      await repository.submitChangeRequest(
        hotelId: hotel.id,
        title: 'Update phone',
        targetTable: 'hotels',
        targetId: hotel.id,
        oldData: {'phone': hotel.phone},
        newData: {'phone': '+1 999 888 7777'},
      );

      final request = (await repository.approvalRequests()).first;
      expect(request.oldValue, contains('phone: ${hotel.phone}'));
      expect(request.newValue, contains('phone: +1 999 888 7777'));
      expect(request.requestedByName, isNotEmpty);
      expect(
        request.requestedAt
            .isAfter(beforeSubmit.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(request.oldData['phone'], hotel.phone);
      expect(request.newData['phone'], '+1 999 888 7777');
    });
  });

  // ---------------------------------------------------------------------------
  // 3. REFILL WORKFLOW
  // ---------------------------------------------------------------------------
  group('Refill Workflow', () {
    test('single refill increments count by one', () async {
      final repository = MockIvraRepository();
      final before = (await repository.roomProducts()).first;

      await repository.recordRefill(roomProductId: before.id);

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      expect(after.refillCount, before.refillCount + 1);
    });

    test('lastRefillAt updates after refill', () async {
      final repository = MockIvraRepository();
      final before = (await repository.roomProducts()).first;
      final beforeTime = before.lastRefillAt;

      await repository.recordRefill(roomProductId: before.id);

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      expect(after.lastRefillAt, isNotNull);
      if (beforeTime != null) {
        expect(after.lastRefillAt!.isAfter(beforeTime), true);
      }
    });

    test(
        'status changes to refillLimitReached at max count '
        '(rp-101-shampoo: refillCount 7, max 10, refill 3 times)', () async {
      final repository = MockIvraRepository();
      // rp-101-shampoo starts with refillCount 7, maxRefillCount 10
      final start = (await repository.roomProducts())
          .firstWhere((item) => item.id == 'rp-101-shampoo');
      expect(start.refillCount, 7);
      expect(start.product.maxRefillCount, 10);

      // Refill 3 times to reach count 10
      await repository.recordRefill(roomProductId: 'rp-101-shampoo');
      await repository.recordRefill(roomProductId: 'rp-101-shampoo');
      await repository.recordRefill(roomProductId: 'rp-101-shampoo');

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == 'rp-101-shampoo');
      expect(after.refillCount, 10);
      expect(after.status, BottleStatus.refillLimitReached);
    });

    test('each refill creates a history event', () async {
      final repository = MockIvraRepository();
      final roomProduct = (await repository.roomProducts()).first;

      await repository.recordRefill(roomProductId: roomProduct.id);
      await repository.recordRefill(roomProductId: roomProduct.id);

      final events = await repository.recentRefillEvents();
      final refillEvents = events
          .where(
            (e) =>
                e.type == RefillEventType.refill &&
                e.roomProductId == roomProduct.id,
          )
          .toList();
      expect(refillEvents.length, 2);
    });

    test('refill event stores previousRefillCount and newRefillCount correctly',
        () async {
      final repository = MockIvraRepository();
      final before = (await repository.roomProducts()).first;
      final originalCount = before.refillCount;

      await repository.recordRefill(roomProductId: before.id);

      final event = (await repository.recentRefillEvents()).first;
      expect(event.type, RefillEventType.refill);
      expect(event.previousRefillCount, originalCount);
      expect(event.newRefillCount, originalCount + 1);
      expect(event.roomProductId, before.id);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. UNDO AND CORRECTION
  // ---------------------------------------------------------------------------
  group('Undo and Correction', () {
    test('undo restores previous count', () async {
      final repository = MockIvraRepository();
      final before = (await repository.roomProducts()).first;
      final originalCount = before.refillCount;

      await repository.recordRefill(roomProductId: before.id);
      final midPoint = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      expect(midPoint.refillCount, originalCount + 1);

      final event = (await repository.recentRefillEvents()).first;
      await repository.undoRefill(refillEventId: event.id);

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      expect(after.refillCount, originalCount);
    });

    test('undo creates undo event with correct counts', () async {
      final repository = MockIvraRepository();
      final before = (await repository.roomProducts()).first;
      final originalCount = before.refillCount;

      await repository.recordRefill(roomProductId: before.id);
      final refillEvent = (await repository.recentRefillEvents()).first;
      await repository.undoRefill(refillEventId: refillEvent.id);

      final undoEvent = (await repository.recentRefillEvents()).first;
      expect(undoEvent.type, RefillEventType.undo);
      expect(undoEvent.previousRefillCount, originalCount + 1);
      expect(undoEvent.newRefillCount, originalCount);
    });

    test(
        'correction request creates pending approval with Correction request in title',
        () async {
      final repository = MockIvraRepository();
      final roomProduct = (await repository.roomProducts()).first;

      await repository.recordRefill(roomProductId: roomProduct.id);
      final event = (await repository.recentRefillEvents()).first;

      await repository.requestCorrection(
        refillEventId: event.id,
        reason: 'Wrong bottle was refilled',
      );

      final approvals = await repository.approvalRequests();
      expect(
        approvals.first.title,
        contains('Correction request'),
      );
      expect(approvals.first.status, ApprovalStatus.pending);
      expect(approvals.first.targetTable, 'correction_requests');
    });

    test('correction request stores the reason', () async {
      final repository = MockIvraRepository();
      final roomProduct = (await repository.roomProducts()).first;

      await repository.recordRefill(roomProductId: roomProduct.id);
      final event = (await repository.recentRefillEvents()).first;

      const reason = 'Accidentally refilled the wrong product';
      await repository.requestCorrection(
        refillEventId: event.id,
        reason: reason,
      );

      final approval = (await repository.approvalRequests()).first;
      expect(approval.newValue, reason);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. INVENTORY AND ORDERS
  // ---------------------------------------------------------------------------
  group('Inventory and Orders', () {
    test('inventory returns correct bottle/bidon counts', () async {
      final repository = MockIvraRepository();
      final inventory = await repository.inventory(hotelId: 'hotel-seaside');
      expect(inventory.length, 2);

      // Shampoo inventory
      final shampoo = inventory.firstWhere(
        (item) => item.product.id == 'prod-shampoo',
      );
      expect(shampoo.fullBottles, 9);
      expect(shampoo.emptyBottles, 17);
      expect(shampoo.fullBidons, 3);
      expect(shampoo.openBidons, 1);
      expect(shampoo.emptyBidons, 5);

      // Shower Gel inventory
      final gel = inventory.firstWhere(
        (item) => item.product.id == 'prod-shower-gel',
      );
      expect(gel.fullBottles, 22);
      expect(gel.fullBidons, 7);
    });

    test(
        'lowBottles and lowBidons detection '
        '(shampoo: 9 full bottles, threshold 12 → lowBottles true)', () async {
      final repository = MockIvraRepository();
      final inventory = await repository.inventory(hotelId: 'hotel-seaside');

      final shampoo = inventory.firstWhere(
        (item) => item.product.id == 'prod-shampoo',
      );
      // fullBottles (9) <= lowBottleThreshold (12)
      expect(shampoo.lowBottles, true);
      // fullBidons (3) <= lowBidonThreshold (4)
      expect(shampoo.lowBidons, true);

      final gel = inventory.firstWhere(
        (item) => item.product.id == 'prod-shower-gel',
      );
      // fullBottles (22) > lowBottleThreshold (12)
      expect(gel.lowBottles, false);
      // fullBidons (7) > lowBidonThreshold (4)
      expect(gel.lowBidons, false);
    });

    test('suggested orders calculate positive quantities for low stock',
        () async {
      final repository = MockIvraRepository();
      final orders = await repository.suggestedOrders(hotelId: 'hotel-seaside');

      // Shampoo should have suggested order because of low stock
      final shampooOrder = orders.firstWhere(
        (order) => order.product.id == 'prod-shampoo',
      );
      // bottlesToOrder = max(threshold*2 - fullBottles, 0)
      //                = max(12*2 - 9, 0) = 15
      expect(shampooOrder.bottlesToOrder, greaterThan(0));
      expect(shampooOrder.bottlesToOrder, 15);
      // bidonsToOrder = max(4*2 - 3, 0) = 5
      expect(shampooOrder.bidonsToOrder, greaterThan(0));
      expect(shampooOrder.bidonsToOrder, 5);
    });

    test('stock adjustment updates inventory counts', () async {
      final repository = MockIvraRepository();
      final before = (await repository.inventory()).first;

      await repository.recordStockAdjustment(
        hotelId: before.hotelId,
        productId: before.product.id,
        fullBottlesDelta: 10,
        fullBidonsDelta: 3,
        emptyBottlesDelta: -2,
        reason: 'Delivery received',
      );

      final after = (await repository.inventory())
          .firstWhere((item) => item.id == before.id);
      expect(after.fullBottles, before.fullBottles + 10);
      expect(after.fullBidons, before.fullBidons + 3);
      expect(after.emptyBottles, before.emptyBottles - 2);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. OFFLINE MODE
  // ---------------------------------------------------------------------------
  group('Offline Mode', () {
    test('enqueue and sync refill action', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = MockIvraRepository();
      final service = OfflineSyncService();
      final before = (await repository.roomProducts()).first;

      await service.enqueue(
        type: SyncActionType.refill,
        payload: {'roomProductId': before.id},
      );

      final pending = await service.pendingActions();
      expect(pending.length, 1);
      expect(pending.first.type, SyncActionType.refill);

      final synced = await service.syncPending(repository);
      expect(synced, 1);
      expect(await service.pendingActions(), isEmpty);

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      expect(after.refillCount, before.refillCount + 1);
    });

    test('enqueue and sync stock adjustment action', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = MockIvraRepository();
      final service = OfflineSyncService();
      final before = (await repository.inventory()).first;

      await service.enqueue(
        type: SyncActionType.stockAdjustment,
        payload: {
          'hotelId': before.hotelId,
          'productId': before.product.id,
          'fullBottlesDelta': 5,
          'reason': 'Offline delivery',
        },
      );

      expect(await service.syncPending(repository), 1);
      expect(await service.pendingActions(), isEmpty);

      final after = (await repository.inventory())
          .firstWhere((item) => item.id == before.id);
      expect(after.fullBottles, before.fullBottles + 5);
    });

    test('failed sync keeps action in queue with error info', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = MockIvraRepository();
      final service = OfflineSyncService();

      await service.enqueue(
        type: SyncActionType.undoRefill,
        payload: {'refillEventId': 'non-existent-event'},
      );

      final summary = await service.syncPendingDetailed(repository);
      expect(summary.synced, 0);
      expect(summary.failed, 1);
      expect(summary.hasFailures, true);

      final pending = await service.pendingActions();
      expect(pending.length, 1);
      expect(pending.single.lastError, isNotNull);
      expect(pending.single.attemptCount, 1);
    });

    test('duplicate refill with same clientRequestId is idempotent', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = MockIvraRepository();
      final before = (await repository.roomProducts()).first;

      await repository.recordRefill(
        roomProductId: before.id,
        clientRequestId: 'idempotent-refill-1',
      );
      await repository.recordRefill(
        roomProductId: before.id,
        clientRequestId: 'idempotent-refill-1',
      );

      final after = (await repository.roomProducts())
          .firstWhere((item) => item.id == before.id);
      // Only incremented once despite two calls with same clientRequestId
      expect(after.refillCount, before.refillCount + 1);

      final events = (await repository.recentRefillEvents())
          .where((e) => e.type == RefillEventType.refill);
      expect(events, hasLength(1));
    });

    test('all SyncActionType variants can be enqueued and round-trip',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();

      for (final type in SyncActionType.values) {
        await service.enqueue(
          type: type,
          payload: {'test': type.value},
        );
      }

      final pending = await service.pendingActions();
      expect(pending.length, SyncActionType.values.length);

      final types = pending.map((a) => a.type).toSet();
      expect(types, containsAll(SyncActionType.values));

      // Verify each type round-trips correctly
      expect(types, contains(SyncActionType.refill));
      expect(types, contains(SyncActionType.undoRefill));
      expect(types, contains(SyncActionType.correctionRequest));
      expect(types, contains(SyncActionType.bottleReplacement));
      expect(types, contains(SyncActionType.stockAdjustment));
      expect(types, contains(SyncActionType.pendingEdit));
    });
  });

  // ---------------------------------------------------------------------------
  // 7. REPORTS AND LOCALIZATION
  // ---------------------------------------------------------------------------
  group('Reports and Localization', () {
    test('CSV export contains expected headers', () async {
      final repository = MockIvraRepository();
      final service = ReportExportService();
      final roomProduct = (await repository.roomProducts()).first;

      await repository.recordRefill(roomProductId: roomProduct.id);
      await repository.refreshSmartAlerts(hotelId: 'hotel-seaside');

      final refillCsv =
          service.refillHistoryCsv(await repository.recentRefillEvents());
      expect(refillCsv, contains('event_id'));
      expect(refillCsv, contains('room_product_id'));
      expect(refillCsv, contains('type'));
      expect(refillCsv, contains('previous_refill_count'));
      expect(refillCsv, contains('new_refill_count'));
      expect(refillCsv, contains(roomProduct.id));

      final orderCsv =
          service.suggestedOrdersCsv(await repository.suggestedOrders());
      expect(orderCsv, contains('bottles_to_order'));
      expect(orderCsv, contains('bidons_to_order'));
      expect(orderCsv, contains('product_sku'));

      final inventoryCsv = service.inventoryCsv(await repository.inventory());
      expect(inventoryCsv, contains('full_bottles'));
      expect(inventoryCsv, contains('empty_bottles'));
      expect(inventoryCsv, contains('full_bidons'));
      expect(inventoryCsv, contains('low_bottles'));
      expect(inventoryCsv, contains('low_bidons'));

      final alertCsv = service.alertsCsv(await repository.alerts());
      expect(alertCsv, contains('alert_id'));
      expect(alertCsv, contains('severity'));
      expect(alertCsv, contains('is_resolved'));
    });

    test('PDF export returns non-empty byte data', () async {
      final repository = MockIvraRepository();
      final service = ReportExportService();
      final roomProduct = (await repository.roomProducts()).first;

      await repository.recordRefill(roomProductId: roomProduct.id);
      await repository.refreshSmartAlerts(hotelId: 'hotel-seaside');

      final refillPdf = await service.refillHistoryPdf(
        await repository.recentRefillEvents(),
      );
      expect(refillPdf.length, greaterThan(100));

      final orderPdf = await service.suggestedOrdersPdf(
        await repository.suggestedOrders(),
      );
      expect(orderPdf.length, greaterThan(100));

      final inventoryPdf = await service.inventoryPdf(
        await repository.inventory(),
      );
      expect(inventoryPdf.length, greaterThan(100));

      final alertsPdf = await service.alertsPdf(
        await repository.alerts(),
      );
      expect(alertsPdf.length, greaterThan(100));
    });

    test(
        'English, French, and Arabic labels are available via AppLocalizations',
        () {
      final en = AppLocalizations(const Locale('en'));
      final fr = AppLocalizations(const Locale('fr'));
      final ar = AppLocalizations(const Locale('ar'));

      // English labels
      expect(en.t('dashboard'), 'Dashboard');
      expect(en.t('hotels'), 'Hotels');
      expect(en.t('rooms'), 'Rooms');
      expect(en.t('inventory'), 'Store Stock');

      // French labels
      expect(fr.t('dashboard'), 'Tableau de bord');
      expect(fr.t('hotels'), 'Hôtels');
      expect(fr.t('rooms'), 'Chambres');
      expect(fr.t('inventory'), 'Stock magasin');

      // Arabic labels
      expect(ar.t('dashboard'), 'لوحة القيادة');
      expect(ar.t('hotels'), 'الفنادق');
      expect(ar.t('rooms'), 'الغرف');
      expect(ar.t('inventory'), 'مخزون المتجر');
    });

    test('all 3 languages have dashboard, hotels, rooms, inventory keys', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = AppLocalizations(locale);
        for (final key in ['dashboard', 'hotels', 'rooms', 'inventory']) {
          final value = l10n.t(key);
          expect(value, isNotEmpty,
              reason:
                  'Key "$key" missing or empty for locale ${locale.languageCode}');
          // Value should not fall back to the key name itself
          expect(value, isNot(equals(key)),
              reason:
                  'Key "$key" should have a translated value for ${locale.languageCode}');
        }
      }
    });

    test('RoomProduct status is calculated dynamically for age and refills', () {
      final productRefillable = Product(
        id: 'p1',
        sku: 'SKU1',
        nameEn: 'P1',
        nameFr: 'P1',
        nameAr: 'P1',
        nameIt: 'P1',
        maxRefillCount: 40,
        maxBottleAgeDays: 5,
        lowBottleThreshold: 5,
        lowBidonThreshold: 2,
        refillType: RefillType.refillable,
      );

      final rpTooOld = RoomProduct(
        id: 'rp1',
        hotelId: 'h1',
        roomId: 'r1',
        roomNumber: '101',
        floorNumber: 1,
        product: productRefillable,
        refillCount: 0,
        lastRefillAt: null,
        bottleStartedAt: DateTime.now().subtract(const Duration(days: 11)),
        status: BottleStatus.active,
      );

      final rpRefillsExceeded = RoomProduct(
        id: 'rp2',
        hotelId: 'h1',
        roomId: 'r1',
        roomNumber: '101',
        floorNumber: 1,
        product: productRefillable,
        refillCount: 43,
        lastRefillAt: null,
        bottleStartedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: BottleStatus.active,
      );

      expect(rpTooOld.status, BottleStatus.tooOld);
      expect(rpRefillsExceeded.status, BottleStatus.refillLimitReached);
    });
  });
}
