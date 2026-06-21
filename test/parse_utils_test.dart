import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/utils/parse_utils.dart';

void main() {
  group('asString', () {
    test('returns the string unchanged', () {
      expect(asString('hello'), 'hello');
    });

    test('returns the fallback for null', () {
      expect(asString(null), '');
      expect(asString(null, fallback: 'x'), 'x');
    });

    test('coerces non-string values via toString', () {
      expect(asString(42), '42');
      expect(asString(true), 'true');
    });
  });

  group('asNullableString', () {
    test('returns null for null and empty strings', () {
      expect(asNullableString(null), isNull);
      expect(asNullableString(''), isNull);
    });

    test('returns the string when non-empty', () {
      expect(asNullableString('abc'), 'abc');
    });

    test('coerces non-string values', () {
      expect(asNullableString(7), '7');
    });
  });

  group('asInt', () {
    test('passes through ints', () {
      expect(asInt(5), 5);
    });

    test('truncates nums', () {
      expect(asInt(5.9), 5);
    });

    test('parses numeric strings', () {
      expect(asInt('12'), 12);
    });

    test('returns the fallback for unparseable / null', () {
      expect(asInt(null), 0);
      expect(asInt('nope', fallback: -1), -1);
      expect(asInt(true, fallback: 9), 9);
    });
  });

  group('asNullableInt', () {
    test('returns null for null and unparseable', () {
      expect(asNullableInt(null), isNull);
      expect(asNullableInt('x'), isNull);
    });

    test('parses ints, nums and numeric strings', () {
      expect(asNullableInt(3), 3);
      expect(asNullableInt(3.2), 3);
      expect(asNullableInt('4'), 4);
    });
  });

  group('asBool', () {
    test('passes through bools', () {
      expect(asBool(true), isTrue);
      expect(asBool(false), isFalse);
    });

    test('parses common truthy/falsy strings', () {
      expect(asBool('true'), isTrue);
      expect(asBool('FALSE'), isFalse);
      expect(asBool('1'), isTrue);
      expect(asBool('0'), isFalse);
      expect(asBool('yes'), isTrue);
      expect(asBool('no'), isFalse);
    });

    test('parses numbers', () {
      expect(asBool(1), isTrue);
      expect(asBool(0), isFalse);
    });

    test('returns the fallback for null / unknown', () {
      expect(asBool(null), isFalse);
      expect(asBool(null, fallback: true), isTrue);
      expect(asBool('maybe', fallback: true), isTrue);
    });
  });

  group('asDateTime', () {
    test('parses an ISO string', () {
      final dt = asDateTime('2024-01-02T03:04:05Z');
      expect(dt.toUtc(), DateTime.utc(2024, 1, 2, 3, 4, 5));
    });

    test('passes through a DateTime', () {
      final now = DateTime.now();
      expect(asDateTime(now), now);
    });

    test('falls back to the epoch for null / unparseable', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      expect(asDateTime(null), epoch);
      expect(asDateTime('not-a-date'), epoch);
    });

    test('honours a custom fallback', () {
      final fallback = DateTime.utc(2000, 1, 1);
      expect(asDateTime(null, fallback: fallback), fallback);
    });
  });

  group('asNullableDateTime', () {
    test('returns null for null, empty and unparseable', () {
      expect(asNullableDateTime(null), isNull);
      expect(asNullableDateTime(''), isNull);
      expect(asNullableDateTime('nope'), isNull);
    });

    test('parses a valid string', () {
      expect(
        asNullableDateTime('2024-06-01T00:00:00Z')!.toUtc(),
        DateTime.utc(2024, 6, 1),
      );
    });
  });

  group('asStringMap / asNullableStringMap', () {
    test('copies a map', () {
      final result = asStringMap({'a': 1, 'b': 'x'});
      expect(result, {'a': 1, 'b': 'x'});
    });

    test('asStringMap returns empty for null / non-map', () {
      expect(asStringMap(null), isEmpty);
      expect(asStringMap('x'), isEmpty);
    });

    test('asNullableStringMap returns null for null / non-map', () {
      expect(asNullableStringMap(null), isNull);
      expect(asNullableStringMap(5), isNull);
      expect(asNullableStringMap({'k': 'v'}), {'k': 'v'});
    });
  });
}
