// parse-sale-email — inbound email webhook for sale detection
// User forwards Vinted/Depop/eBay sale notifications to <token>@sales.presold.app
//
// Webhook from email forwarding provider (e.g. Postmark inbound, Cloudflare Email Workers)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 3, Day 4
  // 1. Validate webhook signature
  // 2. Extract token from to-address
  // 3. Look up user by sale_email_token
  // 4. Parse email: detect platform from sender, extract item/price
  // 5. Match to item in DB (by title fuzzy match, then by manual review queue)
  // 6. Insert into sales, mark item sold
  // 7. Failed parses → log to manual review table
  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
