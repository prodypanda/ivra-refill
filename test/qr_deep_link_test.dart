import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ivra_refill/src/app/ivra_app.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/features/products/public_product_screen.dart';
import 'package:ivra_refill/src/features/rooms/qr_action_screen.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/features/auth/login_screen.dart';
import 'package:ivra_refill/src/features/shared/offline_banner.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/services/notification_service.dart';
import 'package:ivra_refill/src/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({'express_qr_enabled': true});

  group('QR Deep Linking and Action Overlay Tests', () {
    testWidgets('Guest scans QR link with SKU -> redirects to PublicProductScreen', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: null, // guest
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-SHA-1L');
      await tester.pumpAndSettle();

      // Should be on PublicProductScreen
      expect(find.byType(PublicProductScreen), findsOneWidget);
      expect(find.text('IVR-SHA-1L'), findsOneWidget);
      
      // Since it's a public landing page, refill/replace buttons shouldn't exist
      expect(find.text('Refill bottle'), findsNothing);
      expect(find.text('Replace bottle'), findsNothing);
    });

    testWidgets('Guest scans QR link without SKU -> redirects to LoginScreen', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: null, // guest
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/q/hotel-seaside/1/101');
      await tester.pumpAndSettle();

      // Should be redirected to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Authorized staff scans QR link with SKU -> opens QrActionScreen modal overlay', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-SHA-1L');
      await tester.pumpAndSettle();

      // Should be on QrActionScreen
      expect(find.byType(QrActionScreen), findsOneWidget);
      expect(find.text('IVR-SHA-1L'), findsOneWidget);
      
      // Since they are authorized, action buttons should be visible
      // Mock data: rp-101-shampoo has refillCount=7, maxRefillCount=10, so can still refill
      expect(find.text('Refill bottle'), findsOneWidget);
      expect(find.text('Replace bottle'), findsOneWidget);
    });

    testWidgets('Authorized staff scans QR link without SKU -> redirects to RoomsScreen with filters', (tester) async {
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelManager),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      final router = container.read(routerProvider);
      router.go('/q/hotel-seaside/1/101');

      // Use pump() instead of pumpAndSettle() because the RoomsScreen has a
      // Scrollbar with thumbVisibility that fires an assertion during settle.
      // The redirect itself completes within a few frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the URL was updated to pass hotelId, floorNumber, roomNumber
      final currentUri = router.routeInformationProvider.value.uri;
      expect(currentUri.queryParameters['hotelId'], 'hotel-seaside');
      expect(currentUri.queryParameters['floorNumber'], '1');
      expect(currentUri.queryParameters['roomNumber'], '101');
    });

    testWidgets('Unauthorized staff scans QR link with SKU -> shows permission warning, buttons disabled', (tester) async {
      // User belongs to hotel-beachfront, so they are unauthorized for hotel-seaside!
      await _pumpIvraApp(
        tester,
        currentUser: _userForRole(UserRole.hotelStaff, hotelId: 'hotel-beachfront'),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(IvraApp)));
      container.read(routerProvider).go('/q/hotel-seaside/1/101/IVR-SHA-1L');
      await tester.pumpAndSettle();

      // Should be on QrActionScreen
      expect(find.byType(QrActionScreen), findsOneWidget);
      
      // Security warning banner should be visible (uses l10n key 'errorPermissionDenied')
      expect(find.byIcon(Icons.gpp_bad), findsOneWidget);
      
      // Refill button should be disabled (onPressed == null)
      final refillButton = tester.widget<FilledButton>(find.byKey(const ValueKey('refill_button')));
      expect(refillButton.onPressed, isNull);
    });
  });
}

UserProfile _userForRole(UserRole role, {String hotelId = 'hotel-seaside'}) {
  return UserProfile(
    id: 'test-${role.value}',
    fullName: 'Test ${role.value}',
    email: '${role.value}@ivra.test',
    role: role,
    roleString: role.value,
    hotelId: role == UserRole.hotelManager || role == UserRole.hotelStaff
        ? hotelId
        : null,
  );
}

Future<void> _pumpIvraApp(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  UserProfile? currentUser,
}) async {
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localeProvider.overrideWith((ref) => const Locale('en')),
        if (currentUser != null)
          currentUserProvider.overrideWith((ref) async => currentUser)
        else
          currentUserProvider.overrideWith((ref) => Future.error(StateError('Not logged in'))),
        connectivityProvider.overrideWith(
          (ref) => ConnectivityNotifier(host: null),
        ),
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
