import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/ivra_icons.dart';
import '../../domain/models.dart';
import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/shimmer_loading.dart';
import '../shared/premium_snackbar.dart';

class _AnalyticsData {
  _AnalyticsData({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.attentionRoomsCount,
    required this.forecastsData,
    required this.productUsage,
    required this.floorUsageData,
  });

  final int daily;
  final int weekly;
  final int monthly;
  final int attentionRoomsCount;
  final List<({String productName, int? days})> forecastsData;
  final Map<String, int> productUsage;
  final Map<int, int> floorUsageData;
}

final _analyticsDataProvider = Provider.autoDispose.family<_AnalyticsData,
    ({bool isStaff, String? currentUserId, String languageCode})>((ref, arg) {
  final refillEvents = ref.watch(refillEventsProvider
      .select((state) => state.valueOrNull ?? const <RefillEvent>[]));
  final roomProducts = ref.watch(roomProductsProvider
      .select((state) => state.valueOrNull ?? const <RoomProduct>[]));
  final inventory = ref.watch(inventoryProvider
      .select((state) => state.valueOrNull ?? const <InventoryItem>[]));

  final now = DateTime.now();
  final visibleEvents = arg.isStaff && arg.currentUserId != null
      ? refillEvents.where((e) => e.performedBy == arg.currentUserId).toList()
      : refillEvents;
  final refillOnly =
      visibleEvents.where((e) => e.type == RefillEventType.refill).toList();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(const Duration(days: 6));
  final monthStart = DateTime(now.year, now.month - 1, now.day);

  final daily = refillOnly.where((e) => !e.occurredAt.isBefore(today)).length;
  final weekly =
      refillOnly.where((e) => !e.occurredAt.isBefore(weekStart)).length;
  final monthly =
      refillOnly.where((e) => !e.occurredAt.isBefore(monthStart)).length;

  final roomByProduct = {for (final item in roomProducts) item.id: item};
  final productUsage = <String, int>{};
  final floorUsageData = <int, int>{};

  for (final event in refillOnly) {
    final roomProduct = roomByProduct[event.roomProductId];
    if (roomProduct == null) continue;
    final productName = roomProduct.product.label(arg.languageCode);
    productUsage[productName] = (productUsage[productName] ?? 0) + 1;
    final floor = roomProduct.floorNumber;
    floorUsageData[floor] = (floorUsageData[floor] ?? 0) + 1;
  }

  final attentionRoomsCount = roomProducts.where((item) {
    return item.status == BottleStatus.needsRefill ||
        item.status == BottleStatus.refillLimitReached ||
        item.status == BottleStatus.tooOld ||
        item.status == BottleStatus.needsReplacement ||
        item.refillCount >= item.product.maxRefillCount ||
        item.bottleAgeDays(now) >= item.product.maxBottleAgeDays;
  }).length;

  final forecastsData = inventory.map((item) {
    final productName = item.product.label(arg.languageCode);
    final monthlyUsage = productUsage[productName] ?? 0;
    final avgDaily = monthlyUsage <= 0 ? 0.0 : monthlyUsage / 30.0;
    final days = avgDaily <= 0 ? null : (item.fullBottles / avgDaily).floor();
    return (productName: productName, days: days);
  }).toList();

  return _AnalyticsData(
    daily: daily,
    weekly: weekly,
    monthly: monthly,
    attentionRoomsCount: attentionRoomsCount,
    forecastsData: forecastsData,
    productUsage: productUsage,
    floorUsageData: floorUsageData,
  );
});

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
      l10n.t('syncingData') ?? 'Syncing data...',
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
          l10n.t('syncComplete') ?? 'Sync complete',
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

            final currentUser =
                ref.watch(currentUserProvider.select((s) => s.valueOrNull));
            final isStaff = currentUser?.role == UserRole.hotelStaff;
            final isManager = currentUser?.role == UserRole.hotelManager ||
                currentUser?.role == UserRole.appManager;
            final isAdmin = currentUser?.role == UserRole.appAdmin;

            // Compute visible cards dynamically
            final List<Widget> visibleCards = [];

            if (isAdmin || (isManager && data.hotelCount > 1)) {
              visibleCards.add(_MetricCard(
                label: l10n.t('metricHotels'),
                value: data.hotelCount,
                icon: Icons.apartment_outlined,
                iconColor: theme.colorScheme.primary,
                onTap: () => context.go('/hotels'),
              ));
            }

            // Everyone sees rooms
            visibleCards.add(_MetricCard(
              label: l10n.t('metricRooms'),
              value: data.roomCount,
              icon: Icons.meeting_room_outlined,
              iconColor: Colors.orange,
              onTap: () => context.go('/rooms'),
            ));

            if (!isStaff) {
              visibleCards.add(_MetricCard(
                label: l10n.t('metricPendingApprovals'),
                value: data.pendingApprovals,
                icon: Icons.fact_check_outlined,
                iconColor: Colors.amber.shade800,
                onTap: () => context.go('/approvals'),
              ));
            }

            // Everyone sees alerts
            visibleCards.add(_MetricCard(
              label: l10n.t('metricOpenAlerts'),
              value: data.openAlerts,
              icon: Icons.notifications_active_outlined,
              iconColor: theme.colorScheme.error,
              onTap: () => context.go('/alerts'),
            ));

            // Everyone sees bottles to replace
            visibleCards.add(_MetricCard(
              label: l10n.t('metricBottlesToReplace'),
              value: data.bottlesToReplace,
              icon: IvraIcons.replaceAction,
              iconColor: Colors.orange.shade700,
              onTap: () => context.go('/rooms'),
            ));

            if (!isStaff) {
              visibleCards.add(_MetricCard(
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
                  children: visibleCards,
                ),
                const SizedBox(height: 32),
                _ActivityChart(
                  isStaff: isStaff,
                  currentUserId: currentUser?.id,
                ),
                const SizedBox(height: 32),
                _OperationsAnalyticsPanel(
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

class _OperationsAnalyticsPanel extends ConsumerWidget {
  const _OperationsAnalyticsPanel({required this.isStaff, this.currentUserId});

  final bool isStaff;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    final analyticsData = ref.watch(_analyticsDataProvider((
      isStaff: isStaff,
      currentUserId: currentUserId,
      languageCode: languageCode,
    )));

    final floorUsage = {
      for (final entry in analyticsData.floorUsageData.entries)
        '${l10n.t('roomsLabelFloor')} ${entry.key}': entry.value
    };

    final forecasts = analyticsData.forecastsData
        .map((f) => MapEntry(
              f.productName,
              f.days == null
                  ? l10n.t('dashboardStable')
                  : '${f.days}${l10n.t('roomsLabelDaysUnit')}',
            ))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(l10n.t('dashboardOpsAnalytics'),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                OutlinedButton.icon(
                  onPressed: () => _exportSummary(
                      context,
                      ref,
                      analyticsData.daily,
                      analyticsData.weekly,
                      analyticsData.monthly,
                      analyticsData.attentionRoomsCount,
                      forecasts),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.t('dashboardExport')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AnalyticsChip(
                    label: l10n.t('dashboardDaily'),
                    value: analyticsData.daily.toString(),
                    icon: Icons.today_outlined),
                _AnalyticsChip(
                    label: l10n.t('dashboardWeekly'),
                    value: analyticsData.weekly.toString(),
                    icon: Icons.date_range_outlined),
                _AnalyticsChip(
                    label: l10n.t('dashboardMonthly'),
                    value: analyticsData.monthly.toString(),
                    icon: Icons.calendar_month_outlined),
                _AnalyticsChip(
                  label: l10n.t('dashboardRoomsAttention'),
                  value: analyticsData.attentionRoomsCount.toString(),
                  icon: Icons.room_preferences_outlined,
                  width: 290,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final cards = [
                _AnalyticsListCard(
                    title: l10n.t('dashboardProductUsage'),
                    icon: Icons.spa_outlined,
                    rows: _topRows(analyticsData.productUsage)),
                _AnalyticsListCard(
                    title: l10n.t('dashboardUsageByFloor'),
                    icon: Icons.layers_outlined,
                    rows: _topRows(floorUsage)),
                _AnalyticsListCard(
                    title: l10n.t('dashboardStockForecast'),
                    icon: Icons.trending_down_outlined,
                    rows: forecasts.isEmpty
                        ? [MapEntry(l10n.t('dashboardNoStockData'), '')]
                        : forecasts.take(5).toList()),
                _AnalyticsListCard(
                    title: l10n.t('dashboardUnusualPatterns'),
                    icon: Icons.warning_amber_outlined,
                    rows: analyticsData.attentionRoomsCount > 8
                        ? [
                            MapEntry(
                                l10n.tParams('dashboardRoomsRequireReview', {
                                  'count':
                                      '${analyticsData.attentionRoomsCount}'
                                }),
                                l10n.t('dashboardHighPriority'))
                          ]
                        : [MapEntry(l10n.t('dashboardNoUnusualPatterns'), '')]),
              ];
              if (!wide)
                return Column(
                    children: cards
                        .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: c))
                        .toList());
              return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map((c) => SizedBox(
                          width: (constraints.maxWidth - 12) / 2, child: c))
                      .toList());
            }),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, String>> _topRows(Map<String, int> values) {
    if (values.isEmpty) return const [MapEntry('No refill data yet', '')];
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => MapEntry(e.key, e.value.toString()))
        .toList();
  }

  Future<void> _exportSummary(
      BuildContext context,
      WidgetRef ref,
      int daily,
      int weekly,
      int monthly,
      int attentionCount,
      List<MapEntry<String, String>> forecasts) async {
    final buffer = StringBuffer()
      ..writeln('metric,value')
      ..writeln('daily_refills,$daily')
      ..writeln('weekly_refills,$weekly')
      ..writeln('monthly_refills,$monthly')
      ..writeln('rooms_needing_attention,$attentionCount')
      ..writeln()
      ..writeln('product,days_remaining');
    for (final forecast in forecasts) {
      buffer.writeln('"${forecast.key}","${forecast.value}"');
    }
    final result = await ref.read(exportFileServiceProvider).saveBytes(
          fileName: 'ivra-management-summary.csv',
          bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
          mimeType: 'text/csv',
        );
    if (!context.mounted) return;
    PremiumSnackbar.show(context, result.message,
        icon: Icons.download_done_outlined);
  }
}

