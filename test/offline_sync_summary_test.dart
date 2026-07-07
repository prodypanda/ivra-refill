import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/offline/offline_sync_service.dart';

void main() {
  group('OfflineSyncSummary', () {
    test('hasFailures returns true when failed is greater than 0', () {
      const summary = OfflineSyncSummary(synced: 5, failed: 1);

      expect(summary.synced, 5);
      expect(summary.failed, 1);
      expect(summary.hasFailures, isTrue);
    });

    test('hasFailures returns false when failed is 0', () {
      const summary = OfflineSyncSummary(synced: 5, failed: 0);

      expect(summary.synced, 5);
      expect(summary.failed, 0);
      expect(summary.hasFailures, isFalse);
    });

    test('hasFailures returns false when synced and failed are both 0', () {
      const summary = OfflineSyncSummary(synced: 0, failed: 0);

      expect(summary.synced, 0);
      expect(summary.failed, 0);
      expect(summary.hasFailures, isFalse);
    });

    test('hasFailures returns true when failed is greater than 0 and synced is 0', () {
      const summary = OfflineSyncSummary(synced: 0, failed: 2);

      expect(summary.synced, 0);
      expect(summary.failed, 2);
      expect(summary.hasFailures, isTrue);
    });
  });
}
