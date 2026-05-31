import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared-preferences keys used by the auth + biometric flow.
class AuthPrefs {
  const AuthPrefs._();

  static const savedEmail = 'saved_email';
  static const savedPassword = 'saved_password';

  /// Whether the user has opted in to unlocking the app with biometrics.
  static const biometricEnabled = 'biometric_enabled';
}

/// Thin wrapper around [LocalAuthentication] that centralises the options used
/// across the app. The previous implementation called `authenticate()` with
/// the default options (where `persistAcrossBackgrounding` is false), which on
/// Android causes the system BiometricPrompt to be cancelled whenever the
/// activity is briefly paused (e.g. the fingerprint overlay, an incoming
/// notification, or the OS recreating the activity). The pending Dart future
/// then completes/throws and any caller that retries ends up re-showing the
/// prompt over and over. Setting `persistAcrossBackgrounding: true` makes the
/// plugin retry on foregrounding instead of failing, which is the documented
/// fix for the "fingerprint prompt keeps reappearing" bug.
class BiometricAuthService {
  BiometricAuthService([LocalAuthentication? localAuth])
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Whether the current device can perform a biometric / device-credential
  /// check. Always false on web, where `local_auth` is unsupported.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompt the user for biometric authentication. Returns true on success.
  Future<bool> authenticate(String reason) {
    return _localAuth.authenticate(
      localizedReason: reason,
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Whether biometric unlock is enabled by the user. Persisted in
/// [SharedPreferences] so the choice survives restarts, and exposed as a
/// notifier so the settings toggle and the login screen stay in sync.
final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, bool>((ref) {
  return BiometricEnabledNotifier()..load();
});

class BiometricEnabledNotifier extends StateNotifier<bool> {
  BiometricEnabledNotifier() : super(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = prefs.getBool(AuthPrefs.biometricEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AuthPrefs.biometricEnabled, value);
  }
}

/// Whether credentials from a previous successful login are stored locally.
/// Biometric unlock replays these credentials, so it is only offered once they
/// exist.
Future<bool> hasSavedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString(AuthPrefs.savedEmail);
  final password = prefs.getString(AuthPrefs.savedPassword);
  return email != null &&
      email.isNotEmpty &&
      password != null &&
      password.isNotEmpty;
}
