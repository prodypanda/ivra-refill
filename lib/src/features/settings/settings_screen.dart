import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/offline/offline_sync_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/biometric_auth.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const route = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final locale = ref.watch(localeProvider);
    final useSupabase = ref.watch(useSupabaseProvider);
    final offlineMode = ref.watch(offlineModeProvider);

    return PageScaffold(
      title: l10n.t('settings'),
      onRefresh: () async {
        ref.invalidate(offlineActionsProvider);
        ref.invalidate(demoUsersProvider);
        await Future.wait([
          ref.read(offlineActionsProvider.future),
          ref.read(demoUsersProvider.future),
        ]);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              _SettingsMobileStatus(useSupabase: useSupabase),
              const SizedBox(height: 16),
            ],
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
            if (!isMobile) ...[
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: Icon(
                    useSupabase
                        ? Icons.cloud_done_outlined
                        : Icons.science_outlined,
                  ),
                  title: Text(useSupabase
                      ? l10n.t('settingsSupabaseConnected')
                      : l10n.t('demoMode')),
                  subtitle: Text(
                    useSupabase
                        ? l10n.t('settingsSupabaseHint')
                        : l10n.t('settingsNoSupabaseHint'),
                  ),
                ),
              ),
            ],
            if (!useSupabase) ...[
              const SizedBox(height: 20),
              const _DemoUserSwitcher(),
            ],
            const SizedBox(height: 20),
            Card(
              elevation: isMobile ? 0 : null,
              shape: isMobile
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    )
                  : null,
              child: SwitchListTile(
                secondary: const Icon(Icons.sync_disabled_outlined),
                title:
                    Text(AppLocalizations.of(context).t('settingsOfflineMode')),
                subtitle: Text(offlineMode
                    ? AppLocalizations.of(context).t('settingsOfflineQueue')
                    : AppLocalizations.of(context).t('settingsOfflineSend')),
                value: offlineMode,
                onChanged: (value) {
                  ref.read(offlineModeProvider.notifier).state = value;
                },
              ),
            ),
            if (useSupabase) ...[
              const SizedBox(height: 20),
              _BiometricSettingTile(isMobile: isMobile),
            ],
            const SizedBox(height: 20),
            AsyncValueView(
              value: ref.watch(offlineActionsProvider),
              onRetry: () => ref.invalidate(offlineActionsProvider),
              builder: (actions) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          final title = Text(
                            AppLocalizations.of(context).tParams(
                              'settingsPendingSync',
                              {'count': actions.length.toString()},
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          );
                          final actionsBar = Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: isNarrow
                                ? WrapAlignment.start
                                : WrapAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: actions.isEmpty
                                    ? null
                                    : () => _clearQueue(context, ref),
                                icon: const Icon(Icons.delete_sweep_outlined),
                                label: Text(
                                  AppLocalizations.of(context).t(
                                    'settingsBtnClear',
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: actions.isEmpty
                                    ? null
                                    : () => _syncQueue(context, ref),
                                icon: const Icon(Icons.sync_outlined),
                                label: Text(
                                  AppLocalizations.of(context).t(
                                    'settingsBtnSyncNow',
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                const SizedBox(height: 8),
                                actionsBar,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: title),
                              const SizedBox(width: 12),
                              actionsBar,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (actions.isEmpty)
                        Text(AppLocalizations.of(context)
                            .t('settingsNoPendingActions'))
                      else
                        Column(
                          children: [
                            for (final action in actions)
                              _OfflineActionTile(
                                action: action,
                                onEdit: () => _resolveAction(
                                  context,
                                  ref,
                                  action,
                                ),
                                onRetry: () =>
                                    _retryAction(context, ref, action.id),
                                onRemove: () =>
                                    _removeAction(context, ref, action.id),
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
        content: Text(didSync
            ? AppLocalizations.of(context).t('settingsActionSynced')
            : AppLocalizations.of(context).t('settingsActionNeedsReview')),
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
      SnackBar(
          content:
              Text(AppLocalizations.of(context).t('settingsActionUpdated'))),
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
      SnackBar(
          content:
              Text(AppLocalizations.of(context).t('settingsActionRemoved'))),
    );
  }

  Future<void> _clearQueue(BuildContext context, WidgetRef ref) async {
    await ref.read(offlineSyncServiceProvider).clear();
    ref.invalidate(offlineActionsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(AppLocalizations.of(context).t('settingsQueueCleared'))),
    );
  }
}

/// Toggle that lets the user enable or disable biometric (fingerprint / face)
/// unlock for the app. The choice is scoped to the currently signed-in account
/// via [biometricAccountProvider], so enabling it for one user no longer leaks
/// the opt-in to a different account that signs in later.
class _BiometricSettingTile extends ConsumerStatefulWidget {
  const _BiometricSettingTile({required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<_BiometricSettingTile> createState() =>
      _BiometricSettingTileState();
}

class _BiometricSettingTileState extends ConsumerState<_BiometricSettingTile> {
  bool? _available;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available =
        await ref.read(biometricAuthServiceProvider).isAvailable();
    if (!mounted) return;
    setState(() => _available = available);
  }

  Future<void> _onChanged(bool value) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = ref.read(currentUserProvider).valueOrNull?.email;

    if (value) {
      if (email == null || email.isEmpty) {
        // Shouldn't happen on the settings screen, but never enable biometric
        // without an account to tie it to.
        return;
      }
      final available = _available ??
          await ref.read(biometricAuthServiceProvider).isAvailable();
      if (!mounted) return;
      if (!available) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('settingsBiometricUnavailable'))),
        );
        return;
      }
      // Confirm with a real biometric check so the user proves the sensor
      // works before we rely on it at login.
      try {
        final ok = await ref
            .read(biometricAuthServiceProvider)
            .authenticate(l10n.t('authBiometricReason'));
        if (!ok) return;
      } catch (_) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('authBiometricFailed'))),
        );
        return;
      }
    }

    await ref
        .read(biometricAccountProvider.notifier)
        .setAccount(value ? email : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final biometricAccount = ref.watch(biometricAccountProvider);
    final currentEmail = ref.watch(currentUserProvider).valueOrNull?.email;
    final enabled = isBiometricEnabledForEmail(biometricAccount, currentEmail);
    final available = _available ?? false;

    return Card(
      elevation: widget.isMobile ? 0 : null,
      shape: widget.isMobile
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            )
          : null,
      child: SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: Text(l10n.t('settingsBiometricTitle')),
        subtitle: Text(
          available
              ? l10n.t('settingsBiometricHint')
              : l10n.t('settingsBiometricUnavailable'),
        ),
        value: enabled && available,
        onChanged: available ? _onChanged : null,
      ),
    );
  }
}

