## 2025-02-14 - Fix unencrypted global legacy password leak
**Vulnerability:** A legacy `legacyPassword` (saved password) key was stored globally in plaintext in SharedPreferences and not properly scrubbed upon logging in, restoring passwords, or loading BiometricAccountNotifier state.
**Learning:** Legacy fields from previous auth implementations can silently linger and leak secrets if they are not explicitly dropped when migrating credentials to secure storage.
**Prevention:** Ensure exhaustive key scrubbing when transitioning away from unencrypted storage to secure hardware-backed storage for credentials. Double-check all legacy key references.
