import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../account/account_screen.dart';
import '../alerts/alerts_screen.dart';
import '../approvals/approvals_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../hotels/hotels_screen.dart';
import '../inventory/inventory_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../rooms/rooms_screen.dart';
import '../settings/settings_screen.dart';
import '../shared/offline_banner.dart';
import '../team/team_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.valueOrNull;
    final navItems = _navItems(context, currentUser?.role);
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = navItems.indexWhere(
      (item) => location == item.route,
    );

    // Global warm gradient for the Solar Infusion design system
    final isLight = Theme.of(context).brightness == Brightness.light;
    final globalBackground = isLight
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF8F5), // Surface
                Color(0xFFFFF4D9), // Warm golden cream
              ],
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Container(
            decoration: globalBackground,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                children: [
                  NavigationRail(
                    extended: constraints.maxWidth >= 1180,
                    scrollable: true,
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onDestinationSelected: (index) =>
                        context.go(navItems[index].route),
                    labelType: constraints.maxWidth >= 1180
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: _BrandMark(),
                    ),
                    destinations: [
                      for (final item in navItems)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: Colors.black12),
                  Expanded(
                    child: Column(
                      children: [
                        const OfflineBanner(),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: globalBackground,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text('Ivra')),
            drawer: NavigationDrawer(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) {
                Navigator.of(context).pop();
                context.go(navItems[index].route);
              },
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: _BrandMark(),
                ),
                for (final item in navItems)
                  NavigationDrawerDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
            body: Column(
              children: [
                const OfflineBanner(),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_NavItem> _navItems(BuildContext context, UserRole? role) {
    final l10n = AppLocalizations.of(context);
    final items = [
      _NavItem(
        l10n.t('dashboard'),
        Icons.space_dashboard_outlined,
        DashboardScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
          UserRole.hotelStaff,
        },
      ),
      _NavItem(
        l10n.t('hotels'),
        Icons.apartment_outlined,
        HotelsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
        },
      ),
      _NavItem(
        l10n.t('rooms'),
        Icons.meeting_room_outlined,
        RoomsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
          UserRole.hotelStaff,
        },
      ),
      _NavItem(
        l10n.t('inventory'),
        Icons.inventory_2_outlined,
        InventoryScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
          UserRole.hotelStaff,
        },
      ),
      _NavItem(
        l10n.t('products'),
        Icons.spa_outlined,
        ProductsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
        },
      ),
      _NavItem(
        l10n.t('team'),
        Icons.groups_2_outlined,
        TeamScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
        },
      ),
      _NavItem(
        l10n.t('account'),
        Icons.account_circle_outlined,
        AccountScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
          UserRole.hotelStaff,
        },
      ),
      _NavItem(
        l10n.t('approvals'),
        Icons.fact_check_outlined,
        ApprovalsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
        },
      ),
      _NavItem(
        l10n.t('alerts'),
        Icons.notifications_active_outlined,
        AlertsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
          UserRole.hotelStaff,
        },
      ),
      _NavItem(
        l10n.t('reports'),
        Icons.summarize_outlined,
        ReportsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
        },
      ),
      _NavItem(
        l10n.t('settings'),
        Icons.settings_outlined,
        SettingsScreen.route,
        const {
          UserRole.appAdmin,
          UserRole.appManager,
          UserRole.hotelManager,
          UserRole.hotelStaff,
        },
      ),
    ];

    if (role == null) {
      return items
          .where((item) => item.route == DashboardScreen.route)
          .toList();
    }

    return items.where((item) => item.allowedRoles.contains(role)).toList();
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Color.lerp(Theme.of(context).colorScheme.primary, Colors.orange.shade700, 0.3) ?? Theme.of(context).colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'I',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Ivra',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route, this.allowedRoles);

  final String label;
  final IconData icon;
  final String route;
  final Set<UserRole> allowedRoles;
}
