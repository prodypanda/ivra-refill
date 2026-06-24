import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/app_enums.dart';
import '../../state/app_state.dart';
import '../shared/premium_snackbar.dart';

class OperationsAnalyticsPanel extends ConsumerWidget {
  const OperationsAnalyticsPanel({required this.isStaff, this.currentUserId, super.key});

  final bool isStaff;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final refillEvents = ref.watch(refillEventsProvider).valueOrNull ?? const <RefillEvent>[];
    final roomProducts = ref.watch(roomProductsProvider).valueOrNull ?? const <RoomProduct>[];
    final inventory = ref.watch(inventoryProvider).valueOrNull ?? const <InventoryItem>[];
    final now = DateTime.now();
    final visibleEvents = isStaff && currentUserId != null
        ? refillEvents.where((e) => e.performedBy == currentUserId).toList()
        : refillEvents;
    final refillOnly = visibleEvents.where((e) => e.type == RefillEventType.refill).toList();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month - 1, now.day);
    final daily = refillOnly.where((e) => !e.occurredAt.isBefore(today)).length;
    final weekly = refillOnly.where((e) => !e.occurredAt.isBefore(weekStart)).length;
    final monthly = refillOnly.where((e) => !e.occurredAt.isBefore(monthStart)).length;

    final roomByProduct = {for (final item in roomProducts) item.id: item};
    final productUsage = <String, int>{};
    final floorUsage = <String, int>{};
    for (final event in refillOnly) {
      final roomProduct = roomByProduct[event.roomProductId];
      if (roomProduct == null) continue;
      final productName = roomProduct.product.label(Localizations.localeOf(context).languageCode);
      productUsage[productName] = (productUsage[productName] ?? 0) + 1;
      final floor = 'Floor ${roomProduct.floorNumber}';
      floorUsage[floor] = (floorUsage[floor] ?? 0) + 1;
    }

    final attentionRooms = roomProducts.where((item) {
      return item.status == BottleStatus.needsRefill ||
          item.status == BottleStatus.refillLimitReached ||
          item.status == BottleStatus.tooOld ||
          item.status == BottleStatus.needsReplacement ||
          item.refillCount >= item.product.maxRefillCount ||
          item.bottleAgeDays(now) >= item.product.maxBottleAgeDays;
    }).toList();

    final forecasts = inventory.map((item) {
      final productName = item.product.label(Localizations.localeOf(context).languageCode);
      final monthlyUsage = productUsage[productName] ?? 0;
      final avgDaily = monthlyUsage <= 0 ? 0.0 : monthlyUsage / 30.0;
      final days = avgDaily <= 0 ? null : (item.fullBottles / avgDaily).floor();
      return MapEntry(productName, days == null ? 'Stable' : '${days}d');
    }).toList();

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
                Expanded(child: Text('Operations analytics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                OutlinedButton.icon(
                  onPressed: () => _exportSummary(context, ref, daily, weekly, monthly, attentionRooms.length, forecasts),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AnalyticsChip(label: 'Daily', value: daily.toString(), icon: Icons.today_outlined),
                AnalyticsChip(label: 'Weekly', value: weekly.toString(), icon: Icons.date_range_outlined),
                AnalyticsChip(label: 'Monthly', value: monthly.toString(), icon: Icons.calendar_month_outlined),
                AnalyticsChip(label: 'Rooms needing attention', value: attentionRooms.length.toString(), icon: Icons.room_preferences_outlined),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final cards = [
                AnalyticsListCard(title: 'Product usage', icon: Icons.spa_outlined, rows: _topRows(productUsage)),
                AnalyticsListCard(title: 'Usage by floor', icon: Icons.layers_outlined, rows: _topRows(floorUsage)),
                AnalyticsListCard(title: 'Stock depletion forecast', icon: Icons.trending_down_outlined, rows: forecasts.isEmpty ? const [MapEntry('No stock data', '')] : forecasts.take(5).toList()),
                AnalyticsListCard(title: 'Unusual patterns', icon: Icons.warning_amber_outlined, rows: attentionRooms.length > 8 ? [MapEntry('${attentionRooms.length} rooms require review', 'High')] : const [MapEntry('No unusual patterns detected', '')]),
              ];
              if (!wide) return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
              return Wrap(spacing: 12, runSpacing: 12, children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList());
            }),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, String>> _topRows(Map<String, int> values) {
    if (values.isEmpty) return const [MapEntry('No refill data yet', '')];
    final entries = values.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).map((e) => MapEntry(e.key, e.value.toString())).toList();
  }

  Future<void> _exportSummary(BuildContext context, WidgetRef ref, int daily, int weekly, int monthly, int attentionCount, List<MapEntry<String, String>> forecasts) async {
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
    PremiumSnackbar.show(context, result.message, icon: Icons.download_done_outlined);
  }
}

class AnalyticsChip extends StatelessWidget {
  const AnalyticsChip({required this.label, required this.value, required this.icon, super.key});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 10), Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)), Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))]),
    );
  }
}

class AnalyticsListCard extends StatelessWidget {
  const AnalyticsListCard({required this.title, required this.icon, required this.rows, super.key});
  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Icon(icon, size: 18), const SizedBox(width: 8), Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 10),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [Expanded(child: Text(row.key, maxLines: 1, overflow: TextOverflow.ellipsis)), if (row.value.isNotEmpty) Text(row.value, style: const TextStyle(fontWeight: FontWeight.w700))]),
          ),
      ]),
    );
  }
}
