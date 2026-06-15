## 2024-06-15 - Migrate SharedPreferences to FlutterSecureStorage for Passwords
**Vulnerability:** The app was using `SharedPreferences` to store user passwords in plaintext locally on the device for biometric unlock replay.
**Learning:** `SharedPreferences` saves data in unencrypted XML files in the app's internal storage, making it accessible to attackers with root privileges or sandbox escape capabilities.
**Prevention:** Always use secure storage mechanisms like `flutter_secure_storage` (which utilizes Keystore/Keychain) for sensitive data such as passwords, tokens, or API keys.
