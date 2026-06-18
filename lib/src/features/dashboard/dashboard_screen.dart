import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/shimmer_loading.dart';
import '../shared/premium_snackbar.dart';

import 'widgets/metric_card.dart';
import 'widgets/mobile_hero.dart';
import 'widgets/activity_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({this.autoSync = false, super.key});

  final bool autoSync;
  static const route = '/';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _syncTriggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoSync) {
      _triggerSync();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoSync && !oldWidget.autoSync) {
      _triggerSync();
    }
  }

  void _triggerSync() {
    if (_syncTriggered) return;
    _syncTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSync();
    });
  }

  Future<void> _performSync() async {
    final l10n = AppLocalizations.of(context);
    PremiumSnackbar.show(
      context,
      l10n.t('syncingData'),
      icon: Icons.sync,
    );
    try {
      final repository = ref.read(repositoryProvider);
      await ref.read(offlineSyncServiceProvider).syncPending(repository);

      ref.invalidate(dashboardProvider);
      ref.invalidate(hotelsProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(refillEventsProvider);
      ref.invalidate(alertsProvider);
      ref.invalidate(approvalsProvider);

      await ref.read(dashboardProvider.future);

      if (mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('syncComplete'),
          icon: Icons.check_circle_outline,
        );

        final state = GoRouterState.of(context);
        if (state.uri.queryParameters.containsKey('sync')) {
          context.go(DashboardScreen.route);
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncTriggered = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return PageScaffold(
      title: l10n.t('dashboard'),
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
        await ref.read(dashboardProvider.future);
      },
      child: AsyncValueView(
        value: metrics,
        onRetry: () => ref.invalidate(dashboardProvider),
        loadingWidget: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 640
                    ? 2
                    : 1;
            final aspectRatio = _metricAspectRatio(constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                  children: List.generate(
                    6,
                    (index) => const MetricCardShimmer(),
                  ),
                ),
                const SizedBox(height: 32),
                const CardShimmer(), // for chart
              ],
            );
          },
        ),
        builder: (data) => LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.sizeOf(context).width < 720;
            
            final currentUser = ref.watch(currentUserProvider).valueOrNull;
            final isStaff = currentUser?.role == UserRole.hotelStaff;
            final isManager = currentUser?.role == UserRole.hotelManager || currentUser?.role == UserRole.appManager;
            final isAdmin = currentUser?.role == UserRole.appAdmin;

            // Compute visible cards dynamically
            final List<Widget> visibleCards = [];
            
            if (isAdmin || (isManager && data.hotelCount > 1)) {
              visibleCards.add(MetricCard(
                label: l10n.t('metricHotels'),
                value: data.hotelCount,
                icon: Icons.apartment_outlined,
                iconColor: theme.colorScheme.primary,
                onTap: () => context.go('/hotels'),
              ));
            }
            
            // Everyone sees rooms
            visibleCards.add(MetricCard(
              label: l10n.t('metricRooms'),
              value: data.roomCount,
              icon: Icons.meeting_room_outlined,
              iconColor: Colors.orange,
              onTap: () => context.go('/rooms'),
            ));
            
            if (!isStaff) {
              visibleCards.add(MetricCard(
                label: l10n.t('metricPendingApprovals'),
                value: data.pendingApprovals,
                icon: Icons.fact_check_outlined,
                iconColor: Colors.amber.shade800,
                onTap: () => context.go('/approvals'),
              ));
            }
            
            // Everyone sees alerts
            visibleCards.add(MetricCard(
              label: l10n.t('metricOpenAlerts'),
              value: data.openAlerts,
              icon: Icons.notifications_active_outlined,
              iconColor: theme.colorScheme.error,
              onTap: () => context.go('/alerts'),
            ));
            
            // Everyone sees bottles to replace
            visibleCards.add(MetricCard(
              label: l10n.t('metricBottlesToReplace'),
              value: data.bottlesToReplace,
              icon: Icons.recycling_outlined,
              iconColor: Colors.orange.shade700,
              onTap: () => context.go('/rooms'),
            ));
            
            if (!isStaff) {
              visibleCards.add(MetricCard(
                label: l10n.t('metricLowStockProducts'),
                value: data.lowStockProducts,
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.indigo.shade600,
                onTap: () => context.go('/inventory'),
              ));
            }

            // Adjust grid columns based on number of cards and screen width
            final columns = constraints.maxWidth >= 1000
                ? (visibleCards.length >= 3 ? 3 : visibleCards.length)
                : constraints.maxWidth >= 640
                    ? 2
                    : 1;
            final aspectRatio = _metricAspectRatio(constraints.maxWidth);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  MobileHero(data: data),
                  const SizedBox(height: 16),
                ],
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                  children: visibleCards,
                ),
                const SizedBox(height: 32),
                ActivityChart(
                  isStaff: isStaff,
                  currentUserId: currentUser?.id,
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  double _metricAspectRatio(double width) {
    if (width < 360) return 1.8;
    if (width < 640) return 2.0;
    if (width < 1000) return 2.2;
    return 2.4;
  }
}
