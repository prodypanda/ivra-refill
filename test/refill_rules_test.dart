import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/offline/offline_sync_service.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/data/report_export_service.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/features/auth/auth_validation.dart';
import 'package:ivra_refill/src/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth validation catches invalid email and password reset values', () {
    expect(AuthValidation.email(''), 'authValidationEmailRequired');
    expect(AuthValidation.email('wrong'), 'authValidationEmailInvalid');
    expect(AuthValidation.email('manager@ivra.example'), isNull);

    expect(AuthValidation.password('short'), 'authValidationPasswordTooShort');
    expect(
      AuthValidation.matchingPasswords('strongpass', 'different'),
      'authValidationPasswordsDoNotMatch',
    );
    expect(
        AuthValidation.matchingPasswords('strongpass', 'strongpass'), isNull);
  });

  test('password reset redirect uses web path routes', () {
    expect(
      buildPasswordResetRedirectUrl(
        Uri.parse('https://refill.ivra-cosmetics.com/app/login'),
      ),
      'https://refill.ivra-cosmetics.com/app/reset-password',
    );
    expect(
      buildPasswordResetRedirectUrl(
        Uri.parse('https://refill.ivra-cosmetics.com/login'),
      ),
      'https://refill.ivra-cosmetics.com/reset-password',
    );
    expect(
      buildPasswordResetRedirectUrl(Uri.parse('ivra://app/login')),
      'ivra://app/reset-password',
    );
  });

  test('Supabase role checks are null safe for inactive accounts', () {
    final sql =
        File('supabase/migrations/0001_initial_schema.sql').readAsStringSync();

    expect(sql, isNot(contains("current_user_role() <> 'app_admin'")));
    expect(sql, isNot(contains('current_user_role() not in')));
    expect(sql, contains("current_user_role() is distinct from 'app_admin'"));
    expect(sql, isNot(contains('profiles_update_ivra')));
    expect(sql, isNot(contains('refill_events_insert_hotel')));
    expect(sql, isNot(contains('inventory_events_insert_hotel')));
    expect(sql, isNot(contains('approvals_update_ivra')));

    final rlsVerification =
        File('supabase/rls_verification.sql').readAsStringSync();
    expect(rlsVerification, contains('public.submit_change_request'));
    expect(
      rlsVerification,
      contains('cannot directly insert approval requests'),
    );
  });

  test('production release scripts require Supabase values', () {
    final helper = File('scripts/_ivra_env.ps1').readAsStringSync();
    expect(helper, contains('RequireSupabase'));
    expect(helper, contains('Production Supabase values are required'));

    for (final path in [
      'scripts/build_web.ps1',
      'scripts/build_android_release.ps1',
      'scripts/build_android_bundle.ps1',
      'scripts/package_release.ps1',
    ]) {
      final script = File(path).readAsStringSync();
      expect(script, contains('-RequireSupabase'));
    }

    final debugScript =
        File('scripts/build_android_debug.ps1').readAsStringSync();
    expect(debugScript, isNot(contains('-RequireSupabase')));
  });

  test('current user profile can be updated in the demo repository', () async {
    final repository = MockIvraRepository();

    await repository.updateCurrentUserProfile(fullName: 'Updated Admin');
    await repository.changeCurrentUserPassword(password: 'newsecurepass');

    final currentUser = await repository.currentUser();
    final members = await repository.teamMembers();

    expect(currentUser.fullName, 'Updated Admin');
    expect(
      members.firstWhere((member) => member.id == currentUser.id).fullName,
      'Updated Admin',
    );
  });

  test('demo repository can switch between access roles', () async {
    final repository = MockIvraRepository();

    await repository.switchDemoUser(userId: 'hotel-manager-seaside');
    expect((await repository.currentUser()).role, UserRole.hotelManager);
    expect((await repository.currentUser()).hotelId, 'hotel-seaside');

    await repository.switchDemoUser(userId: 'demo-admin');
    expect((await repository.currentUser()).role, UserRole.appAdmin);
  });

  test('recordRefill increments count and creates event', () async {
    final repository = MockIvraRepository();
    final before = (await repository.roomProducts()).first;

    await repository.recordRefill(roomProductId: before.id);

    final after = (await repository.roomProducts()).first;
    final events = await repository.recentRefillEvents();

    expect(after.refillCount, before.refillCount + 1);
    expect(events.first.type, RefillEventType.refill);
  });

  test('client request ids make retryable mutations idempotent', () async {
    final repository = MockIvraRepository();
    final before = (await repository.roomProducts()).first;
    final stockBefore = (await repository.inventory())
        .firstWhere((item) => item.product.id == before.product.id);
    final approvalCount = (await repository.approvalRequests()).length;

    await repository.recordRefill(
      roomProductId: before.id,
      clientRequestId: 'retry-refill-1',
    );
    await repository.recordRefill(
      roomProductId: before.id,
      clientRequestId: 'retry-refill-1',
    );
    await repository.recordStockAdjustment(
      hotelId: stockBefore.hotelId,
      productId: stockBefore.product.id,
      fullBottlesDelta: -1,
      reason: 'Retry-safe stock count',
      clientRequestId: 'retry-stock-1',
    );
    await repository.recordStockAdjustment(
      hotelId: stockBefore.hotelId,
      productId: stockBefore.product.id,
      fullBottlesDelta: -1,
      reason: 'Retry-safe stock count',
      clientRequestId: 'retry-stock-1',
    );
    await repository.submitChangeRequest(
      hotelId: before.hotelId,
      title: 'Retry-safe room edit',
      targetTable: 'rooms',
      targetId: before.roomId,
      oldData: {'room_number': before.roomNumber},
      newData: {'room_number': '999'},
      clientRequestId: 'retry-approval-1',
    );
    await repository.submitChangeRequest(
      hotelId: before.hotelId,
      title: 'Retry-safe room edit',
      targetTable: 'rooms',
      targetId: before.roomId,
      oldData: {'room_number': before.roomNumber},
      newData: {'room_number': '999'},
      clientRequestId: 'retry-approval-1',
    );
    final refillEvent = (await repository.recentRefillEvents())
        .firstWhere((event) => event.type == RefillEventType.refill);
    await repository.requestCorrection(
      refillEventId: refillEvent.id,
      reason: 'Retry-safe correction',
      clientRequestId: 'retry-correction-1',
    );
    await repository.requestCorrection(
      refillEventId: refillEvent.id,
      reason: 'Retry-safe correction',
      clientRequestId: 'retry-correction-1',
    );

    final after = (await repository.roomProducts())
        .firstWhere((item) => item.id == before.id);
    final stockAfter = (await repository.inventory())
        .firstWhere((item) => item.product.id == before.product.id);
    final events = await repository.recentRefillEvents();
    final approvals = await repository.approvalRequests();

    expect(after.refillCount, before.refillCount + 1);
    expect(stockAfter.fullBottles, stockBefore.fullBottles - 1);
    expect(events.where((event) => event.type == RefillEventType.refill),
        hasLength(1));
    expect(approvals.length, approvalCount + 2);
  });

  test('undoRefill restores previous count within window', () async {
    final repository = MockIvraRepository();
    final before = (await repository.roomProducts()).first;

    await repository.recordRefill(roomProductId: before.id);
    final event = (await repository.recentRefillEvents()).first;
    await repository.undoRefill(refillEventId: event.id);

    final after = (await repository.roomProducts()).first;
    expect(after.refillCount, before.refillCount);
  });

  test('client request ids make undo refill idempotent', () async {
    final repository = MockIvraRepository();
    final before = (await repository.roomProducts()).first;

    await repository.recordRefill(roomProductId: before.id);
    final event = (await repository.recentRefillEvents()).first;
    await repository.undoRefill(
      refillEventId: event.id,
      clientRequestId: 'retry-undo-1',
    );
    await repository.undoRefill(
      refillEventId: event.id,
      clientRequestId: 'retry-undo-1',
    );

    final after = (await repository.roomProducts())
        .firstWhere((item) => item.id == before.id);
    final undoEvents = (await repository.recentRefillEvents())
        .where((item) => item.type == RefillEventType.undo);

    expect(after.refillCount, before.refillCount);
    expect(undoEvents, hasLength(1));
  });

  test('replaceBottle resets lifecycle and updates stock', () async {
    final repository = MockIvraRepository();
    final before = (await repository.roomProducts()).first;
    final stockBefore = (await repository.inventory())
        .firstWhere((item) => item.product.id == before.product.id);

    await repository.replaceBottle(
      roomProductId: before.id,
      notes: 'Bottle reached replacement limit',
    );

    final after = (await repository.roomProducts())
        .firstWhere((item) => item.id == before.id);
    final stockAfter = (await repository.inventory())
        .firstWhere((item) => item.product.id == before.product.id);
    final event = (await repository.recentRefillEvents()).first;

    expect(after.refillCount, 0);
    expect(after.status, BottleStatus.active);
    expect(after.bottleStartedAt.isAfter(before.bottleStartedAt), true);
    expect(stockAfter.fullBottles, stockBefore.fullBottles - 1);
    expect(stockAfter.emptyBottles, stockBefore.emptyBottles + 1);
    expect(event.type, RefillEventType.bottleReplaced);
    expect(event.previousRefillCount, before.refillCount);
    expect(event.newRefillCount, 0);
  });

  test('create hotel and room template update demo operations data', () async {
    final repository = MockIvraRepository();
    final hotelCount = (await repository.hotels()).length;
    final products = await repository.products();

    await repository.createHotel(
      name: 'City Suites',
      legalName: 'City Suites Limited',
      city: 'Lagos',
      country: 'Nigeria',
      contactName: 'Operations Lead',
      email: 'ops@city.example',
      phone: '+234 800 222 3333',
      address: '22 Marina Road',
      notes: 'New pilot account',
    );

    final hotels = await repository.hotels();
    expect(hotels.length, hotelCount + 1);
    expect(hotels.last.legalName, 'City Suites Limited');
    expect(hotels.last.address, '22 Marina Road');
    expect(hotels.last.notes, 'New pilot account');

    await repository.createRoomsFromTemplate(
      hotelId: hotels.last.id,
      floorNumber: 4,
      firstRoomNumber: 401,
      roomCount: 3,
      productIds: products.take(3).map((product) => product.id).toList(),
      autoAdjustInventory: true,
    );

    final rooms = await repository.rooms(hotelId: hotels.last.id);
    final roomProducts = await repository.roomProducts(hotelId: hotels.last.id);

    expect(rooms.length, 3);
    expect(roomProducts.length, 9);
  });

  test('room edit request creates a pending approval', () async {
    final repository = MockIvraRepository();
    final roomProduct = (await repository.roomProducts()).first;

    await repository.submitChangeRequest(
      hotelId: roomProduct.hotelId,
      title: 'Update room ${roomProduct.roomNumber}',
      targetTable: 'rooms',
      targetId: roomProduct.roomId,
      oldData: {
        'room_number': roomProduct.roomNumber,
        'floor_number': roomProduct.floorNumber,
      },
      newData: {
        'room_number': '301',
        'floor_number': 3,
      },
    );

    final request = (await repository.approvalRequests()).first;
    expect(request.targetTable, 'rooms');
    expect(request.newValue, contains('room_number: 301'));
    expect(request.newValue, contains('floor_number: 3'));
  });

  test('approved hotel and room edits update demo data', () async {
    final repository = MockIvraRepository();
    final hotel = (await repository.hotels()).first;
    final roomProduct = (await repository.roomProducts()).first;

    await repository.submitChangeRequest(
      hotelId: hotel.id,
      title: 'Update hotel information for ${hotel.name}',
      targetTable: 'hotels',
      targetId: hotel.id,
      oldData: {
        'name': hotel.name,
        'legal_name': hotel.legalName,
        'address': hotel.address,
      },
      newData: {
        'name': 'Updated Seaside Hotel',
        'legal_name': 'Updated Seaside Hotel Ltd',
        'address': '99 Updated Street',
      },
    );

    final hotelRequest = (await repository.approvalRequests()).first;
    await repository.approveRequest(approvalRequestId: hotelRequest.id);

    final updatedHotel =
        (await repository.hotels()).firstWhere((item) => item.id == hotel.id);
    expect(updatedHotel.name, 'Updated Seaside Hotel');
    expect(updatedHotel.legalName, 'Updated Seaside Hotel Ltd');
    expect(updatedHotel.address, '99 Updated Street');

    await repository.submitChangeRequest(
      hotelId: roomProduct.hotelId,
      title: 'Update room ${roomProduct.roomNumber}',
      targetTable: 'rooms',
      targetId: roomProduct.roomId,
      oldData: {
        'room_number': roomProduct.roomNumber,
        'floor_number': roomProduct.floorNumber,
      },
      newData: {
        'room_number': '777',
        'floor_number': 7,
      },
    );

    final roomRequest = (await repository.approvalRequests()).first;
    await repository.approveRequest(approvalRequestId: roomRequest.id);

    final updatedRoomProduct = (await repository.roomProducts())
        .firstWhere((item) => item.id == roomProduct.id);
    expect(updatedRoomProduct.roomNumber, '777');
    expect(updatedRoomProduct.floorNumber, 7);
  });

  test('room product lifecycle edit creates a pending approval', () async {
    final repository = MockIvraRepository();
    final roomProduct = (await repository.roomProducts()).first;

    await repository.submitChangeRequest(
      hotelId: roomProduct.hotelId,
      title:
          'Update ${roomProduct.product.nameEn} bottle in room ${roomProduct.roomNumber}',
      targetTable: 'room_products',
      targetId: roomProduct.id,
      oldData: {
        'status': roomProduct.status.value,
        'bottle_started_at':
            roomProduct.bottleStartedAt.toIso8601String().substring(0, 10),
      },
      newData: {
        'status': BottleStatus.damaged.value,
        'bottle_started_at': '2026-05-23',
      },
    );

    final request = (await repository.approvalRequests()).first;
    expect(request.targetTable, 'room_products');
    expect(request.newValue, contains('status: damaged'));
    expect(request.newValue, contains('bottle_started_at: 2026-05-23'));
  });

  test('stock adjustment changes inventory counts', () async {
    final repository = MockIvraRepository();
    final before = (await repository.inventory()).first;

    await repository.recordStockAdjustment(
      hotelId: before.hotelId,
      productId: before.product.id,
      fullBottlesDelta: 5,
      fullBidonsDelta: 2,
      reason: 'Delivery received',
    );

    final after = (await repository.inventory()).first;
    expect(after.fullBottles, before.fullBottles + 5);
    expect(after.fullBidons, before.fullBidons + 2);
  });

  test('correction request creates pending approval', () async {
    final repository = MockIvraRepository();
    final roomProduct = (await repository.roomProducts()).first;

    await repository.recordRefill(roomProductId: roomProduct.id);
    final event = (await repository.recentRefillEvents()).first;
    await repository.requestCorrection(
      refillEventId: event.id,
      reason: 'Marked the wrong bottle as refilled',
    );

    final approvals = await repository.approvalRequests();
    expect(
      approvals.first.title,
      contains('Correction request'),
    );
  });

  test('invite team member creates pending invitation', () async {
    final repository = MockIvraRepository();
    final before = await repository.teamInvitations();

    await repository.inviteTeamMember(
      email: 'new.staff@seaside.example',
      fullName: 'New Staff Member',
      role: 'hotel_staff',
      hotelId: 'hotel-seaside',
    );

    final after = await repository.teamInvitations();
    expect(after.length, before.length + 1);
    expect(after.first.email, 'new.staff@seaside.example');
  });

  test('team invitations can be resent, cancelled, and members deactivated',
      () async {
    final repository = MockIvraRepository();
    final invitation = (await repository.teamInvitations()).first;
    final member = (await repository.teamMembers())
        .firstWhere((profile) => profile.id == 'hotel-staff-seaside');

    await repository.resendTeamInvitation(invitationId: invitation.id);
    final resent = (await repository.teamInvitations())
        .firstWhere((item) => item.id == invitation.id);
    expect(resent.createdAt.isAfter(invitation.createdAt), true);

    await repository.cancelTeamInvitation(invitationId: invitation.id);
    expect(
      (await repository.teamInvitations())
          .where((item) => item.id == invitation.id),
      isEmpty,
    );

    await repository.setTeamMemberActive(
      userId: member.id,
      isActive: false,
    );
    final inactive = (await repository.teamMembers())
        .firstWhere((profile) => profile.id == member.id);
    expect(inactive.isActive, false);

    await repository.setTeamMemberActive(
      userId: member.id,
      isActive: true,
    );
    final active = (await repository.teamMembers())
        .firstWhere((profile) => profile.id == member.id);
    expect(active.isActive, true);
  });

  test('team invitation can be loaded and accepted by token', () async {
    final repository = MockIvraRepository();
    await repository.inviteTeamMember(
      email: 'token.user@seaside.example',
      fullName: 'Token User',
      role: 'hotel_staff',
      hotelId: 'hotel-seaside',
    );

    final invitation = (await repository.teamInvitations()).firstWhere(
      (item) => item.email == 'token.user@seaside.example',
    );
    final token = invitation.inviteToken!;

    final loaded = await repository.invitationByToken(token: token);
    expect(loaded?.email, invitation.email);

    await repository.acceptTeamInvitation(token: token);

    expect(await repository.invitationByToken(token: token), isNull);
    expect(
      (await repository.teamMembers())
          .any((member) => member.email == invitation.email),
      true,
    );
  });

  test('product catalog can create and update rules', () async {
    final repository = MockIvraRepository();
    final before = await repository.products();

    await repository.createProduct(
      sku: 'IVR-TST-1L',
      nameEn: 'Test Wash',
      nameFr: 'Savon test',
      nameAr: 'منتج اختبار',
      bottleVolumeMl: 1000,
      bidonVolumeMl: 5000,
      maxRefillCount: 8,
      maxBottleAgeDays: 180,
      lowBottleThreshold: 10,
      lowBidonThreshold: 3,
    );

    final created = (await repository.products()).last;
    expect((await repository.products()).length, before.length + 1);
    expect(created.maxRefillCount, 8);

    await repository.updateProduct(
      productId: created.id,
      sku: created.sku,
      nameEn: 'Updated Test Wash',
      nameFr: created.nameFr,
      nameAr: created.nameAr,
      bottleVolumeMl: 750,
      bidonVolumeMl: 5000,
      maxRefillCount: 9,
      maxBottleAgeDays: 210,
      lowBottleThreshold: 11,
      lowBidonThreshold: 4,
    );

    final updated = (await repository.products()).last;
    expect(updated.nameEn, 'Updated Test Wash');
    expect(updated.bottleVolumeMl, 750);
    expect(updated.maxRefillCount, 9);
  });

  test('direct replacement product can be created and updated with custom maxBottleAgeDays', () async {
    final repository = MockIvraRepository();
    final before = await repository.products();

    await repository.createProduct(
      sku: 'IVR-REP-1L',
      nameEn: 'Direct Replace Wash',
      nameFr: 'Savon direct',
      nameAr: 'منتج استبدال مباشر',
      bottleVolumeMl: 1000,
      bidonVolumeMl: 0,
      maxRefillCount: 0,
      maxBottleAgeDays: 120,
      lowBottleThreshold: 5,
      lowBidonThreshold: 0,
      refillType: RefillType.directReplacement,
    );

    final created = (await repository.products()).last;
    expect((await repository.products()).length, before.length + 1);
    expect(created.refillType, RefillType.directReplacement);
    expect(created.maxBottleAgeDays, 120);

    await repository.updateProduct(
      productId: created.id,
      sku: created.sku,
      nameEn: 'Updated Direct Replace Wash',
      nameFr: created.nameFr,
      nameAr: created.nameAr,
      bottleVolumeMl: 1000,
      bidonVolumeMl: 0,
      maxRefillCount: 0,
      maxBottleAgeDays: 90,
      lowBottleThreshold: 5,
      lowBidonThreshold: 0,
      refillType: RefillType.directReplacement,
    );

    final updated = (await repository.products()).last;
    expect(updated.nameEn, 'Updated Direct Replace Wash');
    expect(updated.maxBottleAgeDays, 90);
  });

  test('direct replacement products do not generate refill limit alerts', () async {
    final repository = MockIvraRepository();

    // 1. Create a direct replacement product
    await repository.createProduct(
      sku: 'IVR-REP-XYZ',
      nameEn: 'Direct Replace Body Wash',
      nameFr: 'Savon direct XYZ',
      nameAr: 'استبدال مباشر',
      bottleVolumeMl: 1000,
      bidonVolumeMl: 0,
      maxRefillCount: 0,
      maxBottleAgeDays: 120,
      lowBottleThreshold: 5,
      lowBidonThreshold: 0,
      refillType: RefillType.directReplacement,
    );

    final products = await repository.products();
    final repProduct = products.last;

    // 2. Put this product in a room
    final rooms = await repository.rooms();
    final firstRoom = rooms.first;
    final hotelId = firstRoom.hotelId;
    
    // Now template/place rooms (with autoAdjustInventory: true to initialize inventory item)
    await repository.createRoomsFromTemplate(
      hotelId: hotelId,
      floorNumber: 5,
      firstRoomNumber: 501,
      roomCount: 1,
      productIds: [repProduct.id],
      autoAdjustInventory: true,
    );

    // Adjust stock to have 10 bottles of this new product (now that the item exists in inventory)
    await repository.recordStockAdjustment(
      hotelId: hotelId,
      productId: repProduct.id,
      fullBottlesDelta: 9, // we already have 1 from the room creation
      emptyBottlesDelta: 0,
      fullBidonsDelta: 0,
      openBidonsDelta: 0,
      emptyBidonsDelta: 0,
      reason: 'test stock',
    );

    // 3. Clear all existing alerts for this hotel to test cleanly
    final alertsBefore = await repository.alerts(hotelId: hotelId);
    for (final alert in alertsBefore) {
      await repository.resolveAlert(alertId: alert.id);
    }

    // 4. Trigger alert generation
    await repository.refreshSmartAlerts(hotelId: hotelId);

    // 5. Verify no alerts of type refillLimit are generated for this hotel/product
    final alertsAfter = await repository.alerts(hotelId: hotelId);
    final refillLimitAlerts = alertsAfter.where((a) => !a.isResolved && a.type == AlertType.refillLimit && a.productId == repProduct.id).toList();
    expect(refillLimitAlerts.isEmpty, true);
  });



  test('offline queue syncs refill actions', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final before = (await repository.roomProducts()).first;

    await service.enqueue(
      type: SyncActionType.refill,
      payload: {'roomProductId': before.id},
    );

    expect((await service.pendingActions()).length, 1);

    final synced = await service.syncPending(repository);
    final after = (await repository.roomProducts()).first;

    expect(synced, 1);
    expect((await service.pendingActions()), isEmpty);
    expect(after.refillCount, before.refillCount + 1);
  });

  test('offline queue syncs bottle replacement actions', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final before = (await repository.roomProducts()).first;

    await service.enqueue(
      type: SyncActionType.bottleReplacement,
      payload: {'roomProductId': before.id},
    );

    expect(await service.syncPending(repository), 1);

    final after = (await repository.roomProducts())
        .firstWhere((item) => item.id == before.id);
    final event = (await repository.recentRefillEvents()).first;

    expect(await service.pendingActions(), isEmpty);
    expect(after.refillCount, 0);
    expect(event.type, RefillEventType.bottleReplaced);
  });

  test('offline queue syncs pending edit requests', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final roomProduct = (await repository.roomProducts()).first;
    final approvalCount = (await repository.approvalRequests()).length;

    await service.enqueue(
      type: SyncActionType.pendingEdit,
      payload: {
        'hotelId': roomProduct.hotelId,
        'title': 'Update room ${roomProduct.roomNumber}',
        'targetTable': 'rooms',
        'targetId': roomProduct.roomId,
        'oldData': {
          'room_number': roomProduct.roomNumber,
          'floor_number': roomProduct.floorNumber,
        },
        'newData': {
          'room_number': '990',
          'floor_number': 9,
        },
      },
    );

    expect(await service.syncPending(repository), 1);

    final approvals = await repository.approvalRequests();
    expect(await service.pendingActions(), isEmpty);
    expect(approvals.length, approvalCount + 1);
    expect(approvals.first.targetTable, 'rooms');
    expect(approvals.first.newValue, contains('room_number: 990'));
  });

  test('offline queue keeps failed actions and continues syncing', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final roomProduct = (await repository.roomProducts()).first;
    final before = roomProduct.refillCount;

    await service.enqueue(
      type: SyncActionType.undoRefill,
      payload: {'refillEventId': 'missing-event'},
    );
    await service.enqueue(
      type: SyncActionType.refill,
      payload: {'roomProductId': roomProduct.id},
    );

    final summary = await service.syncPendingDetailed(repository);
    final pending = await service.pendingActions();
    final after = (await repository.roomProducts())
        .firstWhere((item) => item.id == roomProduct.id);

    expect(summary.synced, 1);
    expect(summary.failed, 1);
    expect(after.refillCount, before + 1);
    expect(pending.length, 1);
    expect(pending.single.lastError, isNotNull);
    expect(pending.single.attemptCount, 1);

    await service.remove(pending.single.id);
    expect(await service.pendingActions(), isEmpty);
  });

  test('offline queue payload can be edited after a failed sync', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MockIvraRepository();
    final service = OfflineSyncService();
    final roomProduct = (await repository.roomProducts()).first;
    final before = roomProduct.refillCount;

    await service.enqueue(
      type: SyncActionType.refill,
      payload: {'roomProductId': 'missing-room-product'},
    );

    expect(await service.syncPending(repository), 0);
    final failed = (await service.pendingActions()).single;
    expect(failed.lastError, isNotNull);

    await service.updatePayload(
      failed.id,
      {'roomProductId': roomProduct.id, 'notes': 'Resolved conflict'},
    );
    final resolved = (await service.pendingActions()).single;
    expect(resolved.lastError, isNull);
    expect(resolved.payload['roomProductId'], roomProduct.id);

    expect(await service.syncPending(repository), 1);
    final after = (await repository.roomProducts())
        .firstWhere((item) => item.id == roomProduct.id);

    expect(await service.pendingActions(), isEmpty);
    expect(after.refillCount, before + 1);
  });

  test('smart alerts refresh without duplicates and can be resolved', () async {
    final repository = MockIvraRepository();

    final created =
        await repository.refreshSmartAlerts(hotelId: 'hotel-seaside');
    final duplicateCreated =
        await repository.refreshSmartAlerts(hotelId: 'hotel-seaside');
    final alerts = await repository.alerts(hotelId: 'hotel-seaside');
    final openAlert = alerts.firstWhere((alert) => !alert.isResolved);

    expect(created, greaterThan(0));
    expect(duplicateCreated, 0);
    expect(alerts.any((alert) => alert.type == AlertType.bottleAgeLimit), true);

    await repository.resolveAlert(alertId: openAlert.id);

    final resolved = (await repository.alerts(hotelId: 'hotel-seaside'))
        .firstWhere((alert) => alert.id == openAlert.id);
    expect(resolved.isResolved, true);
  });

  test('report export service creates csv and pdf payloads', () async {
    final repository = MockIvraRepository();
    final service = ReportExportService();
    final roomProduct = (await repository.roomProducts()).first;

    await repository.recordRefill(roomProductId: roomProduct.id);
    await repository.refreshSmartAlerts(hotelId: 'hotel-seaside');

    final refillCsv =
        service.refillHistoryCsv(await repository.recentRefillEvents());
    final orderCsv =
        service.suggestedOrdersCsv(await repository.suggestedOrders());
    final inventoryCsv = service.inventoryCsv(await repository.inventory());
    final alertCsv = service.alertsCsv(await repository.alerts());
    final refillPdf = await service.refillHistoryPdf(
      await repository.recentRefillEvents(),
      languageCode: 'fr',
    );
    final orderPdf =
        await service.suggestedOrdersPdf(await repository.suggestedOrders());
    final frenchOrderPdf = await service.suggestedOrdersPdf(
      await repository.suggestedOrders(),
      languageCode: 'fr',
    );
    final arabicOrderPdf = await service.suggestedOrdersPdf(
      await repository.suggestedOrders(),
      languageCode: 'ar',
    );
    final inventoryPdf = await service.inventoryPdf(
      await repository.inventory(),
      languageCode: 'fr',
    );
    final alertsPdf = await service.alertsPdf(
      await repository.alerts(),
      languageCode: 'ar',
    );

    expect(refillCsv, contains('event_id'));
    expect(refillCsv, contains(roomProduct.id));
    expect(orderCsv, contains('bottles_to_order'));
    expect(inventoryCsv, contains('full_bottles'));
    expect(alertCsv, contains('alert_id'));
    expect(refillPdf.length, greaterThan(100));
    expect(orderPdf.length, greaterThan(100));
    expect(frenchOrderPdf.length, greaterThan(100));
    expect(arabicOrderPdf.length, greaterThan(100));
    expect(inventoryPdf.length, greaterThan(100));
    expect(alertsPdf.length, greaterThan(100));
  });

  test('percentage-based refill and undo restore volumes on MockIvraRepository', () async {
    final repository = MockIvraRepository();
    
    // Find the in-memory inventory for shampoo
    final initialInvList = await repository.inventory(hotelId: 'hotel-seaside');
    final beforeShampoo = initialInvList.firstWhere((item) => item.product.id == 'prod-shampoo');
    
    // Check initial values
    expect(beforeShampoo.openBidonVolumeLeftMl, 2500.0);
    expect(beforeShampoo.fullBidons, 3);
    expect(beforeShampoo.openBidons, 1);
    expect(beforeShampoo.emptyBidons, 5);

    // Record a 50% refill
    // rp-101-shampoo is 'prod-shampoo' (bottle volume 1000ml)
    // 50% refill = 500ml added, which should deduct 500ml from the open bidon (leaving 2000.0ml left)
    await repository.recordRefill(
      roomProductId: 'rp-101-shampoo',
      notes: '[Refill: 50%]',
    );

    final afterRefill1 = (await repository.inventory(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.product.id == 'prod-shampoo');
    expect(afterRefill1.openBidonVolumeLeftMl, 2000.0);
    expect(afterRefill1.fullBidons, 3);
    expect(afterRefill1.openBidons, 1);
    expect(afterRefill1.emptyBidons, 5);

    // Record three 100% refills to trigger bidon replacement
    await repository.recordRefill(roomProductId: 'rp-101-shampoo', notes: '[Refill: 100%]'); // leaves 1000ml
    await repository.recordRefill(roomProductId: 'rp-101-shampoo', notes: '[Refill: 100%]'); // leaves 0ml, triggers new bidon, starts at 5000ml
    await repository.recordRefill(roomProductId: 'rp-101-shampoo', notes: '[Refill: 100%]'); // leaves 4000ml

    final afterRefill2 = (await repository.inventory(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.product.id == 'prod-shampoo');
    expect(afterRefill2.openBidonVolumeLeftMl, 4000.0);
    expect(afterRefill2.fullBidons, 2);
    expect(afterRefill2.openBidons, 1);
    expect(afterRefill2.emptyBidons, 6);

    // Undo the last refill
    final recentEvents = await repository.recentRefillEvents();
    final lastRefillEvent = recentEvents.firstWhere((event) => event.roomProductId == 'rp-101-shampoo' && event.type == RefillEventType.refill);
    
    await repository.undoRefill(refillEventId: lastRefillEvent.id);

    final afterUndo = (await repository.inventory(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.product.id == 'prod-shampoo');
    expect(afterUndo.openBidonVolumeLeftMl, 5000.0);
    expect(afterUndo.fullBidons, 2);
    expect(afterUndo.openBidons, 1);
    expect(afterUndo.emptyBidons, 6);

    // Undo the refill before that (which caused a new bidon to open)
    final updatedEvents = await repository.recentRefillEvents();
    final prevRefillEvent = updatedEvents.firstWhere((event) => event.roomProductId == 'rp-101-shampoo' && event.type == RefillEventType.refill);

    await repository.undoRefill(refillEventId: prevRefillEvent.id);

    final afterBoundaryUndo = (await repository.inventory(hotelId: 'hotel-seaside'))
        .firstWhere((item) => item.product.id == 'prod-shampoo');
    expect(afterBoundaryUndo.openBidonVolumeLeftMl, 1000.0);
    expect(afterBoundaryUndo.fullBidons, 3);
    expect(afterBoundaryUndo.openBidons, 1);
    expect(afterBoundaryUndo.emptyBidons, 5);
  });
}
