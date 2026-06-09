import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/auth_validation.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const route = '/reports';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.t('reports'),
      child: Wrap(
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
                  final events = await ref.read(refillEventsProvider.future);
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
                  final events = await ref.read(refillEventsProvider.future);
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
                      .suggestedOrdersCsv(orders);
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
                      .inventoryCsv(inventory);
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
    );
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
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
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
