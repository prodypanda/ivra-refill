import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";
import firebaseKey from "./firebase-key.json" assert { type: "json" };

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function getAccessToken() {
  const privateKey = firebaseKey.private_key;
  const clientEmail = firebaseKey.client_email;

  const jwt = await new jose.SignJWT({
    iss: clientEmail,
    sub: clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    scope: "https://www.googleapis.com/auth/firebase.messaging"
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(await jose.importPKCS8(privateKey, 'RS256'));

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Error getting access token: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error("Missing Authorization header");
    
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
    if (userError || !user) throw new Error("Unauthorized");

    const { title, body, targetType, targetValue, actionButtons, targetPage, data } = await req.json();
    if (!title || !body || !targetType) {
      throw new Error("Missing required fields");
    }

    const { data: profile } = await supabaseAdmin.from('profiles').select('role, hotel_id').eq('id', user.id).single();
    if (!profile) {
      throw new Error("User profile not found");
    }
    
    // Check if user has permission
    if (profile.role === 'hotel_manager' || profile.role === 'hotel_staff') {
       const isSendingToOwnHotel = targetType === 'hotel' && targetValue === profile.hotel_id;
       if (!isSendingToOwnHotel) {
           throw new Error("Insufficient permissions: You can only send notifications to your own hotel.");
       }
    } else if (profile.role !== 'app_admin' && profile.role !== 'app_manager') {
       throw new Error("Insufficient permissions");
    }

    let targetUserIds: string[] | null = null;

    if (targetType === 'hotel') {
      const { data: p } = await supabaseAdmin
        .from('profiles')
        .select('id')
        .or(`hotel_id.eq.${targetValue},role.in.(app_admin,app_manager)`);
      targetUserIds = p?.map(x => x.id) || [];
    } else if (targetType === 'role') {
      const { data: p } = await supabaseAdmin.from('profiles').select('id').eq('role', targetValue);
      targetUserIds = p?.map(x => x.id) || [];
    } else if (targetType === 'user') {
      const { data: p } = await supabaseAdmin.from('profiles').select('id').eq('email', targetValue);
      targetUserIds = p?.map(x => x.id) || [];
    } else if (targetType !== 'all') {
      throw new Error("Invalid targetType");
    }

    let tokensQuery = supabaseAdmin.from('user_fcm_tokens').select('token');
    
    if (targetUserIds !== null) {
      if (targetUserIds.length === 0) {
        return new Response(JSON.stringify({ message: "No target users found" }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        });
      }
      tokensQuery = tokensQuery.in('user_id', targetUserIds);
    }

    const { data: tokensData, error: tokensError } = await tokensQuery;
    if (tokensError) throw tokensError;

    if (!tokensData || tokensData.length === 0) {
      return new Response(JSON.stringify({ message: "No target users found" }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const tokens = [...new Set(tokensData.map(t => t.token))];
    const accessToken = await getAccessToken();

    const results = { successCount: 0, failureCount: 0, errors: [] as any[] };

    // Send notifications in batches or individually
    const sendPromises = tokens.map(async (token) => {
      const messageObj: any = {
        token,
        data: {
          ...(data || {}),
          title: title,
          body: body,
          targetPage: targetPage || '',
          actionButtons: actionButtons ? JSON.stringify(actionButtons) : '',
        },
        android: {
          priority: "high",
          notification: {
            sound: "default"
          }
        },
        apns: {
          payload: {
            aps: {
              "content-available": 1,
              sound: "default"
            }
          }
        }
      };

      // If action buttons are provided, we must use a data-only message so we can render them locally.
      // Otherwise, the OS will display a default notification without buttons.
      if (!actionButtons || actionButtons.length === 0) {
        messageObj.notification = { title, body };
      } else {
        // Remove android.notification so it remains data-only on Android.
        delete messageObj.android.notification;
      }

      const message = { message: messageObj };

      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${firebaseKey.project_id}/messages:send`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`
        },
        body: JSON.stringify(message)
      });

      const resData = await res.json();
      if (res.ok) {
        results.successCount++;
      } else {
        results.failureCount++;
        results.errors.push({ token, error: resData.error });
        // Optional: Delete token if it's UNREGISTERED
        if (resData.error?.details?.[0]?.errorCode === 'UNREGISTERED') {
          await supabaseAdmin.from('user_fcm_tokens').delete().eq('token', token);
        }
      }
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify(results), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
