import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../app/theme.dart';
import '../shared/async_value_view.dart';
import '../shared/empty_state.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  static const route = '/approvals';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReviewRequests = ref.watch(hasPermissionProvider('approve_corrections'));

    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.t('approvals'),
      onRefresh: () async {
        ref.invalidate(approvalsProvider);
        await ref.read(approvalsProvider.future);
      },
      child: AsyncValueView(
        value: ref.watch(approvalsProvider),
        onRetry: () => ref.invalidate(approvalsProvider),
        builder: (requests) {
          if (requests.isEmpty) {
            return EmptyState(
              icon: Icons.fact_check_outlined,
              title: l10n.t('approvalsEmpty'),
              message: l10n.t('approvalsEmptySubtitle'),
            );
          }
          return Column(
          children: [
            for (var i = 0; i < requests.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(requests[i].id),
                  direction: (canReviewRequests && requests[i].status == ApprovalStatus.pending)
                      ? DismissDirection.horizontal
                      : DismissDirection.none,
                  background: Container(
                    decoration: BoxDecoration(
                      color: themeExt?.success ?? Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 28),
                  ),
                  onDismissed: (direction) async {
                    HapticFeedback.lightImpact();
                    try {
                      if (direction == DismissDirection.startToEnd) {
                        await ref.read(repositoryProvider).approveRequest(approvalRequestId: requests[i].id);
                        if (context.mounted) PremiumSnackbar.show(context, l10n.t('approvalsApproved'), icon: Icons.check_circle_outline);
                      } else {
                        await ref.read(repositoryProvider).rejectRequest(approvalRequestId: requests[i].id);
                        if (context.mounted) PremiumSnackbar.show(context, l10n.t('approvalsRejected'), icon: Icons.info_outline);
                      }
                      _refreshAfterReview(ref);
                    } catch (e) {
                      if (context.mounted) PremiumSnackbar.show(context, _errorMessage(e, l10n), icon: Icons.error_outline, isError: true);
                      _refreshAfterReview(ref);
                    }
                  },
                  child: _ApprovalCard(
                    staggerIndex: i,
                    request: requests[i],
                    canReviewRequests: canReviewRequests,
                    onApprove: () async {
                      try {
                        await ref.read(repositoryProvider).approveRequest(approvalRequestId: requests[i].id);
                        _refreshAfterReview(ref);
                        if (context.mounted) {
                          PremiumSnackbar.show(context, l10n.t('approvalsApproved'), icon: Icons.check_circle_outline);
                        }
                      } catch (e) {
                        developer.log('Approval failed', error: e, name: 'ApprovalsScreen');
                        if (context.mounted) {
                          PremiumSnackbar.show(context, _errorMessage(e, l10n), icon: Icons.error_outline, isError: true);
                        }
                      }
                    },
                    onReject: () async {
                      try {
                        await ref.read(repositoryProvider).rejectRequest(approvalRequestId: requests[i].id);
                        _refreshAfterReview(ref);
                        if (context.mounted) {
                          PremiumSnackbar.show(context, l10n.t('approvalsRejected'), icon: Icons.info_outline);
                        }
                      } catch (e) {
                        developer.log('Rejection failed', error: e, name: 'ApprovalsScreen');
                        if (context.mounted) {
                          PremiumSnackbar.show(context, _errorMessage(e, l10n), icon: Icons.error_outline, isError: true);
                        }
                      }
                    },
                  ),
                ),
              ),
          ],
        );
        },
      ),
    );
  }
}

void _refreshAfterReview(WidgetRef ref) {
  ref.invalidate(approvalsProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(suggestedOrdersProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);
}

class _ApprovalStatusBadge extends StatelessWidget {
  const _ApprovalStatusBadge({required this.status});

  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      ApprovalStatus.approved => themeExt?.success ?? Colors.green,
      ApprovalStatus.rejected => theme.colorScheme.error,
      ApprovalStatus.cancelled => themeExt?.warning ?? Colors.orange,
      ApprovalStatus.pending => themeExt?.info ?? Colors.blue,
    };
    final label = l10n.approvalStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String _errorMessage(Object error, AppLocalizations l10n) {
  final raw = error.toString();
  if (raw.contains('Access denied')) {
    return l10n.t('approvalsAccessDenied');
  }
  if (raw.contains('not found')) {
    return l10n.t('approvalsRequestNotFound');
  }
  return '${l10n.t('approvalsActionFailed')} ($raw)';
}

class _ApprovalCard extends StatefulWidget {
  const _ApprovalCard({
    required this.request,
    required this.canReviewRequests,
    required this.onApprove,
    required this.onReject,
    this.staggerIndex = 0,
  });

  final ApprovalRequest request;
  final bool canReviewRequests;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final int staggerIndex;

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final successColor = themeExt?.success ?? Colors.green;
    final onSuccessColor = themeExt?.onSuccess ?? Colors.white;
    final request = widget.request;
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final cappedIndex = widget.staggerIndex.clamp(0, 6);

    return TweenAnimationBuilder<double>(
      key: ValueKey('approval_${request.id}'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: disableAnim
          ? Duration.zero
          : Duration(milliseconds: 280 + (cappedIndex * 35)),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - anim)),
          child: Opacity(
            opacity: anim,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: _isHovered ? 0.15 : 0.0),
                blurRadius: _isHovered ? 20 : 0,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderColor: theme.colorScheme.primary.withValues(alpha: _isHovered ? 0.4 : 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.compare_arrows_outlined, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            l10n.tParams('approvalsRequestedBy', {'name': request.requestedByName}),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('approvalsOldValue'),
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                            ),
                            Text(
                              request.oldValue,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('approvalsNewValue'),
                              style: theme.textTheme.labelSmall?.copyWith(color: successColor),
                            ),
                            Text(
                              request.newValue,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (request.status != ApprovalStatus.pending)
                  _ApprovalStatusBadge(status: request.status)
                else if (widget.canReviewRequests)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.close_outlined),
                        label: Text(l10n.t('approvalsReject')),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: widget.onReject,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.check_outlined),
                        label: Text(l10n.t('approvalsApprove')),
                        style: FilledButton.styleFrom(
                          backgroundColor: successColor,
                          foregroundColor: onSuccessColor,
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: widget.onApprove,
                      ),
                    ],
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

