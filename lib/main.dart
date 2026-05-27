import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/ivra_app.dart';
import 'src/state/app_state.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(const HashUrlStrategy());

  final useSupabase = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  if (useSupabase) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        useSupabaseProvider.overrideWithValue(useSupabase),
      ],
      child: const IvraApp(),
    ),
  );
}
