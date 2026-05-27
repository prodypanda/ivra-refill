import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/premium_snackbar.dart';

/// A provider that tracks whether the device currently has internet connectivity.
/// It pings the Supabase host periodically to verify real connectivity.
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _startChecking();
  }

  Timer? _timer;

  void _startChecking() {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  Future<void> _check() async {
    try {
      if (kIsWeb) {
        // On web, we can't use InternetAddress.lookup.
        // Instead, just trust the browser's online status via a simple fetch.
        // The _fetchWithCache mechanism already handles web offline errors.
        state = true;
      } else {
        final result = await InternetAddress.lookup('tozmdkasyzdzrbhvfxis.supabase.co')
            .timeout(const Duration(seconds: 5));
        state = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } on SocketException {
      state = false;
    } on TimeoutException {
      state = false;
    } catch (_) {
      state = false;
    }
  }

  /// Force a re-check now (e.g. after user taps "Sync").
  Future<void> recheck() => _check();

  @override
  void dispose() {
    _timer?.cancel();
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
  bool _wasOffline = false;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = ref.watch(connectivityProvider);
    final pendingAsync = ref.watch(offlineActionsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final hasManualOffline = ref.watch(offlineModeProvider);

    final isEffectivelyOffline = !isOnline || hasManualOffline;

    // Auto-sync when coming back online
    if (_wasOffline && isOnline && !hasManualOffline && pendingCount > 0) {
      _wasOffline = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSync(pendingCount);
      });
    }

    _wasOffline = isEffectivelyOffline;

    // Don't show anything if online and no pending actions
    if (!isEffectivelyOffline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Material(
          elevation: 2,
          shadowColor: const Color(0xFF92400E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          color: isEffectivelyOffline
              ? const Color(0xFFFFF3E0) // warm amber for offline
              : const Color(0xFFE8F5E9), // soft green for "pending but online"
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                isEffectivelyOffline
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_sync_outlined,
                size: 20,
                color: isEffectivelyOffline
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEffectivelyOffline
                          ? l10n.t('offlineBannerTitle')
                          : l10n.t('settingsPendingSync'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isEffectivelyOffline
                            ? const Color(0xFFE65100)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      isEffectivelyOffline
                          ? '${l10n.t('offlineBannerSubtitle')}${pendingCount > 0 ? ' • $pendingCount ${l10n.t('offlineBannerPending')}' : ''}'
                          : '$pendingCount ${l10n.t('offlineBannerPending')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isEffectivelyOffline
                            ? const Color(0xFFBF360C)
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingCount > 0 && isOnline && !hasManualOffline)
                _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: () => _manualSync(),
                        icon: const Icon(Icons.sync, size: 16),
                        label: Text(
                          l10n.t('offlineBannerSyncBtn'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
            ],
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
            l10n.t('offlineBannerAutoSynced').replaceAll('{count}', '${summary.synced}'),
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
        } else {
          PremiumSnackbar.show(
            context,
            l10n.t('offlineBannerAutoSynced').replaceAll('{count}', '${summary.synced}'),
            icon: Icons.cloud_done_outlined,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
