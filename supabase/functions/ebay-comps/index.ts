// ebay-comps — internal endpoint for sold comp lookup
// Called by identify-item and price-scan. Caches results.
//
// See ../../docs/ebay-api-notes.md for API details.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 1, Day 3-4 (web tool first, then iOS uses it)
  // 1. Hash query, check cache
  // 2. OAuth client_credentials grant if needed (cache token 2hr)
  // 3. Call Marketplace Insights API with progressive broadening
  // 4. Cache result 24hr
  // 5. Return normalised comps array
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    { status: 501, headers: { "Content-Type": "application/json" } },
  );
});
