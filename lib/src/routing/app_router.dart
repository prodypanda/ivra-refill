import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/account/account_screen.dart';
import '../features/products/public_product_screen.dart';
import '../features/rooms/qr_action_screen.dart';
import '../features/auth/accept_invitation_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/set_password_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/approvals/approvals_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/hotels/hotels_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/inventory/femme_de_chambre_screen.dart';
import '../features/products/products_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/rooms/rooms_screen.dart';
import '../features/settings/app_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/role_permissions_screen.dart';
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
      if (next.value?.event == AuthChangeEvent.passwordRecovery) {
        _ref.read(isPasswordRecoveryProvider.notifier).state = true;
      }
      notifyListeners();
    });
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
    _ref.listen(isLoggedInProvider, (_, __) => notifyListeners());
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
      final isLoggedIn = ref.read(isLoggedInProvider);
      final currentUserValue = isLoggedIn ? ref.read(currentUserProvider) : null;
      final currentUser = currentUserValue?.valueOrNull;

      final profileErrorObj = currentUserValue?.error;
      final isNoUserError = profileErrorObj is StateError &&
          profileErrorObj.message.contains('No authenticated user');

      final hasProfileError = useSupabase &&
          isLoggedIn &&
          (currentUserValue?.hasError ?? false) &&
          !isNoUserError &&
          !(currentUserValue?.isLoading ?? false);

      final path = state.uri.path;
      final isLogin = path == LoginScreen.route;
      final isResetPassword = path == ResetPasswordScreen.route;
      final isAcceptInvite = path == AcceptInvitationScreen.route;
      final isSetPassword = path == SetPasswordScreen.route;
      final isAuthCallback = path == '/auth/callback';

      final isQrLink = path.startsWith('/app/qr') || path.startsWith('/qr') || path.startsWith('/q/');
      final isPublicProduct = path.startsWith('/public/product/');
      final isPublicAuthRoute = isLogin ||
          isResetPassword ||
          isAcceptInvite ||
          isSetPassword ||
          isAuthCallback ||
          isQrLink ||
          isPublicProduct;

      if (!isLoggedIn) {
        if (isQrLink) {
          String? sku;
          if (path.startsWith('/app/qr') || path.startsWith('/qr')) {
            sku = state.uri.queryParameters['sku'];
          } else {
            final segments = state.uri.pathSegments;
            if (segments.length >= 5) {
              sku = segments[4];
            }
          }
          if (sku != null && sku.trim().isNotEmpty) {
            return '/public/product/$sku';
          } else {
            return LoginScreen.route;
          }
        }
        if (!isPublicAuthRoute) return LoginScreen.route;
      }

      if (isLoggedIn && isQrLink) {
        String? hotelId;
        String? floor;
        String? room;
        String? sku;
        if (path.startsWith('/app/qr') || path.startsWith('/qr')) {
          hotelId = state.uri.queryParameters['hId'];
          floor = state.uri.queryParameters['f'];
          room = state.uri.queryParameters['r'];
          sku = state.uri.queryParameters['sku'];
        } else {
          final segments = state.uri.pathSegments;
          if (segments.length >= 4) {
            hotelId = segments[1];
            floor = segments[2];
            room = segments[3];
            if (segments.length >= 5) {
              sku = segments[4];
            }
          }
        }
        final hotels = ref.read(hotelsProvider).valueOrNull ?? [];
        final matchedHotels = hotels.where((h) => h.id == hotelId);
        final expressQrEnabled = matchedHotels.isNotEmpty ? matchedHotels.first.expressQrEnabled : false;

        final isStaffOrHousekeeper = currentUser?.role == UserRole.hotelStaff ||
            currentUser?.role == UserRole.housekeeper;
        if (!expressQrEnabled && isStaffOrHousekeeper) {
          if (path.startsWith('/qr') || path.startsWith('/app/qr')) {
            return RoomsScreen.route;
          }
        }
        if (!expressQrEnabled || sku == null || sku.trim().isEmpty) {
          if (hotelId != null && floor != null && room != null) {
            return '${RoomsScreen.route}?hotelId=$hotelId&floorNumber=$floor&roomNumber=$room';
          }
        }
      }

      if (useSupabase) {
        final userMetadata =
            Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
        final isInvitedUser = userMetadata['invitation_id'] != null;
        final isOnboarded = userMetadata['onboarded'] == true;
        final passwordAlreadySet = ref.read(passwordSetProvider);
        final isPasswordRecovery = ref.read(isPasswordRecoveryProvider);
        final needsPassword =
            (isLoggedIn && isInvitedUser && !isOnboarded && !passwordAlreadySet) ||
                isPasswordRecovery;

        if (needsPassword && !isSetPassword) {
          return SetPasswordScreen.route;
        }

        if (isLoggedIn && hasProfileError && !isPublicAuthRoute && !needsPassword) {
          return LoginScreen.route;
        }
        if (isLoggedIn && isLogin && !hasProfileError && !needsPassword) {
          return DashboardScreen.route;
        }
      } else {
        if (isLoggedIn && isLogin) {
          return DashboardScreen.route;
        }
      }

      if (!isPublicAuthRoute && currentUser != null) {
        if (path == AppSettingsScreen.route) {
          if (currentUser.role != UserRole.appAdmin) {
            return DashboardScreen.route;
          }
        } else if (path == HotelsScreen.route) {
          final hasHotelsAccess =
              ref.read(hasPermissionProvider('manage_hotels')) ||
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
      GoRoute(
        path: '/public/product/:sku',
        builder: (context, state) {
          final sku = state.pathParameters['sku'] ?? '';
          return PublicProductScreen(sku: sku);
        },
      ),
      GoRoute(
        path: '/app/qr',
        pageBuilder: (context, state) {
          final hotelId = state.uri.queryParameters['hId'] ?? '';
          final floor = state.uri.queryParameters['f'] ?? '';
          final room = state.uri.queryParameters['r'] ?? '';
          final sku = state.uri.queryParameters['sku'] ?? '';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: QrActionScreen(
              hotelSlugOrId: hotelId,
              floor: floor,
              room: room,
              sku: sku,
            ),
            opaque: false,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/qr',
        pageBuilder: (context, state) {
          final hotelId = state.uri.queryParameters['hId'] ?? '';
          final floor = state.uri.queryParameters['f'] ?? '';
          final room = state.uri.queryParameters['r'] ?? '';
          final sku = state.uri.queryParameters['sku'] ?? '';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: QrActionScreen(
              hotelSlugOrId: hotelId,
              floor: floor,
              room: room,
              sku: sku,
            ),
            opaque: false,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/q/:h/:f/:r/:p',
        pageBuilder: (context, state) {
          final hotel = state.pathParameters['h'] ?? '';
          final floor = state.pathParameters['f'] ?? '';
          final room = state.pathParameters['r'] ?? '';
          final sku = state.pathParameters['p'] ?? '';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: QrActionScreen(
              hotelSlugOrId: hotel,
              floor: floor,
              room: room,
              sku: sku,
            ),
            opaque: false,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
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
              final hotelId = state.uri.queryParameters['hotelId'];
              final floorNumber = state.uri.queryParameters['floorNumber'];
              final roomNumber = state.uri.queryParameters['roomNumber'];
              return RoomsScreen(
                autoStartScan: scan,
                hotelId: hotelId,
                floorNumber: floorNumber,
                roomNumber: roomNumber,
              );
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
            path: FemmeDeChambreScreen.route,
            builder: (context, state) => const FemmeDeChambreScreen(),
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
            path: RolePermissionsScreen.route,
            builder: (context, state) => const RolePermissionsScreen(),
          ),
          GoRoute(
            path: AppSettingsScreen.route,
            builder: (context, state) => const AppSettingsScreen(),
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
  if (path == FemmeDeChambreScreen.route) return 'view_inventory';
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
