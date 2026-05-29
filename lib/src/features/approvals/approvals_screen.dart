import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  static const route = '/approvals';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final canReviewRequests =
        role == UserRole.appAdmin || role == UserRole.appManager;

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.t('approvalsEmpty'),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('approvalsEmptySubtitle'),
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
          children: [
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tParams(
                            'approvalsRequestedBy',
                            {'name': request.requestedByName},
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.tParams(
                                  'approvalsOldValue',
                                  {'value': request.oldValue},
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.tParams(
                                  'approvalsNewValue',
                                  {'value': request.newValue},
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (request.status != ApprovalStatus.pending)
                          _ApprovalStatusBadge(status: request.status)
                        else if (canReviewRequests)
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.check_outlined),
                                label: Text(l10n.t('approvalsApprove')),
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(repositoryProvider)
                                        .approveRequest(
                                          approvalRequestId: request.id,
                                        );
                                    _refreshAfterReview(ref);
                                    if (context.mounted) {
                                      PremiumSnackbar.show(
                                        context,
                                        l10n.t('approvalsApproved'),
                                        icon: Icons.check_circle_outline,
                                      );
                                    }
                                  } catch (e) {
                                    developer.log(
                                      'Approval failed',
                                      error: e,
                                      name: 'ApprovalsScreen',
                                    );
                                    if (context.mounted) {
                                      PremiumSnackbar.show(
                                        context,
                                        _errorMessage(e, l10n),
                                        icon: Icons.error_outline,
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.close_outlined),
                                label: Text(l10n.t('approvalsReject')),
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(repositoryProvider)
                                        .rejectRequest(
                                          approvalRequestId: request.id,
                                        );
                                    _refreshAfterReview(ref);
                                    if (context.mounted) {
                                      PremiumSnackbar.show(
                                        context,
                                        l10n.t('approvalsRejected'),
                                        icon: Icons.info_outline,
                                      );
                                    }
                                  } catch (e) {
                                    developer.log(
                                      'Rejection failed',
                                      error: e,
                                      name: 'ApprovalsScreen',
                                    );
                                    if (context.mounted) {
                                      PremiumSnackbar.show(
                                        context,
                                        _errorMessage(e, l10n),
                                        icon: Icons.error_outline,
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
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
    final (label, color) = switch (status) {
      ApprovalStatus.approved => ('Approved', Colors.green),
      ApprovalStatus.rejected => ('Rejected', theme.colorScheme.error),
      ApprovalStatus.cancelled => ('Cancelled', Colors.orange),
      ApprovalStatus.pending => ('Pending', Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
