import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/app_enums.dart';

import '../../ui/ivra_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/auth_validation.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/shimmer_loading.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  static const route = '/reports';

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _dateRange;
  String? _hotelId;
  String? _productId;
  String? _roomId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final eventsState = ref.watch(refillEventsProvider);
    final roomProductsState = ref.watch(roomProductsProvider);
    final hotelsState = ref.watch(hotelsProvider);
    final productsState = ref.watch(productsProvider);

    final isLoading = eventsState.isLoading || roomProductsState.isLoading || hotelsState.isLoading || productsState.isLoading;
    final hasError = eventsState.hasError || roomProductsState.hasError || hotelsState.hasError || productsState.hasError;

    final events = eventsState.valueOrNull ?? const [];
    final roomProducts = roomProductsState.valueOrNull ?? const [];
    final hotels = hotelsState.valueOrNull ?? const [];
    final products = productsState.valueOrNull ?? const [];
    final filteredEvents = _filteredEvents(events, roomProducts);

    return PageScaffold(
      title: l10n.t('reports'),
      onRefresh: () async {
        ref.invalidate(refillEventsProvider);
        ref.invalidate(roomProductsProvider);
        ref.invalidate(hotelsProvider);
        ref.invalidate(productsProvider);
        await Future.wait([
          ref.read(refillEventsProvider.future),
          ref.read(roomProductsProvider.future),
          ref.read(hotelsProvider.future),
          ref.read(productsProvider.future),
        ]);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isLoading
            ? Column(
                key: const ValueKey('loading'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  CardShimmer(),
                  SizedBox(height: 16),
                  CardShimmer(),
                ],
              )
            : hasError
                ? Center(
                    key: const ValueKey('error'),
                    child: Text(l10n.t('errorLoadingData') ?? 'Error loading data'),
                  )
                : Column(
                    key: const ValueKey('content'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReportFilters(
                        dateRange: _dateRange,
            hotelId: _hotelId,
            productId: _productId,
            roomId: _roomId,
            hotels: hotels,
            products: products,
            roomProducts: roomProducts,
            onDateRangeChanged: (value) => setState(() => _dateRange = value),
            onHotelChanged: (value) => setState(() {
              _hotelId = value;
              _roomId = null;
            }),
            onProductChanged: (value) => setState(() => _productId = value),
            onRoomChanged: (value) => setState(() => _roomId = value),
            onClear: () => setState(() {
              _dateRange = null;
              _hotelId = null;
              _productId = null;
              _roomId = null;
            }),
          ),
          const SizedBox(height: 16),
          _ReportAnalytics(
            events: filteredEvents,
            roomProducts: roomProducts,
            onScheduleEmail: () => _showScheduleEmailDialog(context),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
          _ReportAction(
            title: l10n.t('reportRefillHistoryTitle'),
            body: l10n.t('reportRefillHistoryBody'),
            icon: Icons.history_outlined,
            actions: [
              _ReportButton(
                label: l10n.t('downloadCsv'),
                icon: Icons.table_view_outlined,
                onPressed: () async {
                  final events = _filteredEvents(
                    await ref.read(refillEventsProvider.future),
                    ref.read(roomProductsProvider).valueOrNull ?? const [],
                  );
                  final csv = ref
                      .read(reportExportServiceProvider)
                      .refillHistoryCsv(events);
                  if (!context.mounted) return;
                  await _saveTextExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-refill-history', 'csv'),
                    text: csv,
                    mimeType: 'text/csv;charset=utf-8',
                  );
                },
              ),
              _ReportButton(
                label: l10n.t('downloadPdf'),
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () async {
                  final languageCode =
                      Localizations.localeOf(context).languageCode;
                  final events = _filteredEvents(
                    await ref.read(refillEventsProvider.future),
                    ref.read(roomProductsProvider).valueOrNull ?? const [],
                  );
                  final pdf = await ref
                      .read(reportExportServiceProvider)
                      .refillHistoryPdf(
                        events,
                        languageCode: languageCode,
                      );
                  if (!context.mounted) return;
                  await _saveBinaryExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-refill-history', 'pdf'),
                    bytes: pdf,
                    mimeType: 'application/pdf',
                  );
                },
              ),
            ],
          ),
          _ReportAction(
            title: l10n.t('suggestedOrders'),
            body: l10n.t('reportSuggestedOrdersBody'),
            icon: Icons.request_quote_outlined,
            actions: [
              _ReportButton(
                label: l10n.t('downloadCsv'),
                icon: Icons.table_view_outlined,
                onPressed: () async {
                  final orders = await ref.read(suggestedOrdersProvider.future);
                  final csv = ref
                      .read(reportExportServiceProvider)
                      .suggestedOrdersCsv(
                        orders,
                        languageCode: Localizations.localeOf(context).languageCode,
                      );
                  if (!context.mounted) return;
                  await _saveTextExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-suggested-orders', 'csv'),
                    text: csv,
                    mimeType: 'text/csv;charset=utf-8',
                  );
                },
              ),
              _ReportButton(
                label: l10n.t('downloadPdf'),
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () async {
                  final languageCode =
                      Localizations.localeOf(context).languageCode;
                  final orders = await ref.read(suggestedOrdersProvider.future);
                  final pdf = await ref
                      .read(reportExportServiceProvider)
                      .suggestedOrdersPdf(
                        orders,
                        languageCode: languageCode,
                      );
                  if (!context.mounted) return;
                  await _saveBinaryExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-suggested-orders', 'pdf'),
                    bytes: pdf,
                    mimeType: 'application/pdf',
                  );
                },
              ),
            ],
          ),
          _ReportAction(
            title: l10n.t('reportInventorySnapshotTitle'),
            body: l10n.t('reportInventorySnapshotBody'),
            icon: Icons.inventory_2_outlined,
            actions: [
              _ReportButton(
                label: l10n.t('downloadCsv'),
                icon: Icons.table_view_outlined,
                onPressed: () async {
                  final inventory = await ref.read(inventoryProvider.future);
                  final csv = ref
                      .read(reportExportServiceProvider)
                      .inventoryCsv(
                        inventory,
                        languageCode: Localizations.localeOf(context).languageCode,
                      );
                  if (!context.mounted) return;
                  await _saveTextExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-inventory-snapshot', 'csv'),
                    text: csv,
                    mimeType: 'text/csv;charset=utf-8',
                  );
                },
              ),
              _ReportButton(
                label: l10n.t('downloadPdf'),
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () async {
                  final languageCode =
                      Localizations.localeOf(context).languageCode;
                  final inventory = await ref.read(inventoryProvider.future);
                  final pdf =
                      await ref.read(reportExportServiceProvider).inventoryPdf(
                            inventory,
                            languageCode: languageCode,
                          );
                  if (!context.mounted) return;
                  await _saveBinaryExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-inventory-snapshot', 'pdf'),
                    bytes: pdf,
                    mimeType: 'application/pdf',
                  );
                },
              ),
            ],
          ),
          _ReportAction(
            title: l10n.t('reportOpenAlertsTitle'),
            body: l10n.t('reportOpenAlertsBody'),
            icon: Icons.notification_important_outlined,
            actions: [
              _ReportButton(
                label: l10n.t('downloadCsv'),
                icon: Icons.table_view_outlined,
                onPressed: () async {
                  final alerts = await ref.read(alertsProvider.future);
                  final openAlerts =
                      alerts.where((alert) => !alert.isResolved).toList();
                  final csv = ref
                      .read(reportExportServiceProvider)
                      .alertsCsv(openAlerts);
                  if (!context.mounted) return;
                  await _saveTextExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-open-alerts', 'csv'),
                    text: csv,
                    mimeType: 'text/csv;charset=utf-8',
                  );
                },
              ),
              _ReportButton(
                label: l10n.t('downloadPdf'),
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () async {
                  final languageCode =
                      Localizations.localeOf(context).languageCode;
                  final alerts = await ref.read(alertsProvider.future);
                  final openAlerts =
                      alerts.where((alert) => !alert.isResolved).toList();
                  final pdf =
                      await ref.read(reportExportServiceProvider).alertsPdf(
                            openAlerts,
                            languageCode: languageCode,
                            products: products,
                            roomProducts: roomProducts,
                          );
                  if (!context.mounted) return;
                  await _saveBinaryExport(
                    context,
                    ref,
                    fileName: _fileName('ivra-open-alerts', 'pdf'),
                    bytes: pdf,
                    mimeType: 'application/pdf',
                  );
                },
              ),
            ],
          ),
        ],
      ),
                    ],
                  ),
      ),
    );
  }

  List<RefillEvent> _filteredEvents(
    List<RefillEvent> events,
    List<RoomProduct> roomProducts,
  ) {
    final roomProductById = {for (final item in roomProducts) item.id: item};
    return events.where((event) {
      final item = roomProductById[event.roomProductId];
      if (_dateRange != null) {
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        if (event.occurredAt.isBefore(start) || event.occurredAt.isAfter(end)) {
          return false;
        }
      }
      if (_hotelId != null && item?.hotelId != _hotelId) return false;
      if (_productId != null && item?.product.id != _productId) return false;
      if (_roomId != null && item?.roomId != _roomId) return false;
      return true;
    }).toList();
  }

  Future<void> _showScheduleEmailDialog(BuildContext context) async {
    final email = TextEditingController();
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('scheduleReportEmail')),
        content: TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.t('authLabelEmail'),
            helperText: l10n.t('scheduleReportEmailHint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.t('btnCancel')),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.t('scheduledReportEmailDrafted'))),
              );
            },
            icon: const Icon(Icons.mark_email_read_outlined),
            label: Text(l10n.t('btnSave')),
          ),
        ],
      ),
    );
    email.dispose();
  }

  Future<void> _saveTextExport(
    BuildContext context,
    WidgetRef ref, {
    required String fileName,
    required String text,
    required String mimeType,
  }) {
    return _saveBinaryExport(
      context,
      ref,
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: mimeType,
    );
  }

  Future<void> _saveBinaryExport(
    BuildContext context,
    WidgetRef ref, {
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final result = await ref.read(exportFileServiceProvider).saveBytes(
            fileName: fileName,
            bytes: bytes,
            mimeType: mimeType,
          );
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = result.path == null
          ? l10n.tParams(
              'exportDownloadStarted',
              {'fileName': result.fileName},
            )
          : l10n.tParams(
              'exportSaved',
              {'fileName': result.fileName, 'path': result.path!},
            );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'exportFailed',
          )),
        ),
      );
    }
  }

  String _fileName(String prefix, String extension) {
    final now = DateTime.now();
    final date = [
      now.year.toString().padLeft(4, '0'),
      now.month.toString().padLeft(2, '0'),
      now.day.toString().padLeft(2, '0'),
    ].join('-');
    return '$prefix-$date.$extension';
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.dateRange,
    required this.hotelId,
    required this.productId,
    required this.roomId,
    required this.hotels,
    required this.products,
    required this.roomProducts,
    required this.onDateRangeChanged,
    required this.onHotelChanged,
    required this.onProductChanged,
    required this.onRoomChanged,
    required this.onClear,
  });

  final DateTimeRange? dateRange;
  final String? hotelId;
  final String? productId;
  final String? roomId;
  final List<Hotel> hotels;
  final List<Product> products;
  final List<RoomProduct> roomProducts;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged<String?> onHotelChanged;
  final ValueChanged<String?> onProductChanged;
  final ValueChanged<String?> onRoomChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rooms = roomProducts
        .where((item) => hotelId == null || item.hotelId == hotelId)
        .fold<Map<String, RoomProduct>>({}, (map, item) {
          map.putIfAbsent(item.roomId, () => item);
          return map;
        })
        .values
        .toList()
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: dateRange,
                );
                onDateRangeChanged(picked);
              },
              icon: const Icon(Icons.date_range_outlined),
              label: Text(dateRange == null
                  ? l10n.t('reportFilterDateRange')
                  : '${_fmt(dateRange!.start)} → ${_fmt(dateRange!.end)}'),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: hotelId,
              decoration: InputDecoration(labelText: l10n.t('hotels')),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.t('allHotels'))),
                for (final hotel in hotels)
                  DropdownMenuItem(value: hotel.id, child: Text(hotel.name)),
              ],
              onChanged: onHotelChanged,
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: productId,
              decoration: InputDecoration(labelText: l10n.t('products')),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.t('reportAllProducts'))),
                for (final product in products)
                  DropdownMenuItem(
                    value: product.id,
                    child: Text(product.label(Localizations.localeOf(context).languageCode)),
                  ),
              ],
              onChanged: onProductChanged,
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: roomId,
              decoration: InputDecoration(labelText: l10n.t('rooms')),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.t('reportAllRooms'))),
                for (final room in rooms)
                  DropdownMenuItem(value: room.roomId, child: Text(room.roomNumber)),
              ],
              onChanged: onRoomChanged,
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: Text(l10n.t('reportClearFilters')),
          ),
          Text(
            l10n.t('reportFiltersApplyExports'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _ReportAnalytics extends StatelessWidget {
  const _ReportAnalytics({
    required this.events,
    required this.roomProducts,
    required this.onScheduleEmail,
  });

  final List<RefillEvent> events;
  final List<RoomProduct> roomProducts;
  final VoidCallback onScheduleEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roomProductById = {for (final item in roomProducts) item.id: item};
    final refills = events.where((e) => e.type == RefillEventType.refill).toList();
    final usageByProduct = <String, int>{};
    final usageByRoom = <String, int>{};
    final daily = <DateTime, int>{};
    for (final event in refills) {
      final item = roomProductById[event.roomProductId];
      final day = DateTime(event.occurredAt.year, event.occurredAt.month, event.occurredAt.day);
      daily[day] = (daily[day] ?? 0) + 1;
      if (item == null) continue;
      final product = item.product.label(Localizations.localeOf(context).languageCode);
      usageByProduct[product] = (usageByProduct[product] ?? 0) + 1;
      usageByRoom[item.roomNumber] = (usageByRoom[item.roomNumber] ?? 0) + 1;
    }
    final corrections = events.where((e) => e.type == RefillEventType.correctionRequested).length;
    final replacements = events.where((e) => e.type == RefillEventType.bottleReplaced).length;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.t('reportAnalyticsTitle'),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onScheduleEmail,
                icon: const Icon(Icons.schedule_send_outlined),
                label: Text(l10n.t('scheduleReportEmail')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiTile(label: l10n.t('reportKpiRefills'), value: refills.length.toString(), icon: IvraIcons.refillAction),
              _KpiTile(label: l10n.t('reportKpiCorrections'), value: corrections.toString(), icon: Icons.assignment_late_outlined),
              _KpiTile(label: l10n.t('reportKpiReplacements'), value: replacements.toString(), icon: IvraIcons.replaceAction),
              _KpiTile(label: l10n.t('reportKpiActiveRooms'), value: usageByRoom.length.toString(), icon: Icons.meeting_room_outlined),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final children = [
                _TrendChart(title: l10n.t('reportTrendChart'), values: daily),
                _TopList(title: l10n.t('reportUsageByProduct'), rows: _topRows(usageByProduct)),
                _TopList(title: l10n.t('reportUsageByRoom'), rows: _topRows(usageByRoom)),
              ];
              if (!wide) {
                return Column(
                  children: children
                      .map((child) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: child,
                          ))
                      .toList(),
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: constraints.maxWidth, child: children.first),
                  for (final child in children.skip(1))
                    SizedBox(width: (constraints.maxWidth - 12) / 2, child: child),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, int>> _topRows(Map<String, int> values) {
    final rows = values.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return rows.take(6).toList();
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.title, required this.values});

  final String title;
  final Map<DateTime, int> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final days = List.generate(14, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 13 - index));
    });
    final maxValue = days.fold<int>(1, (max, day) => values[day] != null && values[day]! > max ? values[day]! : max);

    final double maxY;
    if (maxValue < 5) {
      maxY = 5.0;
    } else {
      final rawMaxY = (maxValue * 1.25).ceilToDouble();
      maxY = ((rawMaxY / 5).ceil() * 5).toDouble();
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

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${days.length} ${l10n.t('days')}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: leftInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            final day = days[index];
                            if (index % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${day.day}/${day.month}',
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
                        reservedSize: 32,
                        interval: leftInterval,
                        getTitlesWidget: (value, meta) => Center(
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => theme.colorScheme.primaryContainer,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = days[group.x.toInt()];
                        final dateStr = '${day.day}/${day.month}';
                        return BarTooltipItem(
                          '$dateStr\n${rod.toY.toInt()} ${l10n.t('chartRefills')}',
                          TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (values[days[i]] ?? 0).toDouble(),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  const _TopList({required this.title, required this.rows});

  final String title;
  final List<MapEntry<String, int>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(AppLocalizations.of(context).t('reportNoAnalyticsData'))
            else
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.key, overflow: TextOverflow.ellipsis)),
                      Text(row.value.toString(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ReportButton {
  const _ReportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _ReportAction extends StatefulWidget {
  const _ReportAction({
    required this.title,
    required this.body,
    required this.icon,
    required this.actions,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<_ReportButton> actions;

  @override
  State<_ReportAction> createState() => _ReportActionState();
}

class _ReportActionState extends State<_ReportAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary
                      .withValues(alpha: _isHovered ? 0.15 : 0.0),
                  blurRadius: _isHovered ? 20 : 0,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              borderColor: theme.colorScheme.outline
                  .withValues(alpha: _isHovered ? 0.3 : 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.6),
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(widget.icon,
                              size: 32, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final action in widget.actions)
                              FilledButton.icon(
                                onPressed: action.onPressed,
                                icon: Icon(action.icon, size: 18),
                                label: Text(action.label),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
