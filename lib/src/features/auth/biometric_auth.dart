import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared-preferences keys used by the auth + biometric flow.
///
/// Biometric opt-in and saved credentials are scoped *per account*. Earlier the
/// app stored a single global `biometric_enabled` flag and one
/// `saved_email`/`saved_password` pair, so enabling biometrics on one account
/// (and the credentials saved at login) leaked to whatever account signed in
/// next. Keying the password by email and tracking which single account opted
/// in fixes that cross-account leak.
class AuthPrefs {
  const AuthPrefs._();

  /// Email of the most recent successful password login. Used only to pre-fill
  /// the login form, never to decide biometric eligibility.
  static const savedEmail = 'saved_email';

  /// Email of the single account that has opted in to biometric unlock (lower
  /// cased), or absent/empty when biometric unlock is disabled.
  static const biometricAccount = 'biometric_account_email';

  /// Per-account saved password, keyed by the normalised email. Biometric
  /// unlock replays the credentials of [biometricAccount] only.
  static String passwordKey(String email) =>
      'saved_password::${normalizeEmail(email)}';

  /// Legacy global keys, read only to clean them up on migration.
  static const legacyBiometricEnabled = 'biometric_enabled';
  static const legacyPassword = 'saved_password';

  /// Canonical form of an email used for keying/comparison.
  static String normalizeEmail(String email) => email.trim().toLowerCase();
}

/// Secure, hardware-backed store (Android Keystore / iOS Keychain) for the
/// only sensitive value the biometric flow persists: the replay password.
const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

/// Persist the credentials for a successful login, scoped to [email].
///
/// The password is written to [_secureStorage] (encrypted at rest) rather than
/// to plaintext [SharedPreferences]. Only the non-sensitive `savedEmail` hint
/// stays in [SharedPreferences]. Any pre-existing plaintext password for this
/// account is scrubbed so old data cannot be recovered from disk.
Future<void> saveLoginCredentials(String email, String password) async {
  final prefs = await SharedPreferences.getInstance();
  final trimmed = email.trim();
  await prefs.setString(AuthPrefs.savedEmail, trimmed);
  await _secureStorage.write(
    key: AuthPrefs.passwordKey(trimmed),
    value: password,
  );

  // Scrub any legacy plaintext password for this account.
  if (prefs.containsKey(AuthPrefs.passwordKey(trimmed))) {
    await prefs.remove(AuthPrefs.passwordKey(trimmed));
  }
  // Scrub the old global plaintext password.
  if (prefs.containsKey(AuthPrefs.legacyPassword)) {
    await prefs.remove(AuthPrefs.legacyPassword);
  }
}

/// The saved password for [email], if any.
///
/// Reads from secure storage first. If nothing is found there but a legacy
/// plaintext password still lives in [SharedPreferences], it is transparently
/// migrated into secure storage (and the plaintext copy deleted) before being
/// returned, so upgrading users keep working without re-entering credentials.
Future<String?> savedPasswordFor(String email) async {
  var password = await _secureStorage.read(key: AuthPrefs.passwordKey(email));
  if (password != null && password.isNotEmpty) return password;

  final prefs = await SharedPreferences.getInstance();
  password = prefs.getString(AuthPrefs.passwordKey(email));
  if (password == null || password.isEmpty) {
    password = prefs.getString(AuthPrefs.legacyPassword);
  }
  if (password != null && password.isNotEmpty) {
    await saveLoginCredentials(email, password);
  }
  return password;
}

/// Whether biometric unlock is currently enabled for [email].
bool isBiometricEnabledForEmail(String? biometricAccount, String? email) {
  if (biometricAccount == null || biometricAccount.isEmpty) return false;
  if (email == null || email.isEmpty) return false;
  return biometricAccount == AuthPrefs.normalizeEmail(email);
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

/// Holds the single account email that has opted in to biometric unlock (or
/// null when disabled). Persisted in [SharedPreferences] so the choice survives
/// restarts, and exposed as a notifier so the settings toggle and the login
/// screen stay in sync. Replaces the old global boolean, which leaked the
/// opt-in across every account on the device.
final biometricAccountProvider =
    StateNotifierProvider<BiometricAccountNotifier, String?>((ref) {
      return BiometricAccountNotifier()..load();
    });

class BiometricAccountNotifier extends StateNotifier<String?> {
  BiometricAccountNotifier() : super(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Drop the legacy global opt-in so a previously stored `true` can no longer
    // grant biometric unlock to an unrelated account. Users re-enable per
    // account once after upgrading.
    if (prefs.containsKey(AuthPrefs.legacyBiometricEnabled)) {
      await prefs.remove(AuthPrefs.legacyBiometricEnabled);
    }
    if (!mounted) return;
    final account = prefs.getString(AuthPrefs.biometricAccount);
    state = (account != null && account.isNotEmpty) ? account : null;
  }

  /// Enable biometric unlock for [email], or pass null/empty to disable it.
  Future<void> setAccount(String? email) async {
    final normalized = (email != null && email.trim().isNotEmpty)
        ? AuthPrefs.normalizeEmail(email)
        : null;
    state = normalized;
    final prefs = await SharedPreferences.getInstance();
    if (normalized == null) {
      await prefs.remove(AuthPrefs.biometricAccount);
    } else {
      await prefs.setString(AuthPrefs.biometricAccount, normalized);
    }
  }
}

/// Whether the account that opted in to biometric unlock has stored credentials
/// to replay. Biometric is only offered on the login screen once they exist.
Future<bool> hasBiometricCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  final account = prefs.getString(AuthPrefs.biometricAccount);
  if (account == null || account.isEmpty) return false;
  final password = await savedPasswordFor(account);
  return password != null && password.isNotEmpty;
}
