-- Migration: Add express_qr_enabled to hotels and update hotel_summaries view
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS express_qr_enabled BOOLEAN DEFAULT FALSE;

-- Recreate hotel_summaries view to include express_qr_enabled
DROP VIEW IF EXISTS public.hotel_summaries;
CREATE VIEW public.hotel_summaries AS
SELECT
    h.id,
    h.name,
    h.legal_name,
    h.contact_name,
    h.phone,
    h.email,
    h.address,
    h.city,
    h.country,
    h.notes,
    h.created_by,
    h.created_at,
    h.updated_at,
    count(DISTINCT r.id)::integer AS room_count,
    count(ar.id) FILTER (WHERE ar.status = 'pending'::approval_status)::integer AS pending_edits,
    h.express_qr_enabled
FROM hotels h
LEFT JOIN rooms r ON r.hotel_id = h.id
LEFT JOIN approval_requests ar ON ar.hotel_id = h.id
GROUP BY h.id;
