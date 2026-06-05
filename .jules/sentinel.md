## 2024-05-15 - [Plaintext Biometric Credentials Storage]
**Vulnerability:** The application stores the user's password in plain text in SharedPreferences to enable biometric unlock.
**Learning:** SharedPreferences is not encrypted on Android or iOS. Storing sensitive data like passwords in SharedPreferences exposes them to unauthorized access on rooted/jailbroken devices or via backups.
**Prevention:** Always use secure storage mechanisms like flutter_secure_storage (which uses KeyStore on Android and Keychain on iOS) for storing sensitive credentials.
