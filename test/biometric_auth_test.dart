import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/features/auth/biometric_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('BiometricAccountNotifier', () {
    test('defaults to null when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = BiometricAccountNotifier();
      await notifier.load();
      expect(notifier.state, isNull);
    });

    test('loads a previously persisted account', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.biometricAccount: 'admin@ivra.com',
      });
      final notifier = BiometricAccountNotifier();
      await notifier.load();
      expect(notifier.state, 'admin@ivra.com');
    });

    test('setAccount normalises and persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = BiometricAccountNotifier();
      await notifier.setAccount('  Admin@Ivra.com ');
      expect(notifier.state, 'admin@ivra.com');

      final reloaded = BiometricAccountNotifier();
      await reloaded.load();
      expect(reloaded.state, 'admin@ivra.com');
    });

    test('setAccount(null) disables and clears the stored account', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.biometricAccount: 'admin@ivra.com',
      });
      final notifier = BiometricAccountNotifier();
      await notifier.load();
      await notifier.setAccount(null);
      expect(notifier.state, isNull);

      final reloaded = BiometricAccountNotifier();
      await reloaded.load();
      expect(reloaded.state, isNull);
    });

    test('drops the legacy global biometric_enabled flag on load', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.legacyBiometricEnabled: true,
      });
      final notifier = BiometricAccountNotifier();
      await notifier.load();
      // Legacy global opt-in must not grant biometric to an unrelated account.
      expect(notifier.state, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AuthPrefs.legacyBiometricEnabled), isFalse);
    });

    test('drops the legacy global saved_password flag on load', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.legacyPassword: 'plaintext_password',
      });
      final notifier = BiometricAccountNotifier();
      await notifier.load();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AuthPrefs.legacyPassword), isFalse);
    });
  });

  group('isBiometricEnabledForEmail', () {
    test('false when no biometric account is set', () {
      expect(isBiometricEnabledForEmail(null, 'admin@ivra.com'), isFalse);
      expect(isBiometricEnabledForEmail('', 'admin@ivra.com'), isFalse);
    });

    test('false when the signed-in account differs', () {
      expect(
        isBiometricEnabledForEmail('admin@ivra.com', 'nashab2015@gmail.com'),
        isFalse,
      );
    });

    test('true (case-insensitively) for the opted-in account', () {
      expect(
        isBiometricEnabledForEmail('admin@ivra.com', 'Admin@Ivra.com'),
        isTrue,
      );
    });
  });

  group('per-account credentials', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('saveLoginCredentials stores password keyed by email and scrubs legacy password', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.legacyPassword: 'plaintext_password',
      });
      await saveLoginCredentials('Admin@Ivra.com', 'hunter2');
      expect(await savedPasswordFor('admin@ivra.com'), 'hunter2');
      // A different account has no stored password.
      expect(await savedPasswordFor('nashab2015@gmail.com'), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AuthPrefs.legacyPassword), isFalse);
    });

    test('signing in as a second account does not overwrite the first',
        () async {
      await saveLoginCredentials('admin@ivra.com', 'adminpw');
      await saveLoginCredentials('nashab2015@gmail.com', 'nashabpw');
      expect(await savedPasswordFor('admin@ivra.com'), 'adminpw');
      expect(await savedPasswordFor('nashab2015@gmail.com'), 'nashabpw');
    });

    test('hasBiometricCredentials reflects the opted-in account only',
        () async {
      await saveLoginCredentials('admin@ivra.com', 'adminpw');
      // No biometric account selected yet.
      expect(await hasBiometricCredentials(), isFalse);

      await BiometricAccountNotifier().setAccount('admin@ivra.com');
      expect(await hasBiometricCredentials(), isTrue);

      // Switch the opt-in to an account without stored credentials.
      await BiometricAccountNotifier().setAccount('nashab2015@gmail.com');
      expect(await hasBiometricCredentials(), isFalse);
    });

    test(
        'legacy plaintext password is migrated to secure storage and scrubbed',
        () async {
      // Seed a legacy plaintext password directly in SharedPreferences.
      SharedPreferences.setMockInitialValues({
        AuthPrefs.passwordKey('admin@ivra.com'): 'legacy_password_123',
        AuthPrefs.legacyPassword: 'plaintext_password',
      });

      // Reading it transparently migrates via the fallback path.
      expect(await savedPasswordFor('admin@ivra.com'), 'legacy_password_123');

      // The plaintext copy must be gone from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(AuthPrefs.passwordKey('admin@ivra.com')),
        isFalse,
      );

      // Also the global legacy password should be gone.
      expect(prefs.containsKey(AuthPrefs.legacyPassword), isFalse);

      // The password must now live in secure storage.
      const secureStorage = FlutterSecureStorage();
      expect(
        await secureStorage.read(key: AuthPrefs.passwordKey('admin@ivra.com')),
        'legacy_password_123',
      );
    });
  });
}
