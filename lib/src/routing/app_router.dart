import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../features/shared/not_found_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/team/team_screen.dart';
import '../features/notifications/send_notification_screen.dart';
import '../features/audit/audit_logs_screen.dart';
import '../features/authorizations/authorizations_screen.dart';
import '../domain/app_enums.dart';
import '../state/app_state.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(supabaseAuthStateProvider, (_, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        _ref.read(isPasswordRecoveryProvider.notifier).state = true;
      }
      notifyListeners();
    });
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
    _ref.listen(useSupabaseProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: DashboardScreen.route,
    errorBuilder: (context, state) => NotFoundScreen(error: state.error),
    redirect: (context, state) {
      final useSupabase = ref.read(useSupabaseProvider);
      final hasSession =
          !useSupabase || Supabase.instance.client.auth.currentSession != null;
      final currentUserValue = hasSession ? ref.read(currentUserProvider) : null;
      final currentUser = currentUserValue?.valueOrNull;
      final hasProfileError =
          useSupabase && hasSession && (currentUserValue?.hasError ?? false);

      final path = state.uri.path;
      final isLogin = path == LoginScreen.route;
      final isResetPassword = path == ResetPasswordScreen.route;
      final isAcceptInvite = path == AcceptInvitationScreen.route;
      final isSetPassword = path == SetPasswordScreen.route;
      final isAuthCallback = path == '/auth/callback';
      final isPublicAuthRoute = isLogin || isResetPassword || isAcceptInvite || isSetPassword || isAuthCallback;

      if (useSupabase) {
        final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
        final userMetadata = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
        final isInvitedUser = userMetadata['invitation_id'] != null;
        final isOnboarded = userMetadata['onboarded'] == true;
        final passwordAlreadySet = ref.read(passwordSetProvider);
        final isPasswordRecovery = ref.read(isPasswordRecoveryProvider);
        final needsPassword = (isLoggedIn && isInvitedUser && !isOnboarded && !passwordAlreadySet) || isPasswordRecovery;

        if (!isLoggedIn && !isPublicAuthRoute) return LoginScreen.route;
        
        if (needsPassword && !isSetPassword) {
          return SetPasswordScreen.route;
        }

        if (isLoggedIn && hasProfileError && !isPublicAuthRoute && !needsPassword) {
          return LoginScreen.route;
        }
        if (isLoggedIn && isLogin && !hasProfileError && !needsPassword) {
          return DashboardScreen.route;
        }
      }

      if (!isPublicAuthRoute && currentUser != null) {
        if (path == HotelsScreen.route) {
          final hasHotelsAccess = ref.read(hasPermissionProvider('manage_hotels')) ||
              ref.read(hasPermissionProvider('view_approvals'));
          if (!hasHotelsAccess) {
            return DashboardScreen.route;
          }
        } else {
          final permission = _permissionForPath(path);
          if (permission != null) {
            final hasPerm = ref.read(hasPermissionProvider(permission));
            if (!hasPerm) {
              return DashboardScreen.route;
            }
          }
        }
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
        builder: (context, state) => SetPasswordScreen(
          refreshToken: state.uri.queryParameters['refresh_token'],
          accessToken: state.uri.queryParameters['access_token'],
        ),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: DashboardScreen.route,
            builder: (context, state) {
              final sync = state.uri.queryParameters['sync'] == 'true';
              return DashboardScreen(autoSync: sync);
            },
          ),
          GoRoute(
            path: HotelsScreen.route,
            builder: (context, state) => const HotelsScreen(),
          ),
          GoRoute(
            path: RoomsScreen.route,
            builder: (context, state) {
              final scan = state.uri.queryParameters['scan'] == 'true';
              return RoomsScreen(autoStartScan: scan);
            },
          ),
          GoRoute(
            path: InventoryScreen.route,
            builder: (context, state) {
              final hotelId = state.uri.queryParameters['hotelId'];
              return InventoryScreen(hotelId: hotelId);
            },
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
            path: SendNotificationScreen.route,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SendNotificationScreen(),
            ),
          ),
          GoRoute(
            path: SettingsScreen.route,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AuditLogsScreen.route,
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: AuthorizationsScreen.route,
            builder: (context, state) => const AuthorizationsScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _permissionForPath(String path) {
  if (path == RoomsScreen.route) return 'view_rooms';
  if (path == InventoryScreen.route) return 'view_inventory';
  if (path == ProductsScreen.route) return 'manage_products';
  if (path == TeamScreen.route) return 'manage_team';
  if (path == ApprovalsScreen.route) return 'view_approvals';
  if (path == AlertsScreen.route) return 'view_alerts';
  if (path == ReportsScreen.route) return 'view_reports';
  if (path == SendNotificationScreen.route) return 'send_notifications';
  if (path == AuditLogsScreen.route) return 'view_audit_logs';
  if (path == AuthorizationsScreen.route) return 'view_authorizations';
  return null;
}
