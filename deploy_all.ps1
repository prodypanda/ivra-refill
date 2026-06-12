flutter build apk --release --dart-define=SUPABASE_URL="https://tozmdkasyzdzrbhvfxis.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_oxa275DytFvFQNOmmtWelg_8Dc2aLod"
.\deploy\assemble_public.ps1 -SupabaseUrl "https://tozmdkasyzdzrbhvfxis.supabase.co" -SupabaseAnonKey "sb_publishable_oxa275DytFvFQNOmmtWelg_8Dc2aLod"
firebase deploy --only hosting