class _SettingsMobileStatus extends StatelessWidget {
  const _SettingsMobileStatus({required this.useSupabase});

  final bool useSupabase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(
          useSupabase ? Icons.cloud_done_outlined : Icons.science_outlined,
          color: colorScheme.primary,
        ),
        title: Text(useSupabase
            ? l10n.t('settingsSupabaseConnected')
            : l10n.t('demoMode')),
        subtitle: Text(
          useSupabase
              ? l10n.t('settingsSupabaseHint')
              : l10n.t('settingsNoSupabaseHint'),
        ),
      ),
    );
  }
}

class _OfflineActionTile extends StatelessWidget {
  const _OfflineActionTile({
    required this.action,
    required this.onEdit,
    required this.onRetry,
    required this.onRemove,
  });

  final OfflineAction action;
  final VoidCallback onEdit;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasError = action.lastError != null;
    final summary = [
      _payloadSummary(action.payload),
      if (action.attemptCount > 0)
        l10n.tParams(
          'settingsActionListAttempts',
          {'count': '${action.attemptCount}'},
        ),
      if (hasError)
        l10n.tParams(
          'settingsActionListError',
          {'message': '${action.lastError}'},
        ),
    ].join('\n');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      isThreeLine: summary.contains('\n'),
      leading: Icon(
        hasError ? Icons.error_outline : Icons.pending_actions,
        color: hasError ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(l10n.syncActionTypeLabel(action.type)),
      subtitle: Text(summary),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: hasError
                ? l10n.t('settingsResolveConflict')
                : l10n.t('settingsEditAction'),
            icon: Icon(
              hasError ? Icons.tune_outlined : Icons.edit_note_outlined,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: l10n.t('settingsRetryAction'),
            icon: const Icon(Icons.sync_outlined),
            onPressed: onRetry,
          ),
          IconButton(
            tooltip: l10n.t('settingsRemoveAction'),
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
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
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return AsyncValueView(
      value: ref.watch(demoUsersProvider),
      onRetry: () => ref.invalidate(demoUsersProvider),
      builder: (users) => Card(
        elevation: isMobile ? 0 : null,
        shape: isMobile
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              )
            : null,
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
                isExpanded: true,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).t('settingsTestAccessAs'),
                  prefixIcon: Icon(Icons.manage_accounts_outlined),
                ),
                items: [
                  for (final user in users)
                    DropdownMenuItem(
                      value: user.id,
                      child: Text(
                        '${user.fullName} (${AppLocalizations.of(context).userRoleLabel(user.role)})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  PremiumSnackbar.showSuccess(
                    context, 
                    AppLocalizations.of(context).t('settingsDemoUserChanged'),
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
                  labelText:
                      AppLocalizations.of(context).t('settingsPayloadJson'),
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
