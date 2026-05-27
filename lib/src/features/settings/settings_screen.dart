import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/offline/offline_sync_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const route = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final useSupabase = ref.watch(useSupabaseProvider);
    final offlineMode = ref.watch(offlineModeProvider);

    return PageScaffold(
      title: l10n.t('settings'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Locale>(
              initialValue: locale,
              decoration: InputDecoration(labelText: l10n.t('language')),
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                DropdownMenuItem(value: Locale('it'), child: Text('Italiano')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).state = value;
                }
              },
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: Icon(
                  useSupabase
                      ? Icons.cloud_done_outlined
                      : Icons.science_outlined,
                ),
                title: Text(
                    useSupabase ? l10n.t('settingsSupabaseConnected') : l10n.t('demoMode')),
                subtitle: Text(
                  useSupabase
                      ? l10n.t('settingsSupabaseHint')
                      : l10n.t('settingsNoSupabaseHint'),
                ),
              ),
            ),
            if (!useSupabase) ...[
              const SizedBox(height: 20),
              const _DemoUserSwitcher(),
            ],
            const SizedBox(height: 20),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.sync_disabled_outlined),
                title: Text(AppLocalizations.of(context).t('settingsOfflineMode')),
                subtitle: Text(offlineMode ? AppLocalizations.of(context).t('settingsOfflineQueue') : AppLocalizations.of(context).t('settingsOfflineSend')),
                value: offlineMode,
                onChanged: (value) {
                  ref.read(offlineModeProvider.notifier).state = value;
                },
              ),
            ),
            const SizedBox(height: 20),
            AsyncValueView(
              value: ref.watch(offlineActionsProvider),
              builder: (actions) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pending sync (${actions.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: actions.isEmpty
                                ? null
                                : () => _clearQueue(context, ref),
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: Text(AppLocalizations.of(context).t('settingsBtnClear')),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: actions.isEmpty
                                ? null
                                : () => _syncQueue(context, ref),
                            icon: const Icon(Icons.sync_outlined),
                            label: Text(AppLocalizations.of(context).t('settingsBtnSyncNow')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (actions.isEmpty)
                        Text(AppLocalizations.of(context).t('settingsNoPendingActions'))
                      else
                        Column(
                          children: [
                            for (final action in actions)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  action.lastError == null
                                      ? Icons.pending_actions
                                      : Icons.error_outline,
                                  color: action.lastError == null
                                      ? null
                                      : Theme.of(context).colorScheme.error,
                                ),
                                title:
                                    Text(l10n.syncActionTypeLabel(action.type)),
                                subtitle: Text(
                                  [
                                    _payloadSummary(action.payload),
                                    if (action.attemptCount > 0)
                                      l10n.tParams(
                                        'settingsActionListAttempts',
                                        {'count': '${action.attemptCount}'},
                                      ),
                                    if (action.lastError != null)
                                      l10n.tParams(
                                        'settingsActionListError',
                                        {'message': '${action.lastError}'},
                                      ),
                                  ].join('\n'),
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: action.lastError == null
                                          ? l10n.t('settingsEditAction')
                                          : l10n.t('settingsResolveConflict'),
                                      icon: Icon(
                                        action.lastError == null
                                            ? Icons.edit_note_outlined
                                            : Icons.tune_outlined,
                                      ),
                                      onPressed: () => _resolveAction(
                                        context,
                                        ref,
                                        action,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.t('settingsRetryAction'),
                                      icon: const Icon(Icons.sync_outlined),
                                      onPressed: () =>
                                          _retryAction(context, ref, action.id),
                                    ),
                                    IconButton(
                                      tooltip: l10n.t('settingsRemoveAction'),
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _removeAction(
                                          context, ref, action.id),
                                    ),
                                  ],
                                ),
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

  Future<void> _syncQueue(BuildContext context, WidgetRef ref) async {
    final summary = await ref
        .read(offlineSyncServiceProvider)
        .syncPendingDetailed(ref.read(repositoryProvider));

    ref.invalidate(offlineActionsProvider);
    ref.invalidate(roomProductsProvider);
    ref.invalidate(refillEventsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(suggestedOrdersProvider);
    ref.invalidate(approvalsProvider);
    ref.invalidate(dashboardProvider);

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final String message;
    if (summary.hasFailures) {
      message = l10n.tParams(
        'settingsSyncedWithFailures',
        {'synced': '${summary.synced}', 'failed': '${summary.failed}'},
      );
    } else {
      message = l10n.tParams(
        summary.synced == 1
            ? 'settingsSyncedSummarySingular'
            : 'settingsSyncedSummary',
        {'synced': '${summary.synced}'},
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _retryAction(
    BuildContext context,
    WidgetRef ref,
    String actionId,
  ) async {
    final didSync = await ref
        .read(offlineSyncServiceProvider)
        .syncAction(ref.read(repositoryProvider), actionId);

    ref.invalidate(offlineActionsProvider);
    ref.invalidate(roomProductsProvider);
    ref.invalidate(refillEventsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(suggestedOrdersProvider);
    ref.invalidate(approvalsProvider);
    ref.invalidate(dashboardProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(didSync ? AppLocalizations.of(context).t('settingsActionSynced') : AppLocalizations.of(context).t('settingsActionNeedsReview')),
      ),
    );
  }

  Future<void> _resolveAction(
    BuildContext context,
    WidgetRef ref,
    OfflineAction action,
  ) async {
    final result = await showDialog<_ResolvedOfflinePayload>(
      context: context,
      builder: (context) => _OfflineConflictDialog(action: action),
    );
    if (result == null) return;

    await ref
        .read(offlineSyncServiceProvider)
        .updatePayload(action.id, result.payload);
    ref.invalidate(offlineActionsProvider);

    if (!context.mounted) return;
    if (result.retryAfterSave) {
      await _retryAction(context, ref, action.id);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('settingsActionUpdated'))),
    );
  }

  Future<void> _removeAction(
    BuildContext context,
    WidgetRef ref,
    String actionId,
  ) async {
    await ref.read(offlineSyncServiceProvider).remove(actionId);
    ref.invalidate(offlineActionsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('settingsActionRemoved'))),
    );
  }

  Future<void> _clearQueue(BuildContext context, WidgetRef ref) async {
    await ref.read(offlineSyncServiceProvider).clear();
    ref.invalidate(offlineActionsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('settingsQueueCleared'))),
    );
  }

  String _payloadSummary(Map<String, dynamic> payload) {
    final entries = payload.entries.take(3).map(
          (entry) => '${entry.key}: ${entry.value}',
        );
    return entries.join(', ');
  }
}

class _DemoUserSwitcher extends ConsumerWidget {
  const _DemoUserSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return AsyncValueView(
      value: ref.watch(demoUsersProvider),
      builder: (users) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).t('settingsDemoUser'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: currentUser?.id,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).t('settingsTestAccessAs'),
                  prefixIcon: Icon(Icons.manage_accounts_outlined),
                ),
                items: [
                  for (final user in users)
                    DropdownMenuItem(
                      value: user.id,
                      child: Text(
                        '${user.fullName} (${AppLocalizations.of(context).userRoleLabel(user.role)})',
                      ),
                    ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  await ref
                      .read(repositoryProvider)
                      .switchDemoUser(userId: value);
                  _refreshAppData(ref);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('settingsDemoUserChanged'))),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _refreshAppData(WidgetRef ref) {
  ref.invalidate(currentUserProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(suggestedOrdersProvider);
  ref.invalidate(approvalsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(teamMembersProvider);
  ref.invalidate(teamInvitationsProvider);
  ref.invalidate(demoUsersProvider);
}

class _OfflineConflictDialog extends StatefulWidget {
  const _OfflineConflictDialog({required this.action});

  final OfflineAction action;

  @override
  State<_OfflineConflictDialog> createState() => _OfflineConflictDialogState();
}

class _OfflineConflictDialogState extends State<_OfflineConflictDialog> {
  late final TextEditingController _payloadController;
  String? _error;

  @override
  void initState() {
    super.initState();
    const encoder = JsonEncoder.withIndent('  ');
    _payloadController = TextEditingController(
      text: encoder.convert(widget.action.payload),
    );
  }

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context).t(
          widget.action.lastError == null
              ? 'settingsActionEditTitle'
              : 'settingsActionConflictTitle',
        ),
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      AppLocalizations.of(context)
                          .syncActionTypeLabel(widget.action.type),
                    ),
                  ),
                  Chip(
                    label: Text(
                      AppLocalizations.of(context).tParams(
                        'settingsActionAttempts',
                        {'count': '${widget.action.attemptCount}'},
                      ),
                    ),
                  ),
                  if (widget.action.lastAttemptAt != null)
                    Chip(
                      label: Text(
                        AppLocalizations.of(context).tParams(
                          'settingsActionLastTried',
                          {
                            'datetime':
                                _formatDateTime(widget.action.lastAttemptAt!)
                          },
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.action.lastError != null) ...[
                const SizedBox(height: 14),
                Text(
                  widget.action.lastError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _payloadController,
                minLines: 8,
                maxLines: 14,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).t('settingsPayloadJson'),
                  alignLabelWithHint: true,
                  errorText: _error,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).t('btnCancel')),
        ),
        TextButton.icon(
          onPressed: () => _submit(retryAfterSave: false),
          icon: const Icon(Icons.save_outlined),
          label: Text(AppLocalizations.of(context).t('btnSave')),
        ),
        FilledButton.icon(
          onPressed: () => _submit(retryAfterSave: true),
          icon: const Icon(Icons.sync_outlined),
          label: Text(AppLocalizations.of(context).t('settingsSaveAndRetry')),
        ),
      ],
    );
  }

  void _submit({required bool retryAfterSave}) {
    final payload = _parsePayload();
    if (payload == null) return;
    Navigator.of(context).pop(
      _ResolvedOfflinePayload(
        payload: payload,
        retryAfterSave: retryAfterSave,
      ),
    );
  }

  Map<String, dynamic>? _parsePayload() {
    try {
      final decoded = jsonDecode(_payloadController.text);
      if (decoded is! Map) {
        setState(() => _error =
            AppLocalizations.of(context).t('settingsPayloadInvalidJson'));
        return null;
      }
      setState(() => _error = null);
      return Map<String, dynamic>.from(decoded);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return null;
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _ResolvedOfflinePayload {
  const _ResolvedOfflinePayload({
    required this.payload,
    required this.retryAfterSave,
  });

  final Map<String, dynamic> payload;
  final bool retryAfterSave;
}
