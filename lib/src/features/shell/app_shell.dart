import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

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

        return _MobileShell(
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          navItems: navItems,
          background: globalBackground,
          child: child,
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
        shortLabel: l10n.t('dashboardShort'),
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

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.navItems,
    required this.background,
    required this.child,
  });

  final int selectedIndex;
  final List<_NavItem> navItems;
  final BoxDecoration? background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const maxPrimary = 3;
    final hasMore = navItems.length > maxPrimary;
    final primaryItems = navItems.take(maxPrimary).toList();
    final moreItems = navItems.skip(maxPrimary).toList();
    final destinationCount = primaryItems.length + (hasMore ? 1 : 0);
    final primaryIndex = selectedIndex < primaryItems.length
        ? selectedIndex
        : destinationCount - 1;
    final theme = Theme.of(context);

    return Container(
      decoration: background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Theme(
              data: theme.copyWith(
                navigationBarTheme: theme.navigationBarTheme.copyWith(
                  labelTextStyle: WidgetStateProperty.all(
                    theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                height: 80,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: primaryIndex,
                onDestinationSelected: (index) {
                  if (hasMore && index == primaryItems.length) {
                    _showMoreDestinations(context, moreItems);
                    return;
                  }
                  context.go(primaryItems[index].route);
                },
                destinations: [
                  for (var index = 0; index < primaryItems.length; index++)
                    NavigationDestination(
                      icon: Icon(primaryItems[index].icon),
                      label: primaryItems[index].mobileLabel,
                    ),
                  if (hasMore)
                    NavigationDestination(
                      icon: const Icon(Icons.more_horiz),
                      label: l10n.t('more'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreDestinations(BuildContext context, List<_NavItem> moreItems) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Center(child: _BrandMark()),
                const SizedBox(height: 8),
                for (final item in moreItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.route);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo-dark.png',
      height: 110,
      fit: BoxFit.contain,
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route, this.allowedRoles,
      {this.shortLabel});

  final String label;
  final String? shortLabel;
  final IconData icon;
  final String route;
  final Set<UserRole> allowedRoles;

  String get mobileLabel => shortLabel ?? label;
}
