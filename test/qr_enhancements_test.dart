import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ivra_refill/src/app/ivra_app.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/features/rooms/qr_action_screen.dart';
import 'package:ivra_refill/src/services/qr_code_pdf_service.dart';
import 'package:ivra_refill/src/services/notification_service.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('QrCodePdfService Tests', () {
    test('generateQrPdf generates a non-empty list of PDF bytes', () async {
      WidgetsFlutterBinding.ensureInitialized();
      final pdfService = QrCodePdfService();
      final labels = [
        const QrCodeLabelData(
          hotelName: 'Seaside Resort',
          floor: '1',
          room: '101',
          productName: 'Shampoo',
          productSku: 'SHA-1L',
          url: 'https://refill.ivra-cosmetics.com/q/hotel-seaside/1/101/IVR-SHA-1L',
        ),
      ];

      final pdfBytes = await pdfService.generateQrPdf(
        labels: labels,
        languageCode: 'en',
      );

      expect(pdfBytes, isNotEmpty);
    });
  });

  group('QR Screen Actions & Generator Widget Tests', () {
    testWidgets('Toggles between Scan and Generate tabs and shows configuration form', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      // Navigate to /qr
      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/qr');
      await tester.pumpAndSettle();

      // Verify we are initially in Scan mode and the scanner viewfinder is present
      expect(find.descendant(of: find.byType(QrActionScreen), matching: find.text('Scan QR Code')), findsAtLeastNWidgets(1));
      // Verify Segmented Tab buttons exist by searching within the SegmentedButton
      final segmentedButtonFinder = find.byWidgetPredicate((widget) => widget is SegmentedButton);
      expect(segmentedButtonFinder, findsOneWidget);

      final scanTabButton = find.descendant(of: segmentedButtonFinder, matching: find.text('Scan QR Code'));
      final generateTabButton = find.descendant(of: segmentedButtonFinder, matching: find.text('Generate QR Codes'));

      expect(scanTabButton, findsOneWidget);
      expect(generateTabButton, findsOneWidget);

      // Tap on the Generate tab button
      await tester.tap(generateTabButton);
      await tester.pumpAndSettle();

      // Verify that the view switched to the Generator form and scanner titles updated
      expect(find.text('Generate QR Codes'), findsNWidgets(2));
      expect(find.text('QR Label Type'), findsOneWidget);
      expect(find.text('Room Door (No SKU)'), findsOneWidget);
      expect(find.text('Dispenser (With SKU)'), findsOneWidget);
      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Product'), findsOneWidget);
      expect(find.text('Generate & Download PDF'), findsOneWidget);
    });

    testWidgets('Refilled status display appends last refill date/time correctly', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      // Navigate to /q/hotel-seaside/1/101/IVR-SHA-1L
      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-SHA-1L');
      await tester.pumpAndSettle();

      // Verify page loaded details for the dispenser
      expect(find.text('Dispenser Status'), findsOneWidget);

      // Verify the formatted status with refill date is rendered
      expect(find.textContaining('Refilled ('), findsOneWidget);
    });

    testWidgets('Lost and Damaged status disables respective buttons', (tester) async {
      final damagedProduct = RoomProduct(
        id: 'rp-101-wash',
        hotelId: 'hotel-seaside',
        roomId: 'room-101',
        roomNumber: '101',
        floorNumber: 1,
        product: const Product(
          id: 'prod-hand-wash',
          sku: 'IVR-HWA-1L',
          nameEn: 'Hand Wash',
          nameFr: 'Savon mains',
          nameAr: 'غسول اليدين',
          nameIt: 'Sapone Mani',
          maxRefillCount: 10,
          maxBottleAgeDays: 240,
          lowBottleThreshold: 12,
          lowBidonThreshold: 4,
        ),
        refillCount: 3,
        lastRefillAt: DateTime.now().subtract(const Duration(hours: 4)),
        bottleStartedAt: DateTime.now().subtract(const Duration(days: 60)),
        status: BottleStatus.damaged,
      );

      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
        allRoomProductsOverride: [damagedProduct],
      );

      // Navigate to Room 101 / Floor 1 / SKU: IVR-HWA-1L (which has status = damaged)
      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-HWA-1L');
      await tester.pumpAndSettle();

      expect(find.text('Dispenser Status'), findsOneWidget);
      expect(find.textContaining('Damaged'), findsAtLeastNWidgets(1));

      // Find the Damaged and Lost action buttons
      final damagedButton = find.widgetWithText(OutlinedButton, 'Damaged');
      final lostButton = find.widgetWithText(OutlinedButton, 'Lost');

      expect(damagedButton, findsOneWidget);
      expect(lostButton, findsOneWidget);

      // Verify both buttons are disabled (onPressed is null)
      final OutlinedButton damagedBtnWidget = tester.widget<OutlinedButton>(damagedButton);
      final OutlinedButton lostBtnWidget = tester.widget<OutlinedButton>(lostButton);

      expect(damagedBtnWidget.onPressed, isNull);
      expect(lostBtnWidget.onPressed, isNull);
    });

    testWidgets('Settings page allows toggling precision scan window and tap-to-scan', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));

      // Verify default state is true
      expect(container.read(precisionScanWindowEnabledProvider), isTrue);
      expect(container.read(tapToScanEnabledProvider), isTrue);

      // Navigate to /settings
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      // Find the SwitchListTiles
      final precisionTileFinder = find.widgetWithText(SwitchListTile, 'Precision Scan Window');
      final tapToScanTileFinder = find.widgetWithText(SwitchListTile, 'Tap to Scan');

      expect(precisionTileFinder, findsOneWidget);
      expect(tapToScanTileFinder, findsOneWidget);

      // Verify initial switch values
      final SwitchListTile precisionTile = tester.widget<SwitchListTile>(precisionTileFinder);
      final SwitchListTile tapToScanTile = tester.widget<SwitchListTile>(tapToScanTileFinder);
      expect(precisionTile.value, isTrue);
      expect(tapToScanTile.value, isTrue);

      // Tap precision scan window switch
      await tester.tap(find.descendant(of: precisionTileFinder, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(container.read(precisionScanWindowEnabledProvider), isFalse);

      // Tap tap to scan switch
      await tester.tap(find.descendant(of: tapToScanTileFinder, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(container.read(tapToScanEnabledProvider), isFalse);
    });

    testWidgets('Scan & Assign - In Stock Flow successfully assigns product', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      // Navigate to Room 101 with IVR-GEL-1L (which is not in Room 101, but is in stock = 22)
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-GEL-1L');
      await tester.pumpAndSettle();

      // Verify Scan & Assign screen is shown
      expect(find.text('Assign Product to Room'), findsOneWidget);
      expect(find.textContaining('22 in stock — will deduct 1 and assign to room'), findsOneWidget);

      // Find the Assign button
      final assignButton = find.widgetWithText(FilledButton, 'Assign to Room');
      expect(assignButton, findsOneWidget);

      // Tap the Assign button
      await tester.tap(assignButton);
      await tester.pumpAndSettle();

      // Verify success card is displayed
      expect(find.text('Action Successful'), findsOneWidget);
      expect(find.textContaining('Product IVR-GEL-1L has been assigned to Room 101 (Floor 1).'), findsOneWidget);
    });

    testWidgets('Scan & Assign - Out of Stock Flow: Confirm Add successfully adds and assigns', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      // Navigate to Room 101 with IVR-CON-1L (not in room, out of stock)
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-CON-1L');
      await tester.pumpAndSettle();

      // Verify Scan & Assign screen for out of stock
      expect(find.text('Assign Product to Room'), findsOneWidget);
      expect(find.textContaining('Out of stock — 1 unit will be auto-added to inventory then assigned'), findsOneWidget);

      // Find the "Add to Inventory & Assign" button
      final autoAddButton = find.widgetWithText(FilledButton, 'Add to Inventory & Assign');
      expect(autoAddButton, findsOneWidget);

      // Tap it to show confirmation dialog
      await tester.tap(autoAddButton);
      await tester.pumpAndSettle();

      // Verify AlertDialog is shown
      expect(find.text('Add to Inventory?'), findsOneWidget);
      expect(find.textContaining('Product "Conditioner" is out of stock.'), findsOneWidget);

      // Find the Confirm button in dialog
      final confirmButton = find.widgetWithText(FilledButton, 'Yes, add & assign');
      expect(confirmButton, findsOneWidget);

      // Tap confirm
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify success card
      expect(find.text('Action Successful'), findsOneWidget);
      expect(find.textContaining('Product IVR-CON-1L has been assigned to Room 101 (Floor 1).'), findsOneWidget);
    });

    testWidgets('Scan & Assign - Out of Stock Flow: Cancel does not perform assign', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      // Navigate to Room 101 with IVR-CON-1L (not in room, out of stock)
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-CON-1L');
      await tester.pumpAndSettle();

      final autoAddButton = find.widgetWithText(FilledButton, 'Add to Inventory & Assign');
      await tester.tap(autoAddButton);
      await tester.pumpAndSettle();

      // Find the Cancel button in dialog
      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      expect(cancelButton, findsOneWidget);

      // Tap Cancel
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify dialog is dismissed but we are still on the assign screen and no success card
      expect(find.text('Add to Inventory?'), findsNothing);
      expect(find.text('Assign Product to Room'), findsOneWidget);
      expect(find.text('Action Successful'), findsNothing);
    });
  });
}

