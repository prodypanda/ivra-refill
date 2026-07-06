import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'src/app/ivra_app.dart';
import 'src/state/app_state.dart';
import 'src/services/notification_service.dart';
import 'src/utils/app_logger.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background messages
  await NotificationService.showLocalNotification(message);
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final useSupabase = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
    if (useSupabase) {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: false,
      );
    }

    final container = ProviderContainer(
      overrides: [useSupabaseProvider.overrideWithValue(useSupabase)],
    );

    try {
      final repo = container.read(repositoryProvider);
      final syncService = container.read(offlineSyncServiceProvider);
      await syncService.syncPendingDetailed(repo);
    } finally {
      container.dispose();
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  setUrlStrategy(PathUrlStrategy());

  // Route uncaught framework errors through the central logging sink so they
  // are observable in release builds (and forwardable to a real crash reporter
  // later via AppLogger.onError).
  FlutterError.onError = AppLogger.recordFlutterError;

  try {
    await Firebase.initializeApp();
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e, stack) {
    // Firebase is optional: the app must still start when no Firebase config
    // is bundled (e.g. local/demo builds). Distinguish that expected case
    // from a genuine initialization failure so real problems are observable
    // instead of silently swallowed.
    if (e is FirebaseException && e.code == 'no-app') {
      // No FirebaseApp configured for this build. Expected; log at info level
      // (suppressed in release) and continue without push messaging.
      AppLogger.info('Firebase not configured; skipping push messaging.');
    } else {
      // A real failure: surface it through the central error sink so it is
      // observable in release builds and forwardable to a crash reporter.
      AppLogger.error(
        e,
        stackTrace: stack,
        context: 'Firebase.initializeApp failed',
      );
      if (kDebugMode) {
        // Extra developer-only diagnostics while debugging locally.
        AppLogger.debug('Firebase init error detail: $e');
      }
    }
  }

  final useSupabase = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  if (useSupabase) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      // Suppress the backend SDK's console logging so the provider name is
      // never surfaced to end users (e.g. the browser console on web).
      debug: false,
    );
  }

  // Workmanager backs onto platform background-execution APIs that rely on
  // `dart:io` (Platform.isAndroid/isIOS). Those throw on web
  // (`Unsupported operation: Platform._operatingSystem`), which previously
  // crashed startup and left the web build stuck on the loading screen. Skip
  // it on web, where background sync isn't supported anyway.
  if (!kIsWeb) {
    Workmanager().initialize(
      callbackDispatcher,
    );

    // Register a periodic task for background sync
    Workmanager().registerPeriodicTask(
      '1',
      'backgroundSync',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        useSupabaseProvider.overrideWithValue(useSupabase),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const IvraApp(),
    ),
  );
}