class _AnalyticsChip extends StatelessWidget {
  const _AnalyticsChip({
    required this.label,
    required this.value,
    required this.icon,
    this.width = 210,
  });
  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900))
      ]),
    );
  }
}

class _AnalyticsListCard extends StatelessWidget {
  const _AnalyticsListCard(
      {required this.title, required this.icon, required this.rows});
  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)))
        ]),
        const SizedBox(height: 10),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(
                  child: Text(row.key,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (row.value.isNotEmpty)
                Text(row.value,
                    style: const TextStyle(fontWeight: FontWeight.w700))
            ]),
          ),
      ]),
    );
  }
}

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedScale(
              scale: _isHovered ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface.withValues(alpha: 0.9),
                        theme.colorScheme.surface.withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.iconColor
                            .withValues(alpha: _isHovered ? 0.15 : 0.05),
                        blurRadius: _isHovered ? 24 : 12,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: widget.iconColor
                          .withValues(alpha: _isHovered ? 0.3 : 0.1),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(widget.icon,
                                size: 28, color: widget.iconColor),
                          ),
                        ],
                      ),
                      Text(
                        widget.value.toString(),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}

class _MobileHero extends StatefulWidget {
  const _MobileHero({required this.data});

  final DashboardMetrics data;

  @override
  State<_MobileHero> createState() => _MobileHeroState();
}

