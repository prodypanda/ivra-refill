## 2024-06-09 - Plaintext password storage in SharedPreferences
**Vulnerability:** The application saves the user's plain text password in Android's `SharedPreferences` in `lib/src/features/auth/biometric_auth.dart`.
**Learning:** This existed because `SharedPreferences` is an easy default to use for persistence without considering encryption of secrets.
**Prevention:** In Flutter applications, always use secure storage mechanisms like `flutter_secure_storage` (which utilizes native KeyStore/Keychain) for sensitive data such as passwords, API keys, or tokens.
