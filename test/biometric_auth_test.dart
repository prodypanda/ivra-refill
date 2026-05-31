import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/features/auth/biometric_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BiometricEnabledNotifier', () {
    test('defaults to false when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = BiometricEnabledNotifier();
      await notifier.load();
      expect(notifier.state, isFalse);
    });

    test('loads a previously persisted value', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.biometricEnabled: true,
      });
      final notifier = BiometricEnabledNotifier();
      await notifier.load();
      expect(notifier.state, isTrue);
    });

    test('setEnabled persists across notifier instances', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = BiometricEnabledNotifier();
      await notifier.setEnabled(true);
      expect(notifier.state, isTrue);

      final reloaded = BiometricEnabledNotifier();
      await reloaded.load();
      expect(reloaded.state, isTrue);
    });
  });

  group('hasSavedCredentials', () {
    test('is false without stored credentials', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await hasSavedCredentials(), isFalse);
    });

    test('is false when either credential is empty', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.savedEmail: 'user@example.com',
        AuthPrefs.savedPassword: '',
      });
      expect(await hasSavedCredentials(), isFalse);
    });

    test('is true when both credentials are present', () async {
      SharedPreferences.setMockInitialValues({
        AuthPrefs.savedEmail: 'user@example.com',
        AuthPrefs.savedPassword: 'hunter2',
      });
      expect(await hasSavedCredentials(), isTrue);
    });
  });
}
