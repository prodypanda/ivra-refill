import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      child: AsyncValueView(
        value: metrics,
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
