## 2026-06-25 - Critical RLS and Local Storage Vulnerabilities

**Vulnerability:**
1. The dynamic RLS loop in `0002_multi_hotel_support.sql` incorrectly granted `FOR ALL` (including INSERT, UPDATE, DELETE) access to `hotel_staff` for critical tables like `approval_requests`, `hotels`, `room_products`, allowing them to bypass the `approve_change_request` RPC and manually alter approval statuses.
2. A legacy global plaintext password (`AuthPrefs.legacyPassword`) was left behind in `SharedPreferences` without being cleaned up, leaving sensitive credentials exposed on the device filesystem.

**Learning:**
1. Never use dynamic `FOR ALL` policies when handling multi-tenant tables. `has_hotel_access` is appropriate for `SELECT` operations, but mutations must always verify role hierarchy (e.g., `hotel_manager` vs `hotel_staff`) or be strictly limited to `SECURITY DEFINER` RPCs.
2. When migrating credentials to secure storage (`flutter_secure_storage`), always forcefully purge legacy plaintext values from `SharedPreferences` in initialization/load routines, not just during targeted operations.

**Prevention:**
1. Use explicit, separate policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE`. Treat the client (and standard API access) as hostile.
2. Ensure explicit key deletion for all legacy authentication tokens in `SharedPreferences`.
