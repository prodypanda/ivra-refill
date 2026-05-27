import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

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
      child: AsyncValueView(
        value: ref.watch(approvalsProvider),
        builder: (requests) => Column(
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
                        if (canReviewRequests)
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.check_outlined),
                                label: Text(l10n.t('approvalsApprove')),
                                onPressed: () async {
                                  await ref
                                      .read(repositoryProvider)
                                      .approveRequest(
                                        approvalRequestId: request.id,
                                      );
                                  _refreshAfterReview(ref);
                                },
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.close_outlined),
                                label: Text(l10n.t('approvalsReject')),
                                onPressed: () async {
                                  await ref
                                      .read(repositoryProvider)
                                      .rejectRequest(
                                        approvalRequestId: request.id,
                                      );
                                  _refreshAfterReview(ref);
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
        ),
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
