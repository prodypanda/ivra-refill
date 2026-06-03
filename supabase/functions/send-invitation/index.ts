import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const payload = await req.json()
    
    // We only care about INSERT and UPDATE events on the user_invitations table
    if (payload.type !== 'INSERT' && payload.type !== 'UPDATE') {
      return new Response('Not an insert or update event', { status: 200 })
    }

    const record = payload.record
    const oldRecord = payload.old_record

    // If it's an UPDATE, verify that it's a "Resend" action.
    // Our database function resend_team_invitation() updates the `created_at` field.
    if (payload.type === 'UPDATE') {
      if (record.created_at === oldRecord.created_at) {
        return new Response('Update event, but not a resend request (created_at unchanged). Skipping.', { status: 200 })
      }
      
      if (record.status !== 'pending') {
        return new Response('Invitation is no longer pending. Skipping.', { status: 200 })
      }
    }

    const email = record.email

    if (!email) {
      return new Response('No email address provided in the record', { status: 400 })
    }

    // Initialize the Supabase admin client
    // These environment variables are automatically injected by Supabase Edge Functions
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Call the native Supabase invite endpoint, which automatically sends the SMTP email
    const { data, error } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
      data: {
        invitation_id: record.id,
        role: record.role,
        full_name: record.full_name
      }
    })

    if (error) {
      throw error
    }

    return new Response(JSON.stringify({ success: true, user: data }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error) {
    console.error('Error sending invitation:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    })
  }
})
