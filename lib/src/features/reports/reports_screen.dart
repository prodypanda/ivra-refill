import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/auth_validation.dart';
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

class _ReportAction extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(body),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in actions)
                    FilledButton.icon(
                      onPressed: action.onPressed,
                      icon: Icon(action.icon),
                      label: Text(action.label),
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