UserProfile _userForRole(UserRole role) {
  String id = 'test-${role.value}';
  String fullName = 'Test ${role.value}';
  String email = '${role.value}@ivra.test';
  if (role == UserRole.hotelManager) {
    id = 'hotel-manager-seaside';
    fullName = 'Amina Bello';
    email = 'amina@seaside.example';
  } else if (role == UserRole.hotelStaff) {
    id = 'hotel-staff-seaside';
    fullName = 'Housekeeping Lead';
    email = 'housekeeping@seaside.example';
  } else if (role == UserRole.appManager) {
    id = 'demo-manager';
    fullName = 'Ivra Manager';
    email = 'manager@ivra.example';
  }
  return UserProfile(
    id: id,
    fullName: fullName,
    email: email,
    role: role,
    roleString: role.value,
    hotelId: role == UserRole.hotelManager || role == UserRole.hotelStaff
        ? 'hotel-seaside'
        : null,
  );
}

Future<void> _pumpIvraApp(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  Locale? locale,
  UserProfile? currentUser,
  List<RoomProduct>? allRoomProductsOverride,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => locale ?? const Locale('en')),
        if (currentUser != null)
          currentUserProvider.overrideWith((ref) async => currentUser),
        if (allRoomProductsOverride != null)
          allRoomProductsProvider.overrideWith((ref) async => allRoomProductsOverride),
        notificationServiceProvider.overrideWith(
          (ref) => _FakeNotificationService(null as dynamic, ref),
        ),
      ],
      child: const IvraApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(super.supabase, super.ref);

  @override
  Future<void> initialize() async {
    // No-op for widget tests
  }
}
