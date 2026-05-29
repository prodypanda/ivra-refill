import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'src/app/ivra_app.dart';
import 'src/state/app_state.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background messages
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final useSupabase = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
    if (useSupabase) {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
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
  setUrlStrategy(const HashUrlStrategy());

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Ignore initialization errors if missing config
  }

  final useSupabase = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  if (useSupabase) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  // Initialize Workmanager
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

  runApp(
    ProviderScope(
      overrides: [
        useSupabaseProvider.overrideWithValue(useSupabase),
      ],
      child: const IvraApp(),
    ),
  );
}
