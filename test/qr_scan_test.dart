import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ivra_refill/src/app/ivra_app.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/features/shared/premium_qr_scanner_dialog.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('QR Code Scanning Tests', () {
    testWidgets('Clicking room QR button and scanning room code filters list', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelManager),
      );

      // Navigate to Rooms Screen
      final context = tester.element(find.text('Dashboard').first);
      GoRouter.of(context).go(RoomsScreen.route);
      await tester.pumpAndSettle();

      // Find the first QR scan button (room search QR button)
      final roomQrScanFinder = find.byTooltip('Scan QR Code').first;
      expect(roomQrScanFinder, findsOneWidget);

      // Tap room QR scan button
      await tester.tap(roomQrScanFinder);
      // Pump multiple frames to allow the dialog entry animation to complete
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // PremiumQrScannerDialog should be shown
      expect(find.byType(PremiumQrScannerDialog), findsOneWidget);

      // Find room 205 demo chip and tap it
      final room205Chip = find.descendant(
        of: find.byType(PremiumQrScannerDialog),
        matching: find.text('205'),
      );
      expect(room205Chip, findsOneWidget);
      await tester.tap(room205Chip, warnIfMissed: false);
      
      // Since tapping pops the dialog, the infinite animation is removed from the tree.
      // Now we can safely call pumpAndSettle.
      await tester.pumpAndSettle();

      // The dialog should close, and the room list should filter to room 205
      expect(find.byType(PremiumQrScannerDialog), findsNothing);
      expect(find.text('Room 205'), findsOneWidget);
      expect(find.text('Room 101'), findsNothing);
    });

    testWidgets('Clicking card-level QR button and scanning product SKU shows choice dialog', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelManager),
      );

      // Navigate to Rooms Screen
      final context = tester.element(find.text('Dashboard').first);
      GoRouter.of(context).go(RoomsScreen.route);
      await tester.pumpAndSettle();

      // Find the card-level QR scan button (tooltip 'Scan QR Code')
      // The first two 'Scan QR Code' tooltips are for room and product search fields.
      // Subsequent ones are room cards. Let's tap the third one (index 2).
      final scanButtons = find.byTooltip('Scan QR Code');
      expect(scanButtons, findsAtLeastNWidgets(3));
      
      // Tap card scan button (index 2)
      await tester.tap(scanButtons.at(2));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Dialog should be open
      expect(find.byType(PremiumQrScannerDialog), findsOneWidget);

      // Find the product SKU chip. In the dialog, the chip label is "PRODUCT:IVR-SHA-1L"
      final productChip = find.text('PRODUCT:IVR-SHA-1L');
      expect(productChip, findsOneWidget);
      await tester.tap(productChip, warnIfMissed: false);
      
      // Dialog pops, so safe to pumpAndSettle
      await tester.pumpAndSettle();

      // Viewfinder dialog should close, and action selection prompt should show up
      expect(find.byType(PremiumQrScannerDialog), findsNothing);
      expect(find.text('Select Action'), findsOneWidget);
      expect(find.text('Refill Bottle'), findsOneWidget);
      expect(find.text('Replace Bottle'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Clicking inventory QR button and scanning product SKU shows adjust stock dialog', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelManager),
      );

      // Navigate to Inventory Screen
      final context = tester.element(find.text('Dashboard').first);
      GoRouter.of(context).go(InventoryScreen.route);
      await tester.pumpAndSettle();

      // Find QR scan button next to inventory search bar
      final inventoryScanButton = find.byTooltip('Scan QR Code').first;
      expect(inventoryScanButton, findsOneWidget);

      // Tap inventory QR scan button
      await tester.tap(inventoryScanButton);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Viewfinder dialog should be open
      expect(find.byType(PremiumQrScannerDialog), findsOneWidget);

      // Find the product SKU chip. In the dialog, the chip label is "PRODUCT:IVR-SHA-1L"
      final productChip = find.text('PRODUCT:IVR-SHA-1L');
      expect(productChip, findsOneWidget);
      await tester.tap(productChip, warnIfMissed: false);
      
      // Dialog pops, safe to pumpAndSettle
      await tester.pumpAndSettle();

      // Viewfinder dialog should close, and stock adjustment dialog should display
      expect(find.byType(PremiumQrScannerDialog), findsNothing);
      expect(find.text('Adjust stock'), findsNWidgets(2));

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigating to /rooms?scan=true auto-starts the QR scanner dialog and clears the URL param on dismiss', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelManager),
      );

      // Navigate directly with deep link query parameter
      final context = tester.element(find.text('Dashboard').first);
      GoRouter.of(context).go('/rooms?scan=true');
      await tester.pump(); // Start navigation/build
      
      // Let the page load, run postFrameCallbacks, and show dialog
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Scanner dialog should be automatically open
      expect(find.byType(PremiumQrScannerDialog), findsOneWidget);

      // Find room 205 demo chip and tap it
      final room205Chip = find.descendant(
        of: find.byType(PremiumQrScannerDialog),
        matching: find.text('205'),
      );
      expect(room205Chip, findsOneWidget);
      await tester.tap(room205Chip, warnIfMissed: false);

      // Pump to settle transitions and verify URL clean up
      await tester.pumpAndSettle();

      // Scanner should be closed
      expect(find.byType(PremiumQrScannerDialog), findsNothing);
      // Results should be filtered to Room 205
      expect(find.text('Room 205'), findsOneWidget);

      // The router URL should be cleaned up to "/rooms" without query parameter
      final roomsContext = tester.element(find.byType(RoomsScreen));
      final currentUri = GoRouter.of(roomsContext).routeInformationProvider.value.uri;
      expect(currentUri.queryParameters['scan'], isNull);
    });
  });
}

UserProfile _userForRole(UserRole role) {
  return UserProfile(
    id: 'test-${role.value}',
    fullName: 'Test ${role.value}',
    email: '${role.value}@ivra.test',
    role: role,
    hotelId: role == UserRole.hotelManager || role == UserRole.hotelStaff
        ? 'hotel-seaside'
        : null,
  );
}

Future<void> _pumpIvraApp(
  WidgetTester tester, {
  Size size = const Size(1024, 768),
  Locale? locale,
  UserProfile? currentUser,
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
