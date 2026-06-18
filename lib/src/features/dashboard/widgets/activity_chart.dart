import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
import '../../../domain/app_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_state.dart';
import '../../shared/shimmer_loading.dart';

enum ChartDateRange { last7Days, lastMonth, lastYear }

class ActivityChart extends ConsumerStatefulWidget {
  const ActivityChart({
    this.isStaff = false,
    this.currentUserId,
    super.key,
  });

  final bool isStaff;
  final String? currentUserId;

  @override
  ConsumerState<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends ConsumerState<ActivityChart> {
  ChartDateRange _dateRange = ChartDateRange.last7Days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final hotels = ref.watch(hotelsProvider).valueOrNull ?? [];
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final refillEventsAsync = ref.watch(refillEventsProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header layout with selectors
            LayoutBuilder(
              builder: (context, headerConstraints) {
                final isWide = headerConstraints.maxWidth > 600;
                final titleText = Text(
                  widget.isStaff ? l10n.t('myCompletedTasksThisWeek') : l10n.t('refillActivity'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                );

                final headerControls = _buildSelectors(context, hotels, selectedHotelId);

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: titleText),
                      const SizedBox(width: 16),
                      headerControls,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleText),
                        Icon(Icons.timeline, color: theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    headerControls,
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Chart Body
            refillEventsAsync.when(
              loading: () => const SizedBox(
                height: 220,
                child: CardShimmer(isCompact: false),
              ),
              error: (err, stack) => SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'Error: $err',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
              data: (refillEvents) {
                // Aggregate refill events, filtering by user if staff
                final refills = refillEvents.where((e) {
                  if (e.type != RefillEventType.refill) return false;
                  if (widget.isStaff && widget.currentUserId != null) {
                    return e.performedBy == widget.currentUserId;
                  }
                  return true;
                }).toList();

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                List<FlSpot> spots = [];
                List<String> xLabels = [];
                double maxX = 6.0;
                double maxY = 10.0;

                switch (_dateRange) {
                  case ChartDateRange.last7Days:
                    maxX = 6.0;
                    final List<int> dailyCounts = List.filled(7, 0);
                    final List<DateTime> dates = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

                    for (final event in refills) {
                      final eventDate = DateTime(event.occurredAt.year, event.occurredAt.month, event.occurredAt.day);
                      for (int i = 0; i < 7; i++) {
                        if (eventDate.isAtSameMomentAs(dates[i])) {
                          dailyCounts[i]++;
                        }
                      }
                    }

                    spots = List.generate(7, (i) => FlSpot(i.toDouble(), dailyCounts[i].toDouble()));

                    final days = [
                      l10n.t('dayMon'),
                      l10n.t('dayTue'),
                      l10n.t('dayWed'),
                      l10n.t('dayThu'),
                      l10n.t('dayFri'),
                      l10n.t('daySat'),
                      l10n.t('daySun'),
                    ];
                    xLabels = dates.map((d) => days[d.weekday - 1]).toList();
                    break;

                  case ChartDateRange.lastMonth:
                    maxX = 29.0;
                    final List<int> dailyCounts = List.filled(30, 0);
                    final List<DateTime> dates = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));

                    for (final event in refills) {
                      final eventDate = DateTime(event.occurredAt.year, event.occurredAt.month, event.occurredAt.day);
                      for (int i = 0; i < 30; i++) {
                        if (eventDate.isAtSameMomentAs(dates[i])) {
                          dailyCounts[i]++;
                        }
                      }
                    }

                    spots = List.generate(30, (i) => FlSpot(i.toDouble(), dailyCounts[i].toDouble()));
                    xLabels = dates.map((d) => '${d.day}/${d.month}').toList();
                    break;

                  case ChartDateRange.lastYear:
                    maxX = 11.0;
                    final List<int> monthlyCounts = List.filled(12, 0);
                    final List<DateTime> months = List.generate(12, (i) => DateTime(today.year, today.month - (11 - i), 1));

                    for (final event in refills) {
                      final eventMonth = DateTime(event.occurredAt.year, event.occurredAt.month, 1);
                      for (int i = 0; i < 12; i++) {
                        if (eventMonth.isAtSameMomentAs(months[i])) {
                          monthlyCounts[i]++;
                        }
                      }
                    }

                    spots = List.generate(12, (i) => FlSpot(i.toDouble(), monthlyCounts[i].toDouble()));

                    final monthKeys = [
                      'monthJan', 'monthFeb', 'monthMar', 'monthApr', 'monthMay', 'monthJun',
                      'monthJul', 'monthAug', 'monthSep', 'monthOct', 'monthNov', 'monthDec'
                    ];
                    xLabels = months.map((m) => l10n.t(monthKeys[m.month - 1])).toList();
                    break;
                }

                double highestRefillCount = 0;
                for (final spot in spots) {
                  if (spot.y > highestRefillCount) {
                    highestRefillCount = spot.y;
                  }
                }

                if (highestRefillCount < 5) {
                  maxY = 5.0;
                } else {
                  maxY = (highestRefillCount * 1.25).ceilToDouble();
                  maxY = ((maxY / 5).ceil() * 5).toDouble();
                }

                double leftInterval = 5;
                if (maxY <= 5) {
                  leftInterval = 1;
                } else if (maxY <= 15) {
                  leftInterval = 3;
                } else if (maxY <= 30) {
                  leftInterval = 5;
                } else if (maxY <= 100) {
                  leftInterval = 20;
                } else {
                  leftInterval = 50;
                }

                return SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: leftInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < xLabels.length) {
                                final isMobile = MediaQuery.sizeOf(context).width < 600;
                                if (_dateRange == ChartDateRange.lastMonth) {
                                  if (index % 5 != 0 && index != xLabels.length - 1) {
                                    return const SizedBox.shrink();
                                  }
                                } else if (_dateRange == ChartDateRange.lastYear) {
                                  if (isMobile && index % 2 != 0) {
                                    return const SizedBox.shrink();
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    xLabels[index],
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: leftInterval,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: maxX,
                      minY: 0,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots
                                .map((spot) => LineTooltipItem(
                                      '${spot.y.toInt()} ${l10n.t('chartRefills')}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ))
                                .toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: theme.colorScheme.primary,
                          barWidth: 6, // Thicker line width
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: Colors.white,
                                strokeWidth: 3,
                                strokeColor: theme.colorScheme.primary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.5), // Stronger gradient
                                theme.colorScheme.primary.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors(BuildContext context, List<Hotel> hotels, String? selectedHotelId) {
    if (widget.isStaff) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final showHotelSelector = hotels.length > 1;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showHotelSelector) ...[
          _buildDropdown<String?>(
            value: selectedHotelId,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.t('allHotels')),
              ),
              for (final hotel in hotels)
                DropdownMenuItem(
                  value: hotel.id,
                  child: Text(hotel.name),
                ),
            ],
            onChanged: (val) {
              ref.read(selectedHotelIdProvider.notifier).state = val;
            },
            icon: Icons.hotel_outlined,
            theme: theme,
          ),
        ],
        _buildDropdown<ChartDateRange>(
          value: _dateRange,
          items: [
            DropdownMenuItem(
              value: ChartDateRange.last7Days,
              child: Text(l10n.t('last7Days')),
            ),
            DropdownMenuItem(
              value: ChartDateRange.lastMonth,
              child: Text(l10n.t('lastMonth')),
            ),
            DropdownMenuItem(
              value: ChartDateRange.lastYear,
              child: Text(l10n.t('lastYear')),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _dateRange = val;
              });
            }
          },
          icon: Icons.date_range_outlined,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary, size: 18),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
