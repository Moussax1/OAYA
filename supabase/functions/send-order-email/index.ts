// supabase/functions/send-order-email/index.ts
// @ts-nocheck — This is a Deno Edge Function, not a Node.js file
// Deploy: supabase functions deploy send-order-email --no-verify-jwt
// Required secrets: MAILTRAP_API_TOKEN, MAILTRAP_SENDER_EMAIL, SUPABASE_SERVICE_ROLE_KEY

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { order_id, user_email } = await req.json();

    if (!order_id || !user_email) {
      return new Response(
        JSON.stringify({ error: "order_id and user_email are required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch order details using service role (bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("*, order_items(*, product:products(name, price))")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ error: "Order not found." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build email HTML
    const itemsHtml = (order.order_items || [])
      .map(
        (item: any) =>
          `<tr>
            <td style="padding: 8px; border-bottom: 1px solid #eee;">${item.product?.name || "Produit"}</td>
            <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
            <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">${(item.unit_price * item.quantity).toFixed(2)} TND</td>
          </tr>`
      )
      .join("");

    const emailHtml = `
      <div style="font-family: 'Inter', Arial, sans-serif; max-width: 600px; margin: auto; background: #fff; border: 1px solid #eee; border-radius: 12px; overflow: hidden;">
        <div style="background: #111; padding: 24px; text-align: center;">
          <h1 style="color: #C9A96E; margin: 0; letter-spacing: 6px;">OAYA</h1>
          <p style="color: #999; margin: 4px 0 0; font-size: 12px;">Confirmation de commande</p>
        </div>
        <div style="padding: 24px;">
          <h2 style="color: #111; margin: 0 0 8px;">Commande confirmée !</h2>
          <p style="color: #666; font-size: 14px;">Merci pour votre achat. Voici le récapitulatif de votre commande.</p>
          <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
            <thead>
              <tr style="background: #f9f9f9;">
                <th style="padding: 8px; text-align: left; font-size: 12px; color: #999;">ARTICLE</th>
                <th style="padding: 8px; text-align: center; font-size: 12px; color: #999;">QTÉ</th>
                <th style="padding: 8px; text-align: right; font-size: 12px; color: #999;">PRIX</th>
              </tr>
            </thead>
            <tbody>${itemsHtml}</tbody>
          </table>
          <div style="text-align: right; border-top: 2px solid #111; padding-top: 12px;">
            <span style="font-size: 18px; font-weight: 700; color: #111;">Total: ${order.total_amount?.toFixed(2) || "0.00"} TND</span>
          </div>
          <p style="color: #999; font-size: 12px; margin-top: 24px;">N° Commande: #${order_id.substring(0, 8).toUpperCase()}</p>
          <p style="color: #999; font-size: 12px;">Livraison estimée: 3 à 5 jours ouvrés</p>
        </div>
        <div style="background: #f9f9f9; padding: 16px; text-align: center;">
          <p style="color: #999; font-size: 11px; margin: 0;">OAYA Store — Votre monde du style</p>
        </div>
      </div>
    `;

    // Send via Mailtrap API
    const mailtrapToken = Deno.env.get("MAILTRAP_API_TOKEN");
    const senderEmail = Deno.env.get("MAILTRAP_SENDER_EMAIL") || "noreply@oaya.store";

    const emailResponse = await fetch("https://send.api.mailtrap.io/api/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Api-Token": mailtrapToken!,
      },
      body: JSON.stringify({
        from: { email: senderEmail, name: "OAYA Store" },
        to: [{ email: user_email }],
        subject: `OAYA — Confirmation de commande #${order_id.substring(0, 8).toUpperCase()}`,
        html: emailHtml,
      }),
    });

    const emailResult = await emailResponse.json();

    return new Response(
      JSON.stringify({ success: true, email_result: emailResult }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Email error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
