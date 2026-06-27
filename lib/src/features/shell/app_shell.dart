import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../version.dart';

import '../alerts/alerts_screen.dart';
import '../approvals/approvals_screen.dart';
import '../audit/audit_logs_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../hotels/hotels_screen.dart';
import '../inventory/inventory_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../rooms/rooms_screen.dart';
import '../settings/settings_screen.dart';
import '../shared/offline_banner.dart';
import '../shared/web_download_banner.dart';
import '../team/team_screen.dart';
import '../notifications/send_notification_screen.dart';
import '../../services/notification_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Initialize push notifications when shell is mounted
    Future.microtask(() {
      ref.read(notificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.valueOrNull;
    final navItems = _navItems(context, ref);
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
                  Column(
                    children: [
                      Expanded(
                        child: NavigationRail(
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
                                icon: _buildNavItemIcon(ref, item),
                                label: Text(item.label),
                              ),
                          ],
                        ),
                      ),
                      if (constraints.maxWidth >= 1180) const _DrawerFooter(),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: Colors.black12),
                  Expanded(
                    child: Column(
                      children: [
                        const _ImpersonationBanner(),
                        const OfflineBanner(),
                        const WebDownloadBanner(),
                        Expanded(child: widget.child),
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
          child: widget.child,
        );
      },
    );
  }

  List<_NavItem> _navItems(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = [
      _NavItem(
        l10n.t('dashboard'),
        Icons.space_dashboard_outlined,
        DashboardScreen.route,
        shortLabel: l10n.t('dashboardShort'),
      ),
      _NavItem(
        l10n.t('hotels'),
        Icons.apartment_outlined,
        HotelsScreen.route,
        permission: 'manage_hotels',
      ),
      _NavItem(
        l10n.t('rooms'),
        Icons.meeting_room_outlined,
        RoomsScreen.route,
        permission: 'view_rooms',
      ),
      _NavItem(
        l10n.t('inventory'),
        Icons.inventory_2_outlined,
        InventoryScreen.route,
        permission: 'view_inventory',
      ),
      _NavItem(
        l10n.t('products'),
        Icons.spa_outlined,
        ProductsScreen.route,
        permission: 'manage_products',
      ),
      _NavItem(
        l10n.t('team'),
        Icons.groups_2_outlined,
        TeamScreen.route,
        permission: 'manage_team',
      ),
      _NavItem(
        l10n.t('approvals'),
        Icons.fact_check_outlined,
        ApprovalsScreen.route,
        permission: 'view_approvals',
      ),
      _NavItem(
        l10n.t('alerts'),
        Icons.notifications_active_outlined,
        AlertsScreen.route,
        permission: 'view_alerts',
      ),
      _NavItem(
        l10n.t('reports'),
        Icons.summarize_outlined,
        ReportsScreen.route,
        permission: 'view_reports',
      ),
      _NavItem(
        l10n.t('menuSendPush'),
        Icons.send_rounded,
        SendNotificationScreen.route,
        permission: 'send_notifications',
      ),
      _NavItem(
        l10n.t('menuAuditLogs'),
        Icons.security_outlined,
        AuditLogsScreen.route,
        permission: 'view_audit_logs',
      ),
      _NavItem(
        l10n.t('authorizationsTitle'),
        Icons.admin_panel_settings_outlined,
        '/authorizations',
        permission: 'view_authorizations',
      ),
      _NavItem(
        l10n.t('settings'),
        Icons.settings_outlined,
        SettingsScreen.route,
      ),
    ];

    final userProfile = ref.watch(currentUserProvider).valueOrNull;
    if (userProfile == null) {
      return items
          .where((item) => item.route == DashboardScreen.route)
          .toList();
    }

    return items.where((item) {
      if (item.permission == null) return true;
      return ref.watch(hasPermissionProvider(item.permission!));
    }).toList();
  }
}

class _MobileShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            const _ImpersonationBanner(),
            const OfflineBanner(),
            const WebDownloadBanner(),
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
                    _showMoreDestinations(context, ref, moreItems);
                    return;
                  }
                  context.go(primaryItems[index].route);
                },
                destinations: [
                  for (var index = 0; index < primaryItems.length; index++)
                    NavigationDestination(
                      icon: _buildNavItemIcon(ref, primaryItems[index]),
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

  void _showMoreDestinations(BuildContext context, WidgetRef ref, List<_NavItem> moreItems) {
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
                      leading: _buildNavItemIcon(ref, item),
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
                const SizedBox(height: 16),
                const _DrawerFooter(),
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
  const _NavItem(
    this.label,
    this.icon,
    this.route, {
    this.permission,
    this.shortLabel,
  });

  final String label;
  final String? shortLabel;
  final IconData icon;
  final String route;
  final String? permission;

  String get mobileLabel => shortLabel ?? label;
}

/// A persistent banner shown across every screen while an app admin is
/// "viewing as" another user. It keeps the admin aware that the app is scoped
/// to someone else and offers a one-tap exit back to their own view.
class _ImpersonationBanner extends ConsumerWidget {
  const _ImpersonationBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impersonated = ref.watch(impersonatedUserProvider);
    if (impersonated == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tParams(
                    'impersonationBanner',
                    {'name': impersonated.fullName},
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  stopImpersonation(ref);
                  context.go(DashboardScreen.route);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l10n.t('impersonationExit')),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'v$appVersion',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'iVRA Refill, by Pulire Tunisia',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Widget _buildNavItemIcon(WidgetRef ref, _NavItem item) {
  if (item.route == AlertsScreen.route) {
    final alertsAsync = ref.watch(alertsProvider);
    return alertsAsync.maybeWhen(
      data: (alerts) {
        final openCount = alerts.where((a) => !a.isResolved).length;
        if (openCount > 0) {
          return Badge(
            backgroundColor: Colors.orange,
            label: Text('$openCount'),
            child: Icon(item.icon),
          );
        }
        return Icon(item.icon);
      },
      orElse: () => Icon(item.icon),
    );
  }
  return Icon(item.icon);
}
