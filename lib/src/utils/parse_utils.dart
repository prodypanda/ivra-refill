/// Null-safe parsing helpers for decoding loosely-typed maps (Supabase rows,
/// RPC results, JSON cache payloads) into strongly-typed model fields.
///
/// The repository mappers previously used raw `as` casts everywhere
/// (`map['hotel_id'] as String`, `DateTime.parse(map['x'] as String)`,
/// `data['count'] as int`). A single unexpected null or shape change from the
/// backend would throw and take down the entire mapper (and the screen reading
/// it). These helpers degrade gracefully to a sensible fallback instead, so one
/// bad/renamed column can no longer crash an otherwise-valid response.
///
/// They intentionally accept `Object?` (the value already read from the map) so
/// call sites stay terse: `asString(map['name'])`, `asInt(map['count'])`, etc.
class ParseUtils {
  const ParseUtils._();
}

/// Returns [value] as a [String], or [fallback] when it is null. Non-string
/// values are coerced via `toString()` so an int/num column still yields a
/// usable string instead of throwing.
String asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Returns [value] as a non-empty [String], or `null` when it is null or an
/// empty/whitespace-only string. Useful for optional id/text columns.
String? asNullableString(Object? value) {
  if (value == null) return null;
  final str = value is String ? value : value.toString();
  return str.isEmpty ? null : str;
}

/// Returns [value] as an [int], or [fallback] when it cannot be parsed.
/// Accepts ints, numeric doubles, and numeric strings (Postgres/PostgREST can
/// surface integer columns as any of these depending on the path).
int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Returns [value] as a nullable [int], or `null` when it cannot be parsed.
int? asNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Returns [value] as a [bool], or [fallback] when it cannot be parsed.
/// Accepts bools, the strings `'true'`/`'false'` (case-insensitive), and the
/// numbers `1`/`0`.
bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case 't':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case 'f':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}

/// Parses [value] into a [DateTime], or returns [fallback] (defaulting to the
/// Unix epoch in UTC) when it is null or unparseable. Never throws.
///
/// Use this for required, non-null timestamp fields. The epoch fallback keeps a
/// model constructible even when a single timestamp column is missing or
/// malformed, instead of throwing a [FormatException] that would discard the
/// entire row.
DateTime asDateTime(Object? value, {DateTime? fallback}) {
  final result = asNullableDateTime(value);
  if (result != null) return result;
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

/// Parses [value] into a [DateTime], or returns `null` when it is null or
/// unparseable. Never throws. Use this for optional timestamp fields.
DateTime? asNullableDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  return null;
}

/// Returns [value] as a `Map<String, dynamic>`, or an empty map when it is null
/// or not a map. Never throws.
Map<String, dynamic> asStringMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

/// Returns [value] as a nullable `Map<String, dynamic>`: `null` when the value
/// is null or not a map, otherwise a copied map. Never throws.
Map<String, dynamic>? asNullableStringMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