class _MobileHeroState extends State<_MobileHero> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withRed(220).withGreen(120),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.spa,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insights,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.t('dashboardHeroTitle'),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild:
                          const SizedBox(height: 0, width: double.infinity),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            widget.data.bottlesToReplace.toString(),
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            l10n.t('metricBottlesToReplace'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _HeroPill(
                                label: l10n.t('metricOpenAlerts'),
                                value: widget.data.openAlerts,
                                icon: Icons.notifications_active,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              _HeroPill(
                                label: l10n.t('metricPendingApprovals'),
                                value: widget.data.pendingApprovals,
                                icon: Icons.fact_check,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = color ?? theme.colorScheme.onSurface;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: foregroundColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$value ${label.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ChartDateRange { last7Days, lastMonth, lastYear }

class _ActivityChart extends ConsumerStatefulWidget {
  const _ActivityChart({
    this.isStaff = false,
    this.currentUserId,
  });

  final bool isStaff;
  final String? currentUserId;

  @override
  ConsumerState<_ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends ConsumerState<_ActivityChart> {
  ChartDateRange _dateRange = ChartDateRange.last7Days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final hotels = ref.watch(hotelsProvider.select((s) => s.valueOrNull ?? []));
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
                    widget.isStaff
                        ? l10n.t('myCompletedTasksThisWeek')
                        : l10n.t('refillActivity'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  );

                  final headerControls =
                      _buildSelectors(context, hotels, selectedHotelId);

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
                          Icon(Icons.timeline,
                              color: theme.colorScheme.primary),
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
                  child: CardShimmer(),
                ),
                error: (err, stack) => SizedBox(
                  height: 220,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          l10n.t('genericError'),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
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
                      final List<DateTime> dates = List.generate(
                          7, (i) => today.subtract(Duration(days: 6 - i)));

                      for (final event in refills) {
                        final eventDate = DateTime(event.occurredAt.year,
                            event.occurredAt.month, event.occurredAt.day);
                        for (int i = 0; i < 7; i++) {
                          if (eventDate.isAtSameMomentAs(dates[i])) {
                            dailyCounts[i]++;
                          }
                        }
                      }

                      spots = List.generate(
                          7,
                          (i) =>
                              FlSpot(i.toDouble(), dailyCounts[i].toDouble()));

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
                      final List<DateTime> dates = List.generate(
                          30, (i) => today.subtract(Duration(days: 29 - i)));

                      for (final event in refills) {
                        final eventDate = DateTime(event.occurredAt.year,
                            event.occurredAt.month, event.occurredAt.day);
                        for (int i = 0; i < 30; i++) {
                          if (eventDate.isAtSameMomentAs(dates[i])) {
                            dailyCounts[i]++;
                          }
                        }
                      }

                      spots = List.generate(
                          30,
                          (i) =>
                              FlSpot(i.toDouble(), dailyCounts[i].toDouble()));
                      xLabels =
                          dates.map((d) => '${d.day}/${d.month}').toList();
                      break;

                    case ChartDateRange.lastYear:
                      maxX = 11.0;
                      final List<int> monthlyCounts = List.filled(12, 0);
                      final List<DateTime> months = List.generate(
                          12,
                          (i) =>
                              DateTime(today.year, today.month - (11 - i), 1));

                      for (final event in refills) {
                        final eventMonth = DateTime(
                            event.occurredAt.year, event.occurredAt.month, 1);
                        for (int i = 0; i < 12; i++) {
                          if (eventMonth.isAtSameMomentAs(months[i])) {
                            monthlyCounts[i]++;
                          }
                        }
                      }

                      spots = List.generate(
                          12,
                          (i) => FlSpot(
                              i.toDouble(), monthlyCounts[i].toDouble()));

                      final monthKeys = [
                        'monthJan',
                        'monthFeb',
                        'monthMar',
                        'monthApr',
                        'monthMay',
                        'monthJun',
                        'monthJul',
                        'monthAug',
                        'monthSep',
                        'monthOct',
                        'monthNov',
                        'monthDec'
                      ];
                      xLabels = months
                          .map((m) => l10n.t(monthKeys[m.month - 1]))
                          .toList();
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
                                  final isMobile =
                                      MediaQuery.sizeOf(context).width < 600;
                                  if (_dateRange == ChartDateRange.lastMonth) {
                                    if (index % 5 != 0 &&
                                        index != xLabels.length - 1) {
                                      return const SizedBox.shrink();
                                    }
                                  } else if (_dateRange ==
                                      ChartDateRange.lastYear) {
                                    if (isMobile && index % 2 != 0) {
                                      return const SizedBox.shrink();
                                    }
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      xLabels[index],
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
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
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.0),
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
        ));
  }

  Widget _buildSelectors(
      BuildContext context, List<Hotel> hotels, String? selectedHotelId) {
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
              icon: Icon(Icons.arrow_drop_down,
                  color: theme.colorScheme.primary, size: 18),
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
