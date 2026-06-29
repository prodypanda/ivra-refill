
## 2026-06-29 - Fixed generic FOR ALL policies and legacy plaintext passwords
**Vulnerability:** Found a loop in an early migration that created dynamic `FOR ALL` policies checking only `has_hotel_access(hotel_id)` for several core tables, effectively bypassing RBAC mutations. Also found that legacy plaintext passwords were not being scrubbed from `SharedPreferences` when migrating to `flutter_secure_storage`.
**Learning:** `FOR ALL` policies are risky when coupled with generic access functions because they grant full CRUD access. Legacy data migrations must prioritize the deletion of the insecure source data.
**Prevention:** Always restrict multi-tenant `has_hotel_access` policies to `FOR SELECT` only. Implement strict, explicit policies or rely on `SECURITY DEFINER` RPCs for mutations. Ensure cleanup logic immediately follows legacy read access during security migrations.
