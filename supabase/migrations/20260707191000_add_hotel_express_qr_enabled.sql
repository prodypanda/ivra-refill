-- Migration: Add express_qr_enabled to hotels
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS express_qr_enabled BOOLEAN DEFAULT FALSE;
