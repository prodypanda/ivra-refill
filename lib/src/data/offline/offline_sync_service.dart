import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/app_enums.dart';
import '../ivra_repository.dart';

class OfflineAction {
  const OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
  });

  final String id;
  final SyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'attempt_count': attemptCount,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'last_error': lastError,
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
    );
  }

  OfflineAction failedWith(String error) {
    return OfflineAction(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      attemptCount: attemptCount + 1,
      lastAttemptAt: DateTime.now(),
      lastError: error,
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
    final actions = await pendingActions();
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
    await prefs.remove(_storageKey);
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
      final didSync = await syncAction(repository, action.id);
      if (didSync) {
        synced += 1;
      } else {
        failed += 1;
      }
    }

    return OfflineSyncSummary(synced: synced, failed: failed);
  }

  Future<bool> syncAction(
    IvraRepository repository,
    String actionId,
  ) async {
    final actions = await pendingActions();
    OfflineAction? action;
    for (final item in actions) {
      if (item.id == actionId) action = item;
    }

    if (action == null) return false;

    try {
      await _perform(repository, action);
      await remove(action.id);
      return true;
    } on Object catch (error) {
      await _replace(action.failedWith(error.toString()));
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
    final actions = await pendingActions();
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
