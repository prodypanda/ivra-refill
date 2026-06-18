import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/services/notification_service.dart';

void main() {
  group('parseNotificationPayloadIds', () {
    test('reads ids from the top level of the payload', () {
      final ids = parseNotificationPayloadIds(
        jsonEncode({'alertId': 'a1', 'hotelId': 'h1'}),
      );
      expect(ids.alertId, 'a1');
      expect(ids.hotelId, 'h1');
    });

    test('reads ids from a nested data Map when top level is absent', () {
      final ids = parseNotificationPayloadIds(
        jsonEncode({
          'data': {'alertId': 'a2', 'hotelId': 'h2'},
        }),
      );
      expect(ids.alertId, 'a2');
      expect(ids.hotelId, 'h2');
    });

    test('reads ids from a nested data JSON string (FCM stringifies data)', () {
      final ids = parseNotificationPayloadIds(
        jsonEncode({
          'data': jsonEncode({'alertId': 'a3', 'hotelId': 'h3'}),
        }),
      );
      expect(ids.alertId, 'a3');
      expect(ids.hotelId, 'h3');
    });

    test('top-level ids take precedence over nested data', () {
      final ids = parseNotificationPayloadIds(
        jsonEncode({
          'alertId': 'top',
          'data': {'alertId': 'nested', 'hotelId': 'h4'},
        }),
      );
      expect(ids.alertId, 'top');
      // hotelId only present in nested data, so it is filled in.
      expect(ids.hotelId, 'h4');
    });

    test('coerces non-string id values to strings', () {
      final ids = parseNotificationPayloadIds(
        jsonEncode({'alertId': 42, 'hotelId': 7}),
      );
      expect(ids.alertId, '42');
      expect(ids.hotelId, '7');
    });

    test('returns empty ids for null, malformed, or non-map payloads', () {
      expect(parseNotificationPayloadIds(null).alertId, isNull);
      expect(parseNotificationPayloadIds('not-json{').alertId, isNull);
      expect(parseNotificationPayloadIds(jsonEncode([1, 2])).hotelId, isNull);
    });

    test('ignores an unparseable nested data string without throwing', () {
      final ids = parseNotificationPayloadIds(
        jsonEncode({'alertId': 'a5', 'data': 'not-json{'}),
      );
      expect(ids.alertId, 'a5');
      expect(ids.hotelId, isNull);
    });
  });

  group('resolveNotificationAction', () {
    test('Dismiss does nothing', () {
      final d = resolveNotificationAction(
        actionId: 'Dismiss',
        alertId: 'a1',
        hotelId: 'h1',
      );
      expect(d.kind, NotificationActionKind.none);
    });

    test('Acknowledge queues the acknowledgement toast', () {
      final d = resolveNotificationAction(
        actionId: 'Acknowledge',
        alertId: null,
        hotelId: null,
      );
      expect(d.kind, NotificationActionKind.toast);
      expect(d.toastKey, 'notificationAcknowledgedToast');
    });

    test('more_info navigates to hotel-scoped inventory when hotelId is set', () {
      final d = resolveNotificationAction(
        actionId: 'more_info',
        alertId: null,
        hotelId: 'h9',
      );
      expect(d.kind, NotificationActionKind.navigate);
      expect(d.navigation, '/inventory?hotelId=h9');
    });

    test('more_info navigates to plain inventory when hotelId is missing', () {
      final d = resolveNotificationAction(
        actionId: 'more_info',
        alertId: null,
        hotelId: '',
      );
      expect(d.kind, NotificationActionKind.navigate);
      expect(d.navigation, '/inventory');
    });

    test('resolve resolves the alert and navigates to /alerts', () {
      final d = resolveNotificationAction(
        actionId: 'resolve',
        alertId: 'a1',
        hotelId: null,
      );
      expect(d.kind, NotificationActionKind.resolveAlert);
      expect(d.navigation, '/alerts');
    });

    test('delete deletes the alert and navigates to /alerts', () {
      final d = resolveNotificationAction(
        actionId: 'delete',
        alertId: 'a1',
        hotelId: null,
      );
      expect(d.kind, NotificationActionKind.deleteAlert);
      expect(d.navigation, '/alerts');
    });

    test('default tap navigates to an explicit targetPage from the payload', () {
      final d = resolveNotificationAction(
        actionId: null,
        alertId: null,
        hotelId: null,
        payload: {'targetPage': '/dashboard'},
      );
      expect(d.kind, NotificationActionKind.navigate);
      expect(d.navigation, '/dashboard');
    });

    test('default tap with no targetPage does nothing', () {
      final d = resolveNotificationAction(
        actionId: null,
        alertId: null,
        hotelId: null,
        payload: {'alertId': 'a1'},
      );
      expect(d.kind, NotificationActionKind.none);
    });

    test('unknown action with no targetPage does nothing', () {
      final d = resolveNotificationAction(
        actionId: 'totally_unknown',
        alertId: 'a1',
        hotelId: 'h1',
        payload: {'alertId': 'a1'},
      );
      expect(d.kind, NotificationActionKind.none);
    });
  });
}
