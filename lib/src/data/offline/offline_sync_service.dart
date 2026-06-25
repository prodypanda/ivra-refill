import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/app_enums.dart';
import '../ivra_repository.dart';
import 'network_error_classifier.dart';

class OfflineAction {
  const OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
    this.isDeadLetter = false,
  });

  /// Maximum number of automatic attempts before an action is moved to the
  /// dead-letter (needs manual review) terminal state.
  static const int maxAttempts = 5;

  /// Base interval used for exponential backoff between transient failures.
  static const Duration backoffBase = Duration(seconds: 30);

  /// Upper bound for the backoff interval.
  static const Duration backoffCap = Duration(minutes: 10);

  final String id;
  final SyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;

  /// When true, the action has either exhausted its retries or hit a permanent
  /// error. It will be skipped by automatic sync passes and surfaced for manual
  /// retry/remove instead.
  final bool isDeadLetter;

  /// Alias kept for readability at call sites that think in terms of a terminal
  /// state rather than the dead-letter queue.
  bool get isTerminal => isDeadLetter;

  /// Alias kept for readability at call sites that think in terms of manual
  /// review controls in the Settings screen.
  bool get needsReview => isDeadLetter;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'attempt_count': attemptCount,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'last_error': lastError,
        'is_dead_letter': isDeadLetter,
      };

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'] as String,
      type: SyncActionType.values.firstWhere(
        (item) => item.value == json['type'],
        orElse: () => SyncActionType.refill,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      attemptCount: (json['attempt_count'] ?? 0) as int,
      lastAttemptAt: json['last_attempt_at'] == null
          ? null
          : DateTime.parse(json['last_attempt_at'] as String),
      lastError: json['last_error'] as String?,
      isDeadLetter: (json['is_dead_letter'] ?? false) as bool,
    );
  }

  OfflineAction copyWith({
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? lastError,
    bool? isDeadLetter,
    Map<String, dynamic>? payload,
  }) {
    return OfflineAction(
      id: id,
      type: type,
      payload: payload ?? this.payload,
      createdAt: createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      isDeadLetter: isDeadLetter ?? this.isDeadLetter,
    );
  }

  /// Records a failed attempt. When [permanent] is true, or when the attempt
  /// count reaches [maxAttempts], the action is moved into the dead-letter
  /// terminal state instead of remaining retriable.
  OfflineAction failedWith(String error, {bool permanent = false}) {
    final nextAttemptCount = attemptCount + 1;
    final exhausted = nextAttemptCount >= maxAttempts;
    return OfflineAction(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      attemptCount: nextAttemptCount,
      lastAttemptAt: DateTime.now(),
      lastError: error,
      isDeadLetter: permanent || exhausted,
    );
  }

  /// Resets a dead-lettered action so a manual retry can attempt it again.
  /// Backoff/attempt history is cleared so the manual pass is not skipped.
  OfflineAction reactivated() {
    return OfflineAction(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      attemptCount: 0,
      lastAttemptAt: null,
      lastError: null,
      isDeadLetter: false,
    );
  }

  OfflineAction resolvedWith(Map<String, dynamic> updatedPayload) {
    return OfflineAction(
      id: id,
      type: type,
      payload: updatedPayload,
      createdAt: createdAt,
      attemptCount: attemptCount,
    );
  }

  /// Exponential backoff window for the current attempt count:
  /// `backoffBase * 2^(attemptCount - 1)`, capped at [backoffCap].
  Duration get backoffDuration {
    if (attemptCount <= 0) return Duration.zero;
    final multiplier = math.pow(2, attemptCount - 1).toInt();
    final millis = backoffBase.inMilliseconds * multiplier;
    if (millis >= backoffCap.inMilliseconds || millis < 0) {
      return backoffCap;
    }
    return Duration(milliseconds: millis);
  }

  /// True when the action is still within its transient-failure backoff window
  /// relative to [now] and should be skipped by an automatic sync pass.
  bool isInBackoff([DateTime? now]) {
    if (isDeadLetter) return false;
    final last = lastAttemptAt;
    if (last == null) return false;
    final readyAt = last.add(backoffDuration);
    return (now ?? DateTime.now()).isBefore(readyAt);
  }
}

