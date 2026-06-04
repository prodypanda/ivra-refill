import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/account/account_screen.dart';
import '../features/auth/accept_invitation_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/set_password_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/approvals/approvals_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/hotels/hotels_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/products/products_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/rooms/rooms_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/team/team_screen.dart';
import '../domain/app_enums.dart';
import '../state/app_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  ref.watch(supabaseAuthStateProvider);
  final hasSession =
      !useSupabase || Supabase.instance.client.auth.currentSession != null;
  final currentUserValue = hasSession ? ref.watch(currentUserProvider) : null;
  final currentUser = currentUserValue?.valueOrNull;
  final hasProfileError =
      useSupabase && hasSession && (currentUserValue?.hasError ?? false);

  return GoRouter(
    initialLocation: DashboardScreen.route,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLogin = path == LoginScreen.route;
      final isResetPassword = path == ResetPasswordScreen.route;
      final isAcceptInvite = path == AcceptInvitationScreen.route;
      final isSetPassword = path == SetPasswordScreen.route;
      final isPublicAuthRoute =
          isLogin || isResetPassword || isAcceptInvite || isSetPassword;

      if (useSupabase) {
        final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
        final userMetadata =
            Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
        final isInvitedUser = userMetadata['invitation_id'] != null;
        final isOnboarded = userMetadata['onboarded'] == true;
        final needsPassword = isLoggedIn && isInvitedUser && !isOnboarded;

        if (!isLoggedIn && !isPublicAuthRoute) return LoginScreen.route;

        if (needsPassword && !isSetPassword) {
          return SetPasswordScreen.route;
        }

        if (isLoggedIn &&
            hasProfileError &&
            !isPublicAuthRoute &&
            !needsPassword) {
          return LoginScreen.route;
        }
        if (isLoggedIn && isLogin && !hasProfileError && !needsPassword) {
          return DashboardScreen.route;
        }
      }

      if (!isPublicAuthRoute &&
          currentUser != null &&
          !_isAllowedRoute(currentUser.role, path)) {
        return DashboardScreen.route;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: LoginScreen.route,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: ResetPasswordScreen.route,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AcceptInvitationScreen.route,
        builder: (context, state) => AcceptInvitationScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: SetPasswordScreen.route,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: DashboardScreen.route,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: HotelsScreen.route,
            builder: (context, state) => const HotelsScreen(),
          ),
          GoRoute(
            path: RoomsScreen.route,
            builder: (context, state) => const RoomsScreen(),
          ),
          GoRoute(
            path: InventoryScreen.route,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: ProductsScreen.route,
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: TeamScreen.route,
            builder: (context, state) => const TeamScreen(),
          ),
          GoRoute(
            path: AccountScreen.route,
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: ApprovalsScreen.route,
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: AlertsScreen.route,
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: ReportsScreen.route,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: SettingsScreen.route,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

bool _isAllowedRoute(UserRole role, String path) {
  final allowedRoutes = _allowedRoutesByRole[role];
  return allowedRoutes == null || allowedRoutes.contains(path);
}

const _allowedRoutesByRole = {
  UserRole.appAdmin: {
    DashboardScreen.route,
    HotelsScreen.route,
    RoomsScreen.route,
    InventoryScreen.route,
    ProductsScreen.route,
    TeamScreen.route,
    AccountScreen.route,
    ApprovalsScreen.route,
    AlertsScreen.route,
    ReportsScreen.route,
    SettingsScreen.route,
  },
  UserRole.appManager: {
    DashboardScreen.route,
    HotelsScreen.route,
    RoomsScreen.route,
    InventoryScreen.route,
    ProductsScreen.route,
    TeamScreen.route,
    AccountScreen.route,
    ApprovalsScreen.route,
    AlertsScreen.route,
    ReportsScreen.route,
    SettingsScreen.route,
  },
  UserRole.hotelManager: {
    DashboardScreen.route,
    HotelsScreen.route,
    RoomsScreen.route,
    InventoryScreen.route,
    TeamScreen.route,
    AccountScreen.route,
    ApprovalsScreen.route,
    AlertsScreen.route,
    ReportsScreen.route,
    SettingsScreen.route,
  },
  UserRole.hotelStaff: {
    DashboardScreen.route,
    RoomsScreen.route,
    InventoryScreen.route,
    AccountScreen.route,
    AlertsScreen.route,
    SettingsScreen.route,
  },
};
