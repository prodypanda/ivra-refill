
## 2024-06-16 - Secure Local Storage & RLS Hardening
**Vulnerability:** The app stored biometric unlock passwords in plaintext using `SharedPreferences`, exposing credentials to device compromise. Additionally, Supabase RPCs `approve_change_request` and `reject_change_request` allowed users to potentially approve their own requests, and the `has_hotel_access` function did not properly authorize the `app_manager` role.
**Learning:** Security Definier Postgres functions must explicitly check self-referencing operations (e.g. self-approval). Plaintext local storage should never hold passwords. Always ensure custom RBAC functions cover all intermediate managerial roles in the hierarchy.
**Prevention:** Use `flutter_secure_storage` for credentials and scrub legacy plaintext values. Implement explicit checks `v_request.requested_by != auth.uid()` in RLS policies or RPCs. Include comprehensive tests for credential migration.