class OfflineSyncSummary {
  const OfflineSyncSummary({
    required this.synced,
    required this.failed,
  });

  final int synced;
  final int failed;

  bool get hasFailures => failed > 0;
}

class OfflineSyncService {
  static const _storageKey = 'ivra_offline_actions';
  final _uuid = const Uuid();

  Future<List<OfflineAction>> pendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences caches values in memory per isolate and does not
    // refetch from disk on getInstance(). The workmanager background isolate
    // and the UI isolate each hold their own cache, so without an explicit
    // reload one isolate can read stale data and clobber the other's queue
    // (silently dropping queued refills). Reload before every read.
    await prefs.reload();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    return raw
        .map((item) => OfflineAction.fromJson(jsonDecode(item)))
        .toList(growable: false);
  }

  Future<void> enqueue({
    required SyncActionType type,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final actions = prefs.getStringList(_storageKey) ?? <String>[];
    final action = OfflineAction(
      id: _uuid.v4(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    actions.add(jsonEncode(action.toJson()));
    await prefs.setStringList(_storageKey, actions);
  }

  Future<void> remove(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    // Reload and re-derive the list from this same reloaded instance so a
    // concurrent isolate's write is not overwritten with a stale snapshot.
    await prefs.reload();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    final actions =
        raw.map((item) => OfflineAction.fromJson(jsonDecode(item))).toList();
    await prefs.setStringList(
      _storageKey,
      actions
          .where((action) => action.id != actionId)
          .map((action) => jsonEncode(action.toJson()))
          .toList(),
    );
  }

  Future<void> updatePayload(
    String actionId,
    Map<String, dynamic> payload,
  ) async {
    final actions = await pendingActions();
    for (final action in actions) {
      if (action.id == actionId) {
        await _replace(action.resolvedWith(payload));
        return;
      }
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Reload before clearing so we observe (and intentionally discard) the
    // latest on-disk queue rather than acting on a stale per-isolate cache.
    // Keeps clear() consistent with enqueue/remove/_replace under the
    // workmanager + UI multi-isolate setup.
    await prefs.reload();
    await prefs.remove(_storageKey);
  }

  /// Actions that have reached a terminal dead-letter state and require manual
  /// review (retry/remove) from the Settings screen.
  Future<List<OfflineAction>> deadLetterActions() async {
    final actions = await pendingActions();
    return actions.where((action) => action.isDeadLetter).toList(growable: false);
  }

  Future<int> syncPending(IvraRepository repository) async {
    final summary = await syncPendingDetailed(repository);
    return summary.synced;
  }

  Future<OfflineSyncSummary> syncPendingDetailed(
    IvraRepository repository,
  ) async {
    final actions = await pendingActions();
    var synced = 0;
    var failed = 0;

    for (final action in actions) {
      // Skip terminal/dead-letter actions: they are surfaced separately for
      // manual retry/remove and must not be counted as freshly failed.
      if (action.isDeadLetter) continue;
      // Respect the transient-failure backoff window during automatic passes.
      if (action.isInBackoff()) continue;

      final didSync = await syncAction(repository, action.id);
      if (didSync) {
        synced += 1;
      } else {
        failed += 1;
      }
    }

    return OfflineSyncSummary(synced: synced, failed: failed);
  }

  /// Resets a dead-lettered action and immediately attempts it again. Used by
  /// the Settings screen's manual retry control; bypasses the backoff window.
  Future<bool> retryDeadLetterAction(
    IvraRepository repository,
    String actionId,
  ) async {
    final actions = await pendingActions();
    for (final action in actions) {
      if (action.id == actionId && action.isDeadLetter) {
        await _replace(action.reactivated());
        break;
      }
    }
    return syncAction(repository, actionId, manual: true);
  }

  /// Attempts a single queued action.
  ///
  /// [manual] indicates a user-triggered retry, which bypasses the backoff
  /// window. Automatic passes skip actions that are dead-lettered or still
  /// within their backoff window.
  Future<bool> syncAction(
    IvraRepository repository,
    String actionId, {
    bool manual = false,
  }) async {
    final actions = await pendingActions();
    OfflineAction? action;
    for (final item in actions) {
      if (item.id == actionId) action = item;
    }

    if (action == null) return false;

    if (!manual) {
      // Do not auto-attempt terminal actions or ones still in backoff.
      if (action.isDeadLetter) return false;
      if (action.isInBackoff()) return false;
    }

    try {
      await _perform(repository, action);
      await remove(action.id);
      return true;
    } on Object catch (error) {
      final permanent = NetworkErrorClassifier.isPermanent(error);
      await _replace(action.failedWith(error.toString(), permanent: permanent));
      return false;
    }
  }

  Future<void> _perform(
    IvraRepository repository,
    OfflineAction action,
  ) async {
    final payload = action.payload;
    switch (action.type) {
      case SyncActionType.refill:
        await repository.recordRefill(
          roomProductId: payload['roomProductId'] as String,
          notes: payload['notes'] as String?,
          clientRequestId: action.id,
        );
      case SyncActionType.undoRefill:
        await repository.undoRefill(
          refillEventId: payload['refillEventId'] as String,
          clientRequestId: action.id,
        );
      case SyncActionType.correctionRequest:
        await repository.requestCorrection(
          refillEventId: payload['refillEventId'] as String,
          reason: payload['reason'] as String,
          clientRequestId: action.id,
        );
      case SyncActionType.bottleReplacement:
        await repository.replaceBottle(
          roomProductId: payload['roomProductId'] as String,
          notes: payload['notes'] as String?,
          clientRequestId: action.id,
          autoAdjustInventory: payload['autoAdjustInventory'] == true,
        );
      case SyncActionType.stockAdjustment:
        await repository.recordStockAdjustment(
          hotelId: payload['hotelId'] as String,
          productId: payload['productId'] as String,
          fullBottlesDelta: (payload['fullBottlesDelta'] ?? 0) as int,
          emptyBottlesDelta: (payload['emptyBottlesDelta'] ?? 0) as int,
          fullBidonsDelta: (payload['fullBidonsDelta'] ?? 0) as int,
          openBidonsDelta: (payload['openBidonsDelta'] ?? 0) as int,
          emptyBidonsDelta: (payload['emptyBidonsDelta'] ?? 0) as int,
          reason: (payload['reason'] ?? '') as String,
          clientRequestId: action.id,
        );
      case SyncActionType.pendingEdit:
        await repository.submitChangeRequest(
          hotelId: payload['hotelId'] as String,
          title: payload['title'] as String,
          targetTable: payload['targetTable'] as String,
          targetId: payload['targetId'] as String,
          oldData: Map<String, dynamic>.from(payload['oldData'] as Map),
          newData: Map<String, dynamic>.from(payload['newData'] as Map),
          clientRequestId: action.id,
        );
    }
  }

  Future<void> _replace(OfflineAction updatedAction) async {
    final prefs = await SharedPreferences.getInstance();
    // Reload and re-derive from this same instance so we merge against the
    // latest on-disk queue instead of a stale cached read.
    await prefs.reload();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    final actions =
        raw.map((item) => OfflineAction.fromJson(jsonDecode(item))).toList();
    await prefs.setStringList(
      _storageKey,
      [
        for (final action in actions)
          jsonEncode(
            (action.id == updatedAction.id ? updatedAction : action).toJson(),
          ),
      ],
    );
  }
}
