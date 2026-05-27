import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/empty_state.dart';
import '../shared/premium_snackbar.dart';
import '../shared/shimmer_loading.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  static const route = '/alerts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.t('alerts'),
      onRefresh: () async {
        ref.invalidate(alertsProvider);
        await ref.read(alertsProvider.future);
      },
      actions: [
        IconButton(
          tooltip: l10n.t('alertsRefreshSmart'),
          icon: const Icon(Icons.auto_awesome_outlined),
          onPressed: () => _refreshAlerts(context, ref),
        ),
      ],
      child: AsyncValueView(
        value: ref.watch(alertsProvider),
        onRetry: () => ref.invalidate(alertsProvider),
        loadingWidget: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: CardShimmer(),
          ),
        ),
        builder: (alerts) => _AlertsList(
          alerts: alerts,
          onRefresh: () => _refreshAlerts(context, ref),
          onResolve: (alertId) => _resolveAlert(context, ref, alertId),
        ),
      ),
    );
  }

  Future<void> _refreshAlerts(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    final created = await ref
        .read(repositoryProvider)
        .refreshSmartAlerts(hotelId: user.hotelId);
    ref.invalidate(alertsProvider);
    ref.invalidate(dashboardProvider);
    if (!context.mounted) return;
    PremiumSnackbar.show(
      context,
      AppLocalizations.of(context)
          .tParams('alertsRefreshedToast', {'count': '$created'}),
      icon: Icons.auto_awesome,
    );
  }

  Future<void> _resolveAlert(
    BuildContext context,
    WidgetRef ref,
    String alertId,
  ) async {
    await ref.read(repositoryProvider).resolveAlert(alertId: alertId);
    ref.invalidate(alertsProvider);
    ref.invalidate(dashboardProvider);
    if (!context.mounted) return;
    PremiumSnackbar.show(
      context,
      AppLocalizations.of(context).t('alertResolvedToast'),
      icon: Icons.check_circle_outline,
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({
    required this.alerts,
    required this.onRefresh,
    required this.onResolve,
  });

  final List<AlertItem> alerts;
  final VoidCallback onRefresh;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return _EmptyAlerts(onRefresh: onRefresh);
    }

    final sortedAlerts = [...alerts]..sort((left, right) {
        final leftResolved = left.isResolved ? 1 : 0;
        final rightResolved = right.isResolved ? 1 : 0;
        final resolvedCompare = leftResolved.compareTo(rightResolved);
        if (resolvedCompare != 0) return resolvedCompare;
        final severityCompare = right.severity.compareTo(left.severity);
        if (severityCompare != 0) return severityCompare;
        return right.createdAt.compareTo(left.createdAt);
      });
    final openCount = alerts.where((alert) => !alert.isResolved).length;
    final highCount = alerts
        .where((alert) => !alert.isResolved && alert.severity >= 3)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _AlertMetric(
              label: AppLocalizations.of(context).t('alertsStatusOpen'),
              value: '$openCount',
            ),
            _AlertMetric(
              label: AppLocalizations.of(context).t('alertsMetricCritical'),
              value: '$highCount',
            ),
            _AlertMetric(
              label: AppLocalizations.of(context).t('alertsStatusResolved'),
              value: '${alerts.length - openCount}',
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final alert in sortedAlerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AlertCard(alert: alert, onResolve: onResolve),
          ),
      ],
    );
  }
}

class _AlertMetric extends StatelessWidget {
  const _AlertMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onResolve,
  });

  final AlertItem alert;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCritical = alert.severity >= 3;
    final cardColor = alert.isResolved
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.48)
        : isCritical
            ? colorScheme.errorContainer
            : null;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  isCritical
                      ? Icons.priority_high_outlined
                      : Icons.notifications_active_outlined,
                ),
                Chip(
                  avatar: Icon(
                    alert.isResolved
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                  label: Text(
                    AppLocalizations.of(context).t(
                      alert.isResolved
                          ? 'alertsStatusResolved'
                          : 'alertsStatusOpen',
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    AppLocalizations.of(context).alertTypeLabel(alert.type),
                  ),
                ),
                Chip(
                  label: Text(
                    AppLocalizations.of(context).tParams(
                      'alertsSeverityLabel',
                      {'severity': '${alert.severity}'},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(alert.body),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (!alert.isResolved)
                  FilledButton.icon(
                    icon: const Icon(Icons.check_outlined),
                    label:
                        Text(AppLocalizations.of(context).t('alertsResolve')),
                    onPressed: () => onResolve(alert.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.notifications_off_outlined,
      title: l10n.t('alertsEmptyTitle'),
      message: l10n.t('alertsEmptyMessage'),
      actionLabel: l10n.t('alertsEmptyAction'),
      onAction: onRefresh,
    );
  }
}
