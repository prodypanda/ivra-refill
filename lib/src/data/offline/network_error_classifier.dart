import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Classifies errors thrown while talking to Supabase/the network so callers
/// can decide when to fall back to cached data, when to retry, and when a
/// failure is permanent and should not be retried.
///
/// Detection is based on concrete exception types instead of matching against
/// `error.toString()`, which is fragile across locales and library versions.
///
/// This is the single source of truth shared by the repository
/// (`SupabaseIvraRepository`) and the offline sync service so the two never
/// drift apart.
class NetworkErrorClassifier {
  const NetworkErrorClassifier._();

  /// Returns true when [error] represents a connectivity failure (the device
  /// is offline or the host is unreachable), meaning a cache fallback is safe.
  static bool isOffline(Object error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;
    // `package:http` throws ClientException on transport-level failures.
    // On web, a failed fetch surfaces as a ClientException as well.
    if (error is ClientException) return true;
    // Supabase wraps transport failures; treat ones without an HTTP status
    // (i.e. the request never reached the server) as offline.
    if (error is PostgrestException && error.code == null) return true;
    return false;
  }

  /// Returns true when [error] is transient and the request is worth retrying
  /// (expired JWT pending auto-refresh, or a connectivity blip).
  static bool isRetriable(Object error) {
    if (isOffline(error)) return true;
    // A momentarily expired/!refreshed session token.
    if (error is AuthException) return true;
    if (error is PostgrestException) {
      // PGRST301: JWT expired. Anything without a status is a transport error.
      return error.code == 'PGRST301' || error.code == null;
    }
    return false;
  }

  /// Returns true when [error] represents a permanent (non-retriable) failure,
  /// such as server-side validation errors or authorization/permission denials.
  /// These should not be retried automatically and should be surfaced for
  /// manual review.
  static bool isPermanent(Object error) => !isRetriable(error);
}
