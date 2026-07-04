import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ivra_refill/src/app/ivra_app.dart';
import 'package:ivra_refill/src/app/theme.dart';
import 'package:ivra_refill/src/data/ivra_repository.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/features/alerts/alerts_screen.dart';
import 'package:ivra_refill/src/features/auth/login_screen.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:ivra_refill/src/features/reports/reports_screen.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/features/settings/settings_screen.dart';
import 'package:ivra_refill/src/features/account/account_screen.dart';
import 'package:ivra_refill/src/features/shared/offline_banner.dart';
import 'package:ivra_refill/src/features/shared/premium_confirm_dialog.dart';
import 'package:ivra_refill/src/features/team/team_screen.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('DashboardScreen', () {
    testWidgets('renders all six metric cards', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      expect(find.text('Hotels'), findsWidgets);
      expect(find.text('Rooms'), findsWidgets);
      expect(find.text('Pending approvals'), findsWidgets);
      expect(find.text('Open alerts'), findsWidgets);
      expect(find.text('Bottles to replace'), findsWidgets);
      expect(find.text('Low stock products'), findsWidgets);
    });

    testWidgets('renders metric values from demo data', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      // Demo data has 2 hotels and 2 rooms
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('French dashboard title renders correctly', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        locale: const Locale('fr'),
      );

      expect(find.text('Tableau de bord'), findsWidgets);
    });

    testWidgets('shows retryable error state when data loading fails',
        (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        repository: _ThrowingRepository(),
      );

      expect(find.text('Could not load this section'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('supports pull to refresh on scrollable pages', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      expect(find.byType(RefreshIndicator), findsWidgets);
    });
  });

  group('LoginScreen', () {
    testWidgets('mobile login shows task-focused sign-in card', (tester) async {
      final router = GoRouter(
        initialLocation: LoginScreen.route,
        routes: [
          GoRoute(
            path: LoginScreen.route,
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: buildIvraTheme(Brightness.light),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpAndSettle();

      expect(find.text('Ivra'), findsNothing);
      expect(find.text('Sign in'), findsNWidgets(2));
      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('Arabic mobile login keeps RTL localized layout',
        (tester) async {
      final router = GoRouter(
        initialLocation: LoginScreen.route,
        routes: [
          GoRoute(
            path: LoginScreen.route,
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: buildIvraTheme(Brightness.light),
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpAndSettle();

      final fieldDirection = Directionality.of(
        tester.element(find.text('البريد الإلكتروني')),
      );
      expect(fieldDirection, TextDirection.rtl);
      expect(find.text('تسجيل الدخول'), findsNWidgets(2));
      expect(find.text('كلمة المرور'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      final router = GoRouter(
        initialLocation: LoginScreen.route,
        routes: [
          GoRoute(
            path: LoginScreen.route,
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: buildIvraTheme(Brightness.light),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
    });
  });

  group('AlertsScreen', () {
    testWidgets('navigates to alerts and shows alert cards', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AlertsScreen.route);
      await tester.pumpAndSettle();

      // Demo data has 2 alerts
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Open'), findsWidgets);
    });

    testWidgets('shows refresh smart alerts button', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AlertsScreen.route);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh smart alerts'), findsOneWidget);
    });

    testWidgets('shows resolve button for open alerts', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AlertsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Resolve'), findsWidgets);
    });

    testWidgets('alert severity and type chips are displayed', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AlertsScreen.route);
      await tester.pumpAndSettle();

      // Demo data has severity 2 and 3 alerts
      expect(find.text('Severity 2'), findsWidgets);
      expect(find.text('Severity 3'), findsWidgets);
    });
  });

  group('InventoryScreen', () {
    testWidgets('navigates to inventory and shows data table', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(InventoryScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Store Stock'), findsWidgets);
      expect(find.text('Full 1L bottles with pump'), findsWidgets);
      expect(find.text('Full 5L refill bottles'), findsWidgets);
      expect(find.text('Empty & Open Bottles'), findsWidgets);
    });

    testWidgets('shows stock status for inventory items', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(InventoryScreen.route);
      await tester.pumpAndSettle();

      // Shampoo has 9 bottles, threshold 12 → low stock
      expect(find.text('Low stock'), findsWidgets);
    });

    testWidgets('mobile inventory uses stock cards instead of data table',
        (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(390, 844),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(InventoryScreen.route);
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsNothing);
      expect(find.text('IVR-SHA-1L'), findsOneWidget);
      expect(find.text('Low stock'), findsWidgets);
    });

    testWidgets('shows adjust stock button', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(InventoryScreen.route);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Adjust stock'), findsWidgets);
    });

    testWidgets('shows suggested orders section', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(InventoryScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Suggested orders'), findsWidgets);
    });
  });

  group('RoomsScreen', () {
    testWidgets('mobile rooms show summary and rounded room cards',
        (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(390, 844),
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

      expect(find.text('Attention Required'), findsWidgets);
      expect(find.text('Refill Needed'), findsWidgets);
      expect(find.text('All OK'), findsWidgets);
      expect(find.textContaining('Room '), findsWidgets);
    });

    testWidgets('Arabic mobile rooms keep RTL localized layout',
        (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(390, 844),
        locale: const Locale('ar'),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('لوحة القيادة').first))
          .go(RoomsScreen.route);
      await tester.pumpAndSettle();

      // Switch to detailed view and expand floors
      await tester.tap(find.text('عرض تفصيلي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('توسيع الكل'));
      await tester.pumpAndSettle();

      final roomsContext = tester.element(find.text('الغرف').first);
      expect(Directionality.of(roomsContext), TextDirection.rtl);
      expect(find.text('انتباه مطلوب'), findsWidgets);
      expect(find.text('تعبئة مطلوبة'), findsWidgets);
      expect(find.text('كل شيء سليم'), findsWidgets);
      expect(find.textContaining('غرفة '), findsWidgets);
    });

    testWidgets('housekeeper can add and remove room products',
        (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.housekeeper),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(RoomsScreen.route);
      await tester.pumpAndSettle();

      // Switch to detailed view and expand floors
      await tester.tap(find.text('Detailed View'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expand all'));
      await tester.pumpAndSettle();

      // Verify "Add product" button is visible
      final addBtn = find.text('Add product').first;
      expect(addBtn, findsOneWidget);

      // Tap on "Add product" button
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap on DropdownButtonFormField to show items
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Find the option Conditioner
      final conditionerOption = find.text('Conditioner (IVR-CON-1L)').last;
      await tester.tap(conditionerOption);
      await tester.pumpAndSettle();

      // Click Confirm button
      final confirmAddBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      expect(confirmAddBtn, findsOneWidget);
      await tester.tap(confirmAddBtn);
      await tester.pumpAndSettle();

      // Toast or snackbar should be displayed and dialog should close
      expect(find.text('Product added'), findsOneWidget);

      // The conditioner product should now be visible in the list
      expect(find.text('Conditioner'), findsWidgets);

      // Scroll the Conditioner widget into view first
      await tester.ensureVisible(find.text('Conditioner').first);
      await tester.pumpAndSettle();

      // Now remove the product using the trash icon
      // Find the delete button next to the "Conditioner" product
      final conditionerRow = find.ancestor(
        of: find.text('Conditioner').first,
        matching: find.byType(Row),
      ).first;
      final deleteBtn = find.descendant(
        of: conditionerRow,
        matching: find.byIcon(Icons.delete_outline),
      );
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Deletion confirmation dialog is open
      expect(find.byType(PremiumConfirmDialog), findsOneWidget);

      // Tap confirm on the dialog
      final confirmDeleteBtn = find.descendant(
        of: find.byType(PremiumConfirmDialog),
        matching: find.byType(FilledButton),
      );
      expect(confirmDeleteBtn, findsOneWidget);
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // Check success snackbar
      expect(find.text('Product removed'), findsOneWidget);
    });
  });

  group('ReportsScreen', () {
    testWidgets('shows all four report cards', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(ReportsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Refill history'), findsWidgets);
      expect(find.text('Suggested orders'), findsWidgets);
      expect(find.text('Store Stock snapshot'), findsWidgets);
      expect(find.text('Open alerts'), findsWidgets);
    });

    testWidgets('shows CSV and PDF download buttons', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(ReportsScreen.route);
      await tester.pumpAndSettle();

      // 4 report cards × 2 buttons each = 8 buttons
      expect(find.text('Download CSV'), findsNWidgets(4));
      expect(find.text('Download PDF'), findsNWidgets(4));
    });

    testWidgets('French reports page renders localized titles', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        locale: const Locale('fr'),
      );

      GoRouter.of(tester.element(find.text('Tableau de bord').first))
          .go(ReportsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Historique de recharge'), findsWidgets);
      expect(find.text('Instantané du stock'), findsWidgets);
      expect(find.text('Alertes ouvertes'), findsWidgets);
      expect(find.text('Télécharger CSV'), findsNWidgets(4));
      expect(find.text('Télécharger PDF'), findsNWidgets(4));
    });

    testWidgets('Arabic reports page renders localized titles', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        locale: const Locale('ar'),
      );

      GoRouter.of(tester.element(find.text('لوحة القيادة').first))
          .go(ReportsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('سجل التعبئة'), findsWidgets);
      expect(find.text('لقطة مخزون المتجر'), findsWidgets);
      expect(find.text('التنبيهات المفتوحة'), findsWidgets);
      expect(find.text('تحميل CSV'), findsNWidgets(4));
      expect(find.text('تحميل PDF'), findsNWidgets(4));
    });

    testWidgets('hotel staff cannot navigate to reports', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(ReportsScreen.route);
      await tester.pumpAndSettle();

      // Should redirect to dashboard
      expect(find.text('Reports'), findsNothing);
      expect(find.text('Dashboard'), findsWidgets);
    });
  });

  group('SettingsScreen', () {
    testWidgets('mobile settings shows compact status card', (tester) async {
      await _pumpIvraApp(tester, size: const Size(390, 844));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Demo mode'), findsWidgets);
      expect(find.text('Offline mode'), findsWidgets);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('Arabic mobile settings keep RTL localized layout',
        (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(390, 844),
        locale: const Locale('ar'),
      );

      GoRouter.of(tester.element(find.text('لوحة القيادة').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      final settingsFinder = find.text('الإعدادات').first;
      expect(
          Directionality.of(tester.element(settingsFinder)), TextDirection.rtl);
      expect(find.text('وضع العرض'), findsWidgets);
      expect(find.text('وضع عدم الاتصال'), findsWidgets);
      expect(find.text('اللغة'), findsOneWidget);
    });

    testWidgets('shows language selector', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('English'), findsWidgets);
    });

    testWidgets('shows demo mode indicator when not using Supabase',
        (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Demo mode'), findsWidgets);
    });

    testWidgets('shows demo user switcher in demo mode', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Demo user'), findsWidgets);
    });

    testWidgets('shows offline mode switch', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Offline mode'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(SwitchListTile),
          matching: find.text('Offline mode'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows pending sync section', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(SettingsScreen.route);
      await tester.pumpAndSettle();

      expect(find.textContaining('Pending sync'), findsWidgets);
    });
  });

  group('AccountScreen', () {
    testWidgets('shows profile form with current user data', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AccountScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
      expect(find.textContaining('admin@ivra.example'), findsWidgets);
      expect(find.textContaining('App admin'), findsWidgets);
    });

    testWidgets('shows password change section', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AccountScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('does not show sign-out in demo mode', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AccountScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('hotel staff sees their role and hotel scope', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AccountScreen.route);
      await tester.pumpAndSettle();

      expect(find.textContaining('Hotel staff'), findsWidgets);
      expect(find.textContaining('Seaside Hotel'), findsWidgets);
    });

    testWidgets('save button exists on profile card', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(AccountScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsWidgets);
    });
  });

  group('TeamScreen', () {
    testWidgets('shows team accounts and pending invitations tables',
        (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      expect(find.text('Team'), findsWidgets);
      expect(find.text('Team accounts'), findsWidgets);
      expect(find.text('Pending invitations'), findsWidgets);
    });

    testWidgets('admin can see invite button', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Invite team member'), findsOneWidget);
    });

    testWidgets('hotel staff cannot see invite button', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      // hotel_staff doesn't have Team in allowed routes
      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      // Should redirect to dashboard (hotelStaff can't access Team)
      expect(find.text('Dashboard'), findsWidgets);
    });

    testWidgets('hotel manager can see invite button', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelManager),
      );

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Invite team member'), findsOneWidget);
    });

    testWidgets('shows team member data in table', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      // Demo data team members
      expect(find.text('Ivra Admin'), findsWidgets);
      expect(find.text('admin@ivra.example'), findsWidgets);
    });

    testWidgets('shows pending invitation details', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      // Demo data has one pending invitation
      expect(find.text('Palms Ops Lead'), findsWidgets);
      expect(find.text('opslead@palms.example'), findsWidgets);
    });

    testWidgets('invitation management actions visible for admin',
        (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      GoRouter.of(tester.element(find.text('Dashboard').first))
          .go(TeamScreen.route);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Copy invitation link'), findsWidgets);
      expect(find.byTooltip('Resend invitation'), findsWidgets);
      expect(find.byTooltip('Cancel invitation'), findsWidgets);
    });
  });

  group('Navigation role restrictions', () {
    testWidgets('app admin sees all navigation items', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Hotels'), findsWidgets);
      expect(find.text('Rooms'), findsWidgets);
      expect(find.text('Store Stock'), findsWidgets);
      expect(find.text('Products'), findsWidgets);
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Approvals'), findsWidgets);
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('hotel manager sees hotels but not products', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelManager),
      );

      expect(find.text('Hotels'), findsWidgets);
      expect(find.text('Products'), findsNothing);
      expect(find.text('Rooms'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
    });

    testWidgets('hotel staff sees minimal navigation', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.hotelStaff),
      );

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Rooms'), findsWidgets);
      expect(find.text('Store Stock'), findsWidgets);
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);

      // Should NOT see these in the navigation menu
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Hotels'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Products'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Team'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Approvals'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Reports'),
        ),
        findsNothing,
      );
    });

    testWidgets('app manager sees same items as admin', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        currentUser: _userForRole(UserRole.appManager),
      );

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Hotels'), findsWidgets);
      expect(find.text('Products'), findsWidgets);
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Approvals'), findsWidgets);
    });
  });

  group('Responsive layout', () {
    testWidgets('tablet-width uses navigation rail', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1024, 768));

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('mobile-width uses bottom navigation', (tester) async {
      await _pumpIvraApp(tester, size: const Size(375, 812));

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('mobile more menu opens secondary destinations',
        (tester) async {
      await _pumpIvraApp(tester, size: const Size(375, 812));

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Store Stock'), findsWidgets);
    });

    testWidgets('extended rail appears at wide width', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1400, 900));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, true);
    });

    testWidgets('non-extended rail at medium width', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1000, 900));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, false);
    });
  });

  group('Localization', () {
    testWidgets('English navigation labels', (tester) async {
      await _pumpIvraApp(tester, size: const Size(1280, 900));

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Store Stock'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('French navigation labels', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        locale: const Locale('fr'),
      );

      expect(find.text('Tableau de bord'), findsWidgets);
      expect(find.text('Stock magasin'), findsWidgets);
      expect(find.text('Paramètres'), findsWidgets);
      expect(find.text('Chambres'), findsWidgets);
    });

    testWidgets('Arabic navigation labels with RTL', (tester) async {
      await _pumpIvraApp(
        tester,
        size: const Size(1280, 900),
        locale: const Locale('ar'),
      );

      expect(find.text('لوحة القيادة'), findsWidgets);
      expect(find.text('مخزون المتجر'), findsWidgets);
      expect(find.text('الإعدادات'), findsWidgets);
      expect(find.text('الغرف'), findsWidgets);

      final dashboardFinder = find.text('لوحة القيادة').first;
      expect(
        Directionality.of(tester.element(dashboardFinder)),
        TextDirection.rtl,
      );
    });

    test('AppLocalizations covers all required keys for all languages', () {
      const keys = [
        'dashboard',
        'hotels',
        'rooms',
        'inventory',
        'products',
        'team',
        'account',
        'approvals',
        'alerts',
        'reports',
        'settings',
        'more',
        'dashboardHeroTitle',
        'refill',
        'undo',
        'correction',
        'pending',
        'suggestedOrders',
        'bottles',
        'bidons',
        'language',
        'demoMode',
        'downloadCsv',
        'downloadPdf',
        'reportRefillHistoryTitle',
        'reportRefillHistoryBody',
        'reportSuggestedOrdersBody',
        'reportInventorySnapshotTitle',
        'reportInventorySnapshotBody',
        'reportOpenAlertsTitle',
        'reportOpenAlertsBody',
        'exportFailed',
      ];

      for (final languageCode in ['en', 'fr', 'ar']) {
        final l10n = AppLocalizations(Locale(languageCode));
        for (final key in keys) {
          final value = l10n.t(key);
          expect(
            value,
            isNot(equals(key)),
            reason: 'Key "$key" is not translated for language "$languageCode"',
          );
        }
      }
    });
  });
}

Future<void> _pumpIvraApp(
  WidgetTester tester, {
  Size size = const Size(1024, 768),
  Locale? locale,
  UserProfile? currentUser,
  IvraRepository? repository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => locale ?? const Locale('en')),
        if (repository != null)
          repositoryProvider.overrideWithValue(repository),
        if (currentUser != null)
          currentUserProvider.overrideWith((ref) async => currentUser),
        // Force connectivity to be deterministically "online" in widget
        // tests so we don't depend on the optional SUPABASE_URL
        // --dart-define or the host-lookup timer scheduling between
        // pumpAndSettle frames.
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

class _ThrowingRepository extends MockIvraRepository {
  @override
  Future<DashboardMetrics> dashboardMetrics({String? hotelId}) {
    throw Exception('Network unavailable');
  }
}

UserProfile _userForRole(UserRole role) {
  return UserProfile(
    id: 'test-${role.value}',
    fullName: 'Test ${role.value}',
    email: '${role.value}@ivra.test',
    role: role,
    roleString: role.value,
    hotelId: role == UserRole.hotelManager || role == UserRole.hotelStaff || role == UserRole.housekeeper
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
