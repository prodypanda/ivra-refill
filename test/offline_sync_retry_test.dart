import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/ivra_repository.dart';
import 'package:ivra_refill/src/data/offline/network_error_classifier.dart';
import 'package:ivra_refill/src/data/offline/offline_sync_service.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A repository fake that throws a configurable error from [recordRefill].
/// All other members are unimplemented (the tests only exercise refill).
class _ThrowingRepository implements IvraRepository {
  _ThrowingRepository(this.error);

  Object? error;
  int recordRefillCalls = 0;

  @override
  Future<void> recordRefill({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
  }) async {
    recordRefillCalls += 1;
    final err = error;
    if (err != null) throw err;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<OfflineAction> _enqueueRefill(OfflineSyncService service) async {
  await service.enqueue(
    type: SyncActionType.refill,
    payload: {'roomProductId': 'rp-1'},
  );
  return (await service.pendingActions()).single;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkErrorClassifier', () {
    test('transient errors are retriable, not permanent', () {
      expect(NetworkErrorClassifier.isRetriable(const SocketException('x')),
          isTrue);
      expect(NetworkErrorClassifier.isRetriable(TimeoutException('x')), isTrue);
      expect(NetworkErrorClassifier.isRetriable(const HttpException('x')),
          isTrue);
      expect(
        NetworkErrorClassifier.isRetriable(
          const PostgrestException(message: 'jwt expired', code: 'PGRST301'),
        ),
        isTrue,
      );
      expect(
        NetworkErrorClassifier.isRetriable(
          const PostgrestException(message: 'transport'),
        ),
        isTrue,
      );
      expect(NetworkErrorClassifier.isRetriable(const AuthException('expired')),
          isTrue);

      expect(NetworkErrorClassifier.isPermanent(const SocketException('x')),
          isFalse);
    });

    test('server validation / 4xx errors are permanent', () {
      const validation = PostgrestException(
        message: 'invalid input',
        code: '23514',
      );
      expect(NetworkErrorClassifier.isRetriable(validation), isFalse);
      expect(NetworkErrorClassifier.isPermanent(validation), isTrue);
    });
  });

  group('OfflineSyncService retry / dead-letter / backoff', () {
    test('transient failure keeps the action retriable (not dead-letter)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(const SocketException('offline'));

      await _enqueueRefill(service);
      final synced = await service.syncPending(repo);

      expect(synced, 0);
      final action = (await service.pendingActions()).single;
      expect(action.attemptCount, 1);
      expect(action.isDeadLetter, isFalse);
    });

    test('permanent failure goes straight to dead-letter', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(
        const PostgrestException(message: 'invalid', code: '23514'),
      );

      await _enqueueRefill(service);
      await service.syncPending(repo);

      final action = (await service.pendingActions()).single;
      expect(action.attemptCount, 1);
      expect(action.isDeadLetter, isTrue);
      expect(action.needsReview, isTrue);
      expect(await service.deadLetterActions(), hasLength(1));
    });

