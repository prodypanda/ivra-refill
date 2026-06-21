import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// A tiny logging abstraction so the app does not scatter raw `debugPrint`
/// calls (which are stripped in release builds and therefore silently drop
/// errors).
///
/// Levels:
///   * [debug] / [info] — diagnostic messages. Emitted via `dart:developer`'s
///     `log` in debug/profile builds and suppressed in release builds.
///   * [error] — failures. Always routed somewhere it can be observed: in
///     debug/profile builds via `developer.log` and `debugPrint`; in release
///     builds it is handed to [FlutterError.presentError] (so it reaches the
///     platform console / crash plumbing) in addition to `developer.log`.
///
/// No third-party crash reporter is wired in (none is configured for this
/// project). Instead a real sink can be plugged in later by assigning
/// [AppLogger.onError]; when set it receives every error so it can forward to
/// Sentry/Crashlytics/etc.
class AppLogger {
  AppLogger._();

  static const String _name = 'ivra';

  /// Optional external sink. When set, every [error] is forwarded here so a
  /// real crash-reporting backend can be plugged in without touching call
  /// sites.
  static void Function(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  })? onError;

  static void debug(String msg) {
    if (kReleaseMode) return;
    developer.log(msg, name: _name, level: 500);
  }

  static void info(String msg) {
    if (kReleaseMode) return;
    developer.log(msg, name: _name, level: 800);
  }

  /// Records an [error] (with optional [stackTrace] and human [context]).
  ///
  /// This never throws — logging must not take down the caller.
  static void error(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final label = context == null || context.isEmpty ? 'error' : context;
    try {
      developer.log(
        label,
        name: _name,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );

      if (kReleaseMode) {
        // In release builds developer.log output may be dropped, so also hand
        // the failure to Flutter's error presenter, which routes to the
        // platform console and any installed FlutterError plumbing.
        FlutterError.presentError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: _name,
            context: ErrorDescription(label),
          ),
        );
      } else {
        debugPrint('[$_name] $label: $error');
      }

      onError?.call(error, stackTrace: stackTrace, context: context);
    } catch (_) {
      // Logging must never throw.
    }
  }

  /// Hook to wire into `FlutterError.onError` so uncaught framework errors flow
  /// through the same sink as explicit [error] calls.
  static void recordFlutterError(FlutterErrorDetails details) {
    // Preserve Flutter's default presentation (console dump in debug, etc.).
    FlutterError.presentError(details);
    final context = details.context?.toString() ?? details.library;
    error(
      details.exception,
      stackTrace: details.stack,
      context: context,
    );
  }
}
