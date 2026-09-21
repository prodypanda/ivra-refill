-- Migration: 20260710000000_app_settings.sql
-- Creates global app_settings table with real-time replication and RLS

CREATE TABLE IF NOT EXISTS public.app_settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  updated_at timestamptz DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id)
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read settings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'app_settings' AND policyname = 'Allow read app_settings'
  ) THEN
    CREATE POLICY "Allow read app_settings" ON public.app_settings
      FOR SELECT USING (true);
  END IF;
END $$;

-- Allow superadmin to insert/update settings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'app_settings' AND policyname = 'Allow superadmin write app_settings'
  ) THEN
    CREATE POLICY "Allow superadmin write app_settings" ON public.app_settings
      FOR ALL TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
          AND profiles.role = 'app_admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
          AND profiles.role = 'app_admin'
        )
      );
  END IF;
END $$;

-- Enable Supabase Realtime for app_settings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'app_settings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_settings;
  END IF;
END $$;

-- Seed default record
INSERT INTO public.app_settings (key, value)
VALUES ('app_theme_style', '"solar_infusion"')
ON CONFLICT (key) DO NOTHING;
