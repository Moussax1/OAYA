// supabase/functions/stripe-webhook/index.ts
// Deno Edge Function to receive Stripe webhooks, verify signature,
// update the corresponding order in the database and create notifications.
// Deploy with: supabase functions deploy stripe-webhook --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { importPKCS8, SignJWT } from "https://esm.sh/jose@4.14.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, stripe-signature",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Helper to get FCM HTTP v1 access token from service account (base64 encoded JSON)
    async function getFcmAccessToken(): Promise<string | null> {
      try {
        const saBase64 = Deno.env.get('FCM_SERVICE_ACCOUNT_BASE64');
        if (!saBase64) return null;
        const saJson = atob(saBase64);
        const sa = JSON.parse(saJson);
        const privateKey = sa.private_key as string;
        const key = await importPKCS8(privateKey, 'RS256');
        const jwt = await new SignJWT({ scope: 'https://www.googleapis.com/auth/firebase.messaging' })
          .setProtectedHeader({ alg: 'RS256' })
          .setIssuer(sa.client_email)
          .setSubject(sa.client_email)
          .setAudience('https://oauth2.googleapis.com/token')
          .setIssuedAt()
          .setExpirationTime('1h')
          .sign(key);

        const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`,
        });
        if (!tokenResp.ok) return null;
        const data = await tokenResp.json();
        return data.access_token as string | null;
      } catch (_) {
        return null;
      }
    }
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
      apiVersion: "2023-10-16",
      httpClient: Stripe.createFetchHttpClient(),
    });

    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") || "";
    if (!webhookSecret) {
      return new Response(JSON.stringify({ error: 'Missing STRIPE_WEBHOOK_SECRET' }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Read raw body as Uint8Array for signature verification
    const buf = await req.arrayBuffer();
    const payload = new Uint8Array(buf);
    const sig = req.headers.get("stripe-signature") || "";

    let event;
    try {
      event = stripe.webhooks.constructEvent(payload, sig, webhookSecret);
    } catch (err) {
      return new Response(JSON.stringify({ error: 'Invalid webhook signature' }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const type = event.type;
    const obj = event.data?.object || {};
    const paymentIntentId = obj.id;

    // Supabase REST endpoint and service role key
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!supabaseUrl || !serviceKey) {
      return new Response(JSON.stringify({ error: 'Missing SUPABASE configuration' }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Find matching order by stripe_payment_id
    const encodedPid = encodeURIComponent(paymentIntentId);
    const ordersResp = await fetch(`${supabaseUrl}/rest/v1/orders?stripe_payment_id=eq.${encodedPid}`, {
      headers: {
        'apikey': serviceKey,
        'Authorization': `Bearer ${serviceKey}`,
        'Accept': 'application/json',
      },
    });

    if (!ordersResp.ok) {
      return new Response(JSON.stringify({ error: 'Failed querying orders' }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const orders = await ordersResp.json();
    if (!orders || orders.length === 0) {
      // No matching order — acknowledge webhook
      return new Response(JSON.stringify({ received: true, note: 'no_order' }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const order = orders[0];
    const orderId = order.id;

    if (type === 'payment_intent.succeeded') {
      // Idempotency: only update if not already marked paid
      if (order.status !== 'paid') {
        await fetch(`${supabaseUrl}/rest/v1/orders?id=eq.${orderId}`, {
          method: 'PATCH',
          headers: {
            'apikey': serviceKey,
            'Authorization': `Bearer ${serviceKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ status: 'paid', paid_at: new Date().toISOString() }),
        });

        // Create an in-app notification
        await fetch(`${supabaseUrl}/rest/v1/notifications`, {
          method: 'POST',
          headers: {
            'apikey': serviceKey,
            'Authorization': `Bearer ${serviceKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ user_id: order.user_id, title: 'Paiement confirmé', body: `Votre paiement pour la commande #${orderId.toString().substring(0,8)} a été reçu.` }),
        });

        // Send push via FCM: prefer HTTP v1 (service account) then fallback to legacy server key
        try {
          const profileResp = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${order.user_id}`, {
            headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Accept': 'application/json' },
          });
          if (profileResp.ok) {
            const profiles = await profileResp.json();
            const profile = (profiles && profiles[0]) || null;
            const token = profile?.fcm_token;
            const legacyServerKey = Deno.env.get('FCM_SERVER_KEY');

            // Attempt FCM HTTP v1 with service account
            const accessToken = await getFcmAccessToken();
            if (token && accessToken && Deno.env.get('FCM_PROJECT_ID')) {
              try {
                await fetch(`https://fcm.googleapis.com/v1/projects/${Deno.env.get('FCM_PROJECT_ID')}/messages:send`, {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': `Bearer ${accessToken}`,
                  },
                  body: JSON.stringify({
                    message: {
                      token: token,
                      notification: { title: 'Paiement confirmé', body: `Votre commande #${orderId.toString().substring(0,8)} est payée.` },
                      data: { order_id: orderId.toString() },
                    },
                  }),
                });
              } catch (_) {
                // if HTTP v1 fails, fall back to legacy key if available
              }
            }

            // Fallback to legacy server key if HTTP v1 not available or failed
            if (token && (!Deno.env.get('FCM_SERVICE_ACCOUNT_BASE64') || !Deno.env.get('FCM_PROJECT_ID'))) {
              if (token && legacyServerKey) {
                try {
                  await fetch('https://fcm.googleapis.com/fcm/send', {
                    method: 'POST',
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': `key=${legacyServerKey}`,
                    },
                    body: JSON.stringify({
                      to: token,
                      notification: { title: 'Paiement confirmé', body: `Votre commande #${orderId.toString().substring(0,8)} est payée.` },
                      data: { order_id: orderId.toString() },
                    }),
                  });
                } catch (_) {}
              } else {
                console.warn('FCM push skipped: no FCM HTTP v1 credentials and no legacy server key.');
              }
            }
          }
        } catch (_) {}

        // Trigger send-order-email function (fire-and-forget)
        try {
          await fetch(`${supabaseUrl}/functions/v1/send-order-email`, {
            method: 'POST',
            headers: {
              'apikey': serviceKey,
              'Authorization': `Bearer ${serviceKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ order_id: orderId.toString() }),
          });
        } catch (_) {}
      }
    }

    if (type === 'payment_intent.payment_failed') {
      await fetch(`${supabaseUrl}/rest/v1/orders?id=eq.${orderId}`, {
        method: 'PATCH',
        headers: {
          'apikey': serviceKey,
          'Authorization': `Bearer ${serviceKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status: 'failed' }),
      });

      await fetch(`${supabaseUrl}/rest/v1/notifications`, {
        method: 'POST',
        headers: {
          'apikey': serviceKey,
          'Authorization': `Bearer ${serviceKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user_id: order.user_id, title: 'Paiement échoué', body: `Le paiement de la commande #${orderId.toString().substring(0,8)} a échoué.` }),
      });
    }

    return new Response(JSON.stringify({ received: true }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
