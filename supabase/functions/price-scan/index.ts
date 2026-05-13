// price-scan — public endpoint for the free web scanner
// No auth, rate-limited by IP.
//
// Called by web/app/api/scan/route.ts.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 1, Day 3-4
  // 1. Check rate limit (3/IP/day)
  // 2. Receive photo, upload to scan-photos bucket
  // 3. Call identify-item logic (Prompt 1)
  // 4. Call ebay-comps for sold comp data
  // 5. Call Prompt 3 for price guidance
  // 6. Insert into price_scans table
  // 7. Return result with shareable_slug
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    { status: 501, headers: { "Content-Type": "application/json" } },
  );
});
