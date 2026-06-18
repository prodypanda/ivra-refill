import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/supabase_ivra_repository.dart';

/// Builds a cache envelope string with the given fields. Mirrors the shape the
/// repository writes: `{ 'v': <version>, 'ts': <epochMs>, 'data': <payload> }`.
String _envelope({
  required Object? version,
  required Object? ts,
  required Object? data,
}) {
  return jsonEncode(<String, dynamic>{'v': version, 'ts': ts, 'data': data});
}

int _now() => DateTime.now().millisecondsSinceEpoch;

void main() {
  final version = SupabaseIvraRepository.cacheVersion;
  final maxAge = SupabaseIvraRepository.cacheMaxAge;

  Object? read(String? cached) =>
      SupabaseIvraRepository.readCacheEnvelopeForTest(cached);

  group('_readCacheEnvelope returns the payload', () {
    test('for a fresh, current-version envelope wrapping a list', () {
      final payload = [
        {'id': '1', 'name': 'A'},
        {'id': '2', 'name': 'B'},
      ];
      final result = read(_envelope(version: version, ts: _now(), data: payload));
      expect(result, payload);
    });

    test('for a fresh, current-version envelope wrapping a map', () {
      final payload = {'id': '1', 'name': 'A'};
      final result = read(_envelope(version: version, ts: _now(), data: payload));
      expect(result, payload);
    });

    test('for an entry written exactly at the edge of the TTL', () {
      final ts = _now() - maxAge.inMilliseconds + 1000;
      final result = read(_envelope(version: version, ts: ts, data: [1, 2, 3]));
      expect(result, [1, 2, 3]);
    });
  });

  group('_readCacheEnvelope treats as a miss (returns null)', () {
    test('when the cached string is null', () {
      expect(read(null), isNull);
    });

    test('when the cached string is not valid JSON', () {
      expect(read('not-json{'), isNull);
    });

    test('for a legacy bare payload with no envelope (a JSON list)', () {
      expect(read(jsonEncode([1, 2, 3])), isNull);
    });

    test('for a JSON value that is not a Map', () {
      expect(read(jsonEncode('a-string')), isNull);
    });

    test('when the version key is missing', () {
      expect(read(jsonEncode({'ts': _now(), 'data': []})), isNull);
    });

    test('when the ts key is missing', () {
      expect(read(jsonEncode({'v': version, 'data': []})), isNull);
    });

    test('when the data key is missing', () {
      expect(read(jsonEncode({'v': version, 'ts': _now()})), isNull);
    });

    test('when the version does not match the current version', () {
      expect(
        read(_envelope(version: '$version-mismatch', ts: _now(), data: [])),
        isNull,
      );
    });

    test('when the version is an int instead of the expected string', () {
      expect(read(_envelope(version: 1, ts: _now(), data: [])), isNull);
    });

    test('when ts is not an int', () {
      expect(read(_envelope(version: version, ts: 'soon', data: [])), isNull);
    });

    test('when the entry is older than the max age', () {
      final ts = _now() - maxAge.inMilliseconds - 1000;
      expect(read(_envelope(version: version, ts: ts, data: [])), isNull);
    });

    test('when the timestamp is in the future (negative age)', () {
      final ts = _now() + const Duration(hours: 1).inMilliseconds;
      expect(read(_envelope(version: version, ts: ts, data: [])), isNull);
    });
  });
}
