import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/empty_state.dart';
import '../shared/premium_snackbar.dart';
import '../shared/shimmer_loading.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a short, human-readable relative time string.
String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

/// Maps an [AlertType] to a descriptive icon.
IconData _alertTypeIcon(AlertType type) {
  return switch (type) {
    AlertType.lowBidonStock => Icons.inventory_2_outlined,
    AlertType.lowBottleStock => Icons.inventory_2_outlined,
    AlertType.bottleAgeLimit => Icons.timer_outlined,
    AlertType.refillLimit => Icons.replay_outlined,
    AlertType.pendingApproval => Icons.fact_check_outlined,
    AlertType.suspiciousActivity => Icons.warning_amber_outlined,
    AlertType.inactiveHotel => Icons.hotel_outlined,
  };
}

/// Returns the accent colour for a given severity level.
Color _severityColor(int severity, ColorScheme colorScheme) {
  if (severity >= 3) return colorScheme.error;
  if (severity == 2) return Colors.amber.shade700;
  return Colors.blue.shade600;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

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
    HapticFeedback.lightImpact();
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

// ---------------------------------------------------------------------------
// Alerts list + summary
// ---------------------------------------------------------------------------

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

    final openCount = alerts.where((a) => !a.isResolved).length;
    final criticalCount =
        alerts.where((a) => !a.isResolved && a.severity >= 3).length;
    final resolvedCount = alerts.length - openCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary metric cards ──
        _MetricsSummary(
          openCount: openCount,
          criticalCount: criticalCount,
          resolvedCount: resolvedCount,
        ),
        const SizedBox(height: 20),
        // ── Alert cards ──
        for (final alert in sortedAlerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AlertCard(alert: alert, onResolve: onResolve),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary metrics bar
// ---------------------------------------------------------------------------

class _MetricsSummary extends StatelessWidget {
  const _MetricsSummary({
    required this.openCount,
    required this.criticalCount,
    required this.resolvedCount,
  });

  final int openCount;
  final int criticalCount;
  final int resolvedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow screens (<720) use full-width stacked cards
        final isMobile = constraints.maxWidth < 720;
        final cardWidth = isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3; // 3 cards with 12px gaps

        final cards = [
          _MetricCard(
            label: l10n.t('alertsMetricCritical'),
            value: '$criticalCount',
            icon: Icons.error_outline_rounded,
            gradientColors: [
              colorScheme.error.withValues(alpha: 0.15),
              colorScheme.error.withValues(alpha: 0.05),
            ],
            iconColor: colorScheme.error,
            valueColor: colorScheme.error,
            width: cardWidth,
          ),
          _MetricCard(
            label: l10n.t('alertsStatusOpen'),
            value: '$openCount',
            icon: Icons.notifications_active_outlined,
            gradientColors: [
              Colors.amber.withValues(alpha: 0.18),
              Colors.amber.withValues(alpha: 0.05),
            ],
            iconColor: Colors.amber.shade800,
            valueColor: Colors.amber.shade900,
            width: cardWidth,
          ),
          _MetricCard(
            label: l10n.t('alertsStatusResolved'),
            value: '$resolvedCount',
            icon: Icons.check_circle_outline_rounded,
            gradientColors: [
              Colors.green.withValues(alpha: 0.15),
              Colors.green.withValues(alpha: 0.05),
            ],
            iconColor: Colors.green.shade700,
            valueColor: Colors.green.shade800,
            width: cardWidth,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
    required this.valueColor,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color valueColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: valueColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert card
// ---------------------------------------------------------------------------

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onResolve,
  });

  final AlertItem alert;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isResolved = alert.isResolved;
    final severityCol = _severityColor(alert.severity, colorScheme);
    final l10n = AppLocalizations.of(context);

    // Muted opacity for resolved alerts
    final contentOpacity = isResolved ? 0.45 : 1.0;

    return Dismissible(
      key: ValueKey(alert.id),
      direction: isResolved ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        onResolve(alert.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        opacity: isResolved ? 0.72 : 1.0,
        child: Container(
        decoration: BoxDecoration(
          color: isResolved
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.38)
              : colorScheme.surface.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isResolved
              ? null
              : [
                  BoxShadow(
                    color: severityCol.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Colored left severity strip ──
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: severityCol.withValues(alpha: isResolved ? 0.3 : 1.0),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // ── Card content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row: icon + title + time ──
                        Row(
                          children: [
                            // Type icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: severityCol.withValues(
                                    alpha: isResolved ? 0.06 : 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _alertTypeIcon(alert.type),
                                size: 20,
                                color: severityCol
                                    .withValues(alpha: contentOpacity),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title
                            Expanded(
                              child: Text(
                                alert.title,
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: contentOpacity),
                                  decoration: isResolved
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time ago
                            Text(
                              _timeAgo(alert.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: isResolved ? 0.35 : 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // ── Body text ──
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            alert.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: isResolved ? 0.35 : 0.72),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ── Bottom row: chips + resolve button ──
                        Row(
                          children: [
                            // Type chip
                            _PillChip(
                              label: l10n.alertTypeLabel(alert.type),
                              backgroundColor: severityCol
                                  .withValues(alpha: isResolved ? 0.05 : 0.08),
                              textColor: severityCol
                                  .withValues(alpha: contentOpacity),
                            ),
                            const SizedBox(width: 8),
                            // Severity indicator
                            _PillChip(
                              label: l10n.tParams('alertsSeverityLabel',
                                  {'severity': '${alert.severity}'}),
                              backgroundColor: severityCol
                                  .withValues(alpha: isResolved ? 0.05 : 0.08),
                              textColor: severityCol
                                  .withValues(alpha: contentOpacity),
                            ),
                            const Spacer(),
                            // Status indicator or resolve button
                            if (isResolved)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: Colors.green.shade600
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.t('alertsStatusResolved'),
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.green.shade600
                                          .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            else
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.check_outlined,
                                    size: 16),
                                label: Text(l10n.t('alertsResolve')),
                                onPressed: () => onResolve(alert.id),
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
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill chip (compact, rounded label used in card bottom row)
// ---------------------------------------------------------------------------

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

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
