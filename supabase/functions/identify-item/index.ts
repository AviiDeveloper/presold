// identify-item — photo(s) → Haiku vision → universal item data
// Requires user JWT. Called by iOS Capture flow.
//
// See ../../docs/ai-prompts.md (Prompt 1) for the prompt this uses.
// Bump version in lockstep with the prompt.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 2, Day 3-4
  // 1. Validate JWT
  // 2. Read photo URLs from request body
  // 3. Call Anthropic API with Prompt 1
  // 4. Return JSON matching shared/types/item.schema.json
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    { status: 501, headers: { "Content-Type": "application/json" } },
  );
});
