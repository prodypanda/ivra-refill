## 2024-07-03 - Prevent Privilege Escalation in profiles Table
**Vulnerability:** The RLS policy for updating the `profiles` table lacked a `WITH CHECK` clause, allowing users to modify sensitive columns like `role` and `hotel_id` (privilege escalation).
**Learning:** Supabase RLS `UPDATE` policies without a `WITH CHECK` clause allow modifying any column. While `WITH CHECK` can restrict the new row state, its difficult to prevent specific column modifications (like ensuring `role` hasnt changed) using just RLS policies without creating complex comparisons.
**Prevention:** Use `BEFORE UPDATE` triggers to explicitly block modifications to sensitive columns (like roles, foreign keys, or active statuses) by unauthorized users, providing a more robust defense than simple RLS policies.