    test('reaching the retry cap moves the action to dead-letter', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(const SocketException('offline'));

      final queued = await _enqueueRefill(service);

      // Drive attempts up to the cap. Manual retries bypass the backoff window
      // so we can exercise the cap deterministically without waiting.
      for (var i = 0; i < OfflineAction.maxAttempts; i++) {
        await service.syncAction(repo, queued.id, manual: true);
      }

      final action = (await service.pendingActions()).single;
      expect(action.attemptCount, OfflineAction.maxAttempts);
      expect(action.isDeadLetter, isTrue);
    });

    test('automatic sync skips dead-lettered actions', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(
        const PostgrestException(message: 'invalid', code: '23514'),
      );

      final queued = await _enqueueRefill(service);
      await service.syncPending(repo); // -> dead-letter, 1 call
      expect(repo.recordRefillCalls, 1);

      // A second automatic pass must NOT attempt the dead-lettered action.
      final summary = await service.syncPendingDetailed(repo);
      expect(repo.recordRefillCalls, 1);
      expect(summary.failed, 0);
      expect(summary.synced, 0);
      // Still present, still terminal.
      expect((await service.pendingActions()).single.id, queued.id);
    });

    test('automatic sync skips actions still in their backoff window',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(const SocketException('offline'));

      await _enqueueRefill(service);
      await service.syncPending(repo); // attempt 1, just failed transiently
      expect(repo.recordRefillCalls, 1);

      // Immediately running again should skip it (within backoff window).
      await service.syncPending(repo);
      expect(repo.recordRefillCalls, 1);
    });

    test('manual retry bypasses backoff window', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(const SocketException('offline'));

      final queued = await _enqueueRefill(service);
      await service.syncPending(repo); // attempt 1
      expect(repo.recordRefillCalls, 1);

      // Manual retry runs even though we are within the backoff window.
      await service.syncAction(repo, queued.id, manual: true);
      expect(repo.recordRefillCalls, 2);
    });

    test('manual retry resets a dead-lettered action and can succeed',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(
        const PostgrestException(message: 'invalid', code: '23514'),
      );

      final queued = await _enqueueRefill(service);
      await service.syncPending(repo);
      expect((await service.pendingActions()).single.isDeadLetter, isTrue);

      // The error is resolved server-side; manual retry resets and succeeds.
      repo.error = null;
      final didSync = await service.retryDeadLetterAction(repo, queued.id);

      expect(didSync, isTrue);
      expect(await service.pendingActions(), isEmpty);
    });

    test('manual retry of a dead-letter that still fails resets then re-fails',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(const SocketException('offline'));

      // Force into dead-letter via repeated manual attempts.
      final queued = await _enqueueRefill(service);
      for (var i = 0; i < OfflineAction.maxAttempts; i++) {
        await service.syncAction(repo, queued.id, manual: true);
      }
      expect((await service.pendingActions()).single.isDeadLetter, isTrue);

      // Manual retry resets attemptCount to 0, then fails again transiently.
      await service.retryDeadLetterAction(repo, queued.id);
      final action = (await service.pendingActions()).single;
      expect(action.attemptCount, 1);
      expect(action.isDeadLetter, isFalse);
    });
  });

  group('OfflineAction backoff math', () {
    test('exponential backoff grows and is capped', () {
      final base = OfflineAction(
        id: 'a',
        type: SyncActionType.refill,
        payload: const {},
        createdAt: DateTime(2024),
        attemptCount: 1,
      );
      expect(base.backoffDuration, OfflineAction.backoffBase);

      final second = base.copyWith(attemptCount: 2);
      expect(second.backoffDuration, OfflineAction.backoffBase * 2);

      final huge = base.copyWith(attemptCount: 20);
      expect(huge.backoffDuration, OfflineAction.backoffCap);
    });

    test('isInBackoff respects lastAttemptAt and terminal state', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final justFailed = OfflineAction(
        id: 'a',
        type: SyncActionType.refill,
        payload: const {},
        createdAt: now,
        attemptCount: 1,
        lastAttemptAt: now,
      );
      expect(justFailed.isInBackoff(now), isTrue);
      expect(
        justFailed.isInBackoff(now.add(const Duration(minutes: 1))),
        isFalse,
      );

      final terminal = justFailed.copyWith(isDeadLetter: true);
      expect(terminal.isInBackoff(now), isFalse);
    });
  });

  group('OfflineSyncService extreme backlog handling', () {
    test('handles 50+ backlogged operations without issues', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineSyncService();
      final repo = _ThrowingRepository(null);

      // Enqueue 55 actions
      for (var i = 0; i < 55; i++) {
        await service.enqueue(
          type: SyncActionType.refill,
          payload: {'roomProductId': 'rp-$i'},
        );
      }

      var pending = await service.pendingActions();
      expect(pending.length, 55);

      // Attempt to sync all of them
      final summary = await service.syncPendingDetailed(repo);

      expect(summary.synced, 55);
      expect(summary.failed, 0);
      expect(repo.recordRefillCalls, 55);

      pending = await service.pendingActions();
      expect(pending, isEmpty);
    });
  });
}
