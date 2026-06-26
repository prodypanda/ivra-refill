import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ivra_refill/src/app/ivra_app.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/features/approvals/approvals_screen.dart';
import 'package:ivra_refill/src/features/hotels/hotels_screen.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';
import 'package:ivra_refill/src/features/products/products_screen.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('Ivra app starts in demo mode', (tester) async {
    await _pumpIvraApp(tester);

    expect(find.byType(IvraApp), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('desktop layout uses navigation rail', (tester) async {
    await _pumpIvraApp(tester, size: const Size(1280, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('mobile layout uses bottom navigation shell', (tester) async {
    await _pumpIvraApp(tester, size: const Size(390, 844));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('Arabic locale renders core navigation as RTL', (tester) async {
    await _pumpIvraApp(
      tester,
      size: const Size(1280, 900),
      locale: const Locale('ar'),
    );

    final dashboardFinder = find.text('لوحة القيادة').first;
    expect(dashboardFinder, findsOneWidget);
    expect(
      Directionality.of(tester.element(dashboardFinder)),
      TextDirection.rtl,
    );
  });

  testWidgets('hotel staff navigation hides management routes', (tester) async {
    await _pumpIvraApp(
      tester,
      size: const Size(1280, 900),
      currentUser: _userForRole(UserRole.hotelStaff),
    );

    expect(find.text('Rooms'), findsWidgets);
    expect(find.text('Store Stock'), findsWidgets);
    expect(find.text('Products'), findsNothing);
    expect(find.text('Team'), findsNothing);
    expect(find.text('Reports'), findsNothing);
  });

  testWidgets('hotel staff direct management route redirects', (tester) async {
    await _pumpIvraApp(
      tester,
      size: const Size(1280, 900),
      currentUser: _userForRole(UserRole.hotelStaff),
    );

    GoRouter.of(tester.element(find.text('Dashboard').first))
        .go(ProductsScreen.route);
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsNothing);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('hotel staff room screen hides edit request actions',
      (tester) async {
    await _pumpIvraApp(
      tester,
      size: const Size(1280, 900),
      currentUser: _userForRole(UserRole.hotelStaff),
    );

    GoRouter.of(tester.element(find.text('Dashboard').first))
        .go(RoomsScreen.route);
    await tester.pumpAndSettle();

    // Switch to detailed view and expand floors
    await tester.tap(find.text('Detailed View'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expand all'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Create room template'), findsNothing);
    expect(find.text('Bottle edit'), findsNothing);
    expect(find.text('Room edit'), findsNothing);
    expect(find.text('Refill bottle'), findsWidgets);
  });

  testWidgets('hotel manager cannot create hotels or approve requests',
      (tester) async {
    await _pumpIvraApp(
      tester,
      size: const Size(1280, 900),
      currentUser: _userForRole(UserRole.hotelManager),
    );

    final context = tester.element(find.text('Dashboard').first);
    GoRouter.of(context).go(HotelsScreen.route);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Create hotel'), findsNothing);
    expect(find.byTooltip('Request hotel edit'), findsWidgets);

    GoRouter.of(tester.element(find.text('Hotels').first))
        .go(ApprovalsScreen.route);
    await tester.pumpAndSettle();

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });

  test('reports export labels are localized', () {
    expect(
      const AppLocalizations(Locale('en')).t('reportInventorySnapshotTitle'),
      'Store Stock snapshot',
    );
    expect(
      const AppLocalizations(Locale('fr')).t('reportOpenAlertsTitle'),
      'Alertes ouvertes',
    );
    expect(
      const AppLocalizations(Locale('ar')).t('downloadPdf'),
      'تحميل PDF',
    );
  });
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

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(super.supabase, super.ref);

  @override
  Future<void> initialize() async {
    // No-op for widget tests
  }
}
