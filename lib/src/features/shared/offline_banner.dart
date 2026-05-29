import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/premium_snackbar.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

String? _supabaseHostFromEnv() {
  if (_supabaseUrl.isEmpty) return null;
  try {
    final uri = Uri.parse(_supabaseUrl);
    if (uri.host.isEmpty) return null;
    return uri.host;
  } catch (_) {
    return null;
  }
}

/// A provider that tracks whether the device currently has internet connectivity.
/// On native platforms it periodically resolves the configured Supabase host;
/// when no host is configured (e.g. demo mode or tests) it stays optimistically
/// online and is only updated by explicit `recheck()` calls.
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(host: _supabaseHostFromEnv()),
);

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier({
    String? host,
    Duration pollInterval = const Duration(seconds: 30),
    Duration lookupTimeout = const Duration(seconds: 5),
  })  : _host = host,
        _pollInterval = pollInterval,
        _lookupTimeout = lookupTimeout,
        super(true) {
    if (_host != null && !kIsWeb) {
      // Kick off an immediate check so the offline banner appears quickly
      // when the device is offline at app launch, in addition to the periodic
      // poll.
      _check();
      _timer = Timer.periodic(_pollInterval, (_) => _check());
    }
  }

  final String? _host;
  final Duration _pollInterval;
  final Duration _lookupTimeout;
  Timer? _timer;
  Timer? _timeoutTimer;
  bool _disposed = false;

  Future<void> _check() async {
    if (_disposed) return;
    final host = _host;
    if (host == null || kIsWeb) return;

    final completer = Completer<bool>();
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_lookupTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });
    InternetAddress.lookup(host).then((result) {
      if (completer.isCompleted) return;
      completer.complete(
        result.isNotEmpty && result.first.rawAddress.isNotEmpty,
      );
    }).catchError((_) {
      if (!completer.isCompleted) completer.complete(false);
    });

    final reachable = await completer.future;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (_disposed || !mounted) return;
    state = reachable;
  }

  /// Force a re-check now (e.g. after user taps "Sync").
  Future<void> recheck() => _check();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    super.dispose();
  }
}

/// A persistent banner shown at the top of the app shell when the user
/// is offline or has pending sync actions.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = ref.watch(connectivityProvider);
    final pendingAsync = ref.watch(offlineActionsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final hasManualOffline = ref.watch(offlineModeProvider);

    final isEffectivelyOffline = !isOnline || hasManualOffline;

    // Auto-sync when coming back online. Triggering this from `ref.listen`
    // (and not from inline build-time state mutation) keeps the build pure
    // and avoids spurious rebuilds being interpreted as connectivity
    // transitions — for example, when the pending-actions list changes
    // while we are still offline.
    ref.listen<bool>(connectivityProvider, (previous, next) {
      final wasOffline = previous == false;
      final isNowOnline = next == true;
      if (wasOffline &&
          isNowOnline &&
          !ref.read(offlineModeProvider) &&
          (ref.read(offlineActionsProvider).valueOrNull?.length ?? 0) > 0) {
        final count =
            ref.read(offlineActionsProvider).valueOrNull?.length ?? 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoSync(count);
        });
      }
    });
    ref.listen<bool>(offlineModeProvider, (previous, next) {
      final wasManualOffline = previous == true;
      final isNoLongerManualOffline = next == false;
      if (wasManualOffline &&
          isNoLongerManualOffline &&
          ref.read(connectivityProvider) == true &&
          (ref.read(offlineActionsProvider).valueOrNull?.length ?? 0) > 0) {
        final count =
            ref.read(offlineActionsProvider).valueOrNull?.length ?? 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoSync(count);
        });
      }
    });

    // Don't show anything if online and no pending actions
    if (!isEffectivelyOffline && pendingCount == 0) {
      return const SizedBox.shrink();
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Material(
            elevation: 2,
            shadowColor: const Color(0xFF92400E).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            color: isEffectivelyOffline
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEffectivelyOffline
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_sync_outlined,
                    size: 16,
                    color: isEffectivelyOffline
                        ? const Color(0xFFE65100)
                        : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEffectivelyOffline
                        ? l10n.t('offlineBannerTitle')
                        : l10n.tParams(
                            'settingsPendingSync',
                            {'count': pendingCount.toString()},
                          ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isEffectivelyOffline
                          ? const Color(0xFFE65100)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                  if (pendingCount > 0 && isOnline && !hasManualOffline) ...[
                    const SizedBox(width: 12),
                    if (_isSyncing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      InkWell(
                        onTap: _manualSync,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.sync, size: 16, color: Color(0xFF2E7D32)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _autoSync(int expectedCount) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(offlineSyncServiceProvider);
      final repo = ref.read(repositoryProvider);
      final summary = await syncService.syncPendingDetailed(repo);

      ref.invalidate(offlineActionsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(alertsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (summary.hasFailures) {
          PremiumSnackbar.show(
            context,
            l10n.t('offlineBannerSyncFailed'),
            icon: Icons.warning_amber_outlined,
          );
        } else if (summary.synced > 0) {
          PremiumSnackbar.show(
            context,
            l10n.tParams(
              'offlineBannerAutoSynced',
              {'count': '${summary.synced}'},
            ),
            icon: Icons.cloud_done_outlined,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _manualSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(offlineSyncServiceProvider);
      final repo = ref.read(repositoryProvider);
      final summary = await syncService.syncPendingDetailed(repo);

      ref.invalidate(offlineActionsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(alertsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (summary.hasFailures) {
          PremiumSnackbar.show(
            context,
            l10n.t('offlineBannerSyncFailed'),
            icon: Icons.warning_amber_outlined,
          );
        } else if (summary.synced > 0) {
          PremiumSnackbar.show(
            context,
            l10n.tParams(
              'offlineBannerAutoSynced',
              {'count': '${summary.synced}'},
            ),
            icon: Icons.cloud_done_outlined,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
