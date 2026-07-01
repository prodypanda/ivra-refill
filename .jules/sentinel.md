## 2024-05-24 - Fix plain-text password leakage in SharedPreferences
**Vulnerability:** A legacy plain-text password `AuthPrefs.legacyPassword` was migrating to `flutter_secure_storage` but was never scrubbed from `SharedPreferences`, causing the sensitive data to leak permanently on disk.
**Learning:** The previous implementation failed to properly follow through on zero-trust principles where legacy insecure data should be proactively destroyed.
**Prevention:** We must always clean up legacy storage configurations after migrations, preferably after checking the target is persisted. Eager deletion on provider init breaks migration flows, so migration targets must scrub their insecure sources upon success.
