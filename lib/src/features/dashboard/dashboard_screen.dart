import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/shimmer_loading.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const route = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 640
                    ? 2
                    : 1;
            final aspectRatio = _metricAspectRatio(constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  _MobileHero(data: data),
                  const SizedBox(height: 16),
                ],
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                  children: [
                    _MetricCard(
                      l10n.t('metricHotels'),
                      data.hotelCount,
                      Icons.apartment_outlined,
                      theme.colorScheme.primary,
                    ),
                    _MetricCard(
                      l10n.t('metricRooms'),
                      data.roomCount,
                      Icons.meeting_room_outlined,
                      Colors.orange,
                    ),
                    _MetricCard(
                      l10n.t('metricPendingApprovals'),
                      data.pendingApprovals,
                      Icons.fact_check_outlined,
                      Colors.amber.shade800,
                    ),
                    _MetricCard(
                      l10n.t('metricOpenAlerts'),
                      data.openAlerts,
                      Icons.notifications_active_outlined,
                      theme.colorScheme.error,
                    ),
                    _MetricCard(
                      l10n.t('metricBottlesToReplace'),
                      data.bottlesToReplace,
                      Icons.recycling_outlined,
                      Colors.orange.shade700,
                    ),
                    _MetricCard(
                      l10n.t('metricLowStockProducts'),
                      data.lowStockProducts,
                      Icons.inventory_2_outlined,
                      Colors.indigo.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const _ActivityChart(),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  double _metricAspectRatio(double width) {
    if (width < 360) return 2.2;
    if (width < 640) return 2.7;
    return 2.5;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, this.iconColor);

  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.data});

  final DashboardMetrics data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              Colors.orange.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.spa_outlined,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('dashboardHeroTitle'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.bottlesToReplace} ${l10n.t('metricBottlesToReplace').toLowerCase()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _HeroPill(
                    label: l10n.t('metricOpenAlerts'),
                    value: data.openAlerts,
                    icon: Icons.notifications_active_outlined,
                  ),
                  const SizedBox(width: 10),
                  _HeroPill(
                    label: l10n.t('metricPendingApprovals'),
                    value: data.pendingApprovals,
                    icon: Icons.fact_check_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$value ${label.toLowerCase()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).t('dashboardRefillActivity'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 60,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10),
                      FlSpot(1, 24),
                      FlSpot(2, 18),
                      FlSpot(3, 40),
                      FlSpot(4, 30),
                      FlSpot(5, 52),
                      FlSpot(6, 45),
                    ],
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
