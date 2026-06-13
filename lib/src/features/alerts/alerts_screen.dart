import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../services/notification_service.dart';
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
          onDelete: (alertId) => _deleteAlert(context, ref, alertId),
          onResolveAll: () => _resolveAllAlerts(context, ref, alerts),
          onDeleteAll: () => _deleteAllAlerts(context, ref, alerts),
        ),
      ),
    );
  }

  Future<void> _refreshAlerts(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    
    final oldAlerts = await ref.read(repositoryProvider).alerts(hotelId: user.hotelId);
    final oldIds = oldAlerts.map((a) => a.id).toSet();

    final created = await ref
        .read(repositoryProvider)
        .refreshSmartAlerts(hotelId: user.hotelId);

    if (created > 0) {
      final newAlertsList = await ref.read(repositoryProvider).alerts(hotelId: user.hotelId);
      final newAlerts = newAlertsList.where((a) => !oldIds.contains(a.id)).toList();
      
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      final langCode = Localizations.localeOf(context).languageCode;
      final products = await ref.read(productsProvider.future);
      
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel_v2',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      for (final alert in newAlerts) {
        final product = products.where((p) => p.id == alert.productId).firstOrNull;
        final (title, body) = alert.localizedStrings(l10n, langCode, product);

        await flutterLocalNotificationsPlugin.show(
          id: alert.id.hashCode,
          title: title,
          body: body,
          notificationDetails: platformChannelSpecifics,
        );
      }
    }

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

  Future<void> _deleteAlert(
    BuildContext context,
    WidgetRef ref,
    String alertId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('delete')),
        content: Text('${l10n.t('delete')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('btnCancel')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteAlert(alertId);
        ref.invalidate(alertsProvider);
        ref.invalidate(dashboardProvider);
      } catch (e) {
        if (context.mounted) {
          PremiumSnackbar.showError(context, e);
        }
      }
    }
  }

  Future<void> _resolveAllAlerts(
    BuildContext context,
    WidgetRef ref,
    List<AlertItem> alerts,
  ) async {
    final openAlerts = alerts.where((a) => !a.isResolved).toList();
    if (openAlerts.isEmpty) return;

    HapticFeedback.mediumImpact();
    final repository = ref.read(repositoryProvider);
    try {
      await Future.wait(openAlerts.map((a) => repository.resolveAlert(alertId: a.id)));
      ref.invalidate(alertsProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        PremiumSnackbar.show(
          context,
          AppLocalizations.of(context).t('alertResolvedToast'),
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve all alerts: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllAlerts(
    BuildContext context,
    WidgetRef ref,
    List<AlertItem> alerts,
  ) async {
    if (alerts.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('delete')),
        content: Text('Delete all alerts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('btnCancel')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(repositoryProvider);
      try {
        await Future.wait(alerts.map((a) => repository.deleteAlert(a.id)));
        ref.invalidate(alertsProvider);
        ref.invalidate(dashboardProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete all alerts: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
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
    required this.onDelete,
    required this.onResolveAll,
    required this.onDeleteAll,
  });

  final List<AlertItem> alerts;
  final VoidCallback onRefresh;
  final ValueChanged<String> onResolve;
  final ValueChanged<String> onDelete;
  final VoidCallback onResolveAll;
  final VoidCallback onDeleteAll;

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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
        // ── Resolve All / Delete All actions ──
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              if (openCount > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onResolveAll,
                    icon: const Icon(Icons.done_all),
                    label: Text(
                      l10n.t('resolveAll'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (openCount > 0) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onDeleteAll,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(
                    l10n.t('deleteAll'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Alert cards ──
        for (final alert in sortedAlerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AlertCard(
              alert: alert,
              onResolve: onResolve,
              onDelete: onDelete,
            ),
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

class _AlertCard extends ConsumerStatefulWidget {
  const _AlertCard({
    required this.alert,
    required this.onResolve,
    required this.onDelete,
  });

  final AlertItem alert;
  final ValueChanged<String> onResolve;
  final ValueChanged<String> onDelete;

  @override
  ConsumerState<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends ConsumerState<_AlertCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isResolved = widget.alert.isResolved;
    final severityCol = _severityColor(widget.alert.severity, colorScheme);
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    final productsAsync = ref.watch(productsProvider);
    final product = productsAsync.valueOrNull
        ?.where((p) => p.id == widget.alert.productId)
        .firstOrNull;

    final (title, body) = widget.alert.localizedStrings(l10n, lang, product);

    final hotelsAsync = ref.watch(hotelsProvider);
    final hotel = hotelsAsync.valueOrNull
        ?.where((h) => h.id == widget.alert.hotelId)
        .firstOrNull;
    final hotelName = hotel?.name ?? '';

    // Muted opacity for resolved alerts
    final contentOpacity = isResolved ? 0.45 : 1.0;

    return Dismissible(
      key: ValueKey(widget.alert.id),
      direction:
          isResolved ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        widget.onResolve(widget.alert.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check_circle_outline,
            color: Colors.white, size: 28),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        opacity: isResolved ? 0.72 : 1.0,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedScale(
            scale: _isHovered && !isResolved ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isResolved
                      ? [
                          colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.38),
                          colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.2),
                        ]
                      : [
                          colorScheme.surface.withValues(alpha: 0.95),
                          colorScheme.surface.withValues(alpha: 0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: severityCol.withValues(
                      alpha: _isHovered && !isResolved ? 0.3 : 0.0),
                  width: 1.5,
                ),
                boxShadow: isResolved
                    ? null
                    : [
                        BoxShadow(
                          color: severityCol.withValues(
                              alpha: _isHovered ? 0.15 : 0.08),
                          blurRadius: _isHovered ? 24 : 16,
                          offset: Offset(0, _isHovered ? 8 : 4),
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
                          color: severityCol.withValues(
                              alpha: isResolved ? 0.3 : 1.0),
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
                                      _alertTypeIcon(widget.alert.type),
                                      size: 20,
                                      color: severityCol.withValues(
                                          alpha: contentOpacity),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hotelName.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text(
                                              hotelName,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium?.copyWith(
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Time ago
                                  Text(
                                    _timeAgo(widget.alert.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(
                                              alpha: isResolved ? 0.35 : 0.55),
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
                                  body,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                        alpha: isResolved ? 0.35 : 0.72),
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
                                    label:
                                        l10n.alertTypeLabel(widget.alert.type),
                                    backgroundColor: severityCol.withValues(
                                        alpha: isResolved ? 0.05 : 0.08),
                                    textColor: severityCol.withValues(
                                        alpha: contentOpacity),
                                  ),
                                  const SizedBox(width: 8),
                                  // Severity indicator
                                  _PillChip(
                                    label: l10n.tParams('alertsSeverityLabel', {
                                      'severity': '${widget.alert.severity}'
                                    }),
                                    backgroundColor: severityCol.withValues(
                                        alpha: isResolved ? 0.05 : 0.08),
                                    textColor: severityCol.withValues(
                                        alpha: contentOpacity),
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
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
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
                                      onPressed: () =>
                                          widget.onResolve(widget.alert.id),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: l10n.t('delete'),
                                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                                    onPressed: () => widget.onDelete(widget.alert.id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
