# [Week 1, Day 3–end] Scan flow shipped + refinements + Week 1 closed

## Goal

Build the free `/scan` price scanner end-to-end and iterate it from "wired up"
to "working in a charity shop on a phone." This entry consolidates PRs #5
through #12 (the full scan-flow arc) plus the Week 1 close-out PR — one
retrospective log because they're all the same body of work, shipped as small
ships over a single working day.

## PLAN.md section

Week 1, Day 3-4 (`/scan` page + API + AI + comps + storage + DB) followed by
incremental refinements driven by real-world testing on a live Vercel deploy.

Week 1 D5 (shareable result page + OG image) **descoped** at the user's
direction — the inline result view is enough for v1; the first TikTok is a
marketing action.

## What shipped

### PR #5 — scan flow end-to-end ([feat: add /scan price scanner end-to-end](https://github.com/AviiDeveloper/presold/pull/5))

- `web/lib/types.ts` mirroring `shared/types/*.schema.json` (Item,
  PriceGuidance, EbayComp, Platform, ItemCondition, SellSpeed).
- `web/lib/anthropic.ts` (later renamed `ai.ts`) — Haiku 4.5 client with
  `identifyItem` (Prompt 1) and `suggestPrice` (Prompt 3).
- `web/lib/ebay.ts` — official eBay Marketplace Insights wrapper with
  broaden-on-sparse + 24h sha256 comp cache (later replaced as the active
  path; kept for switch-back, see ADR-005).
- `web/lib/rate-limit.ts` — 3-scans-per-IP-per-day in-memory limiter.
- `web/lib/scan.ts` — orchestrator: validate → identify → comps →
  guidance → upload to `scan-photos` → insert `price_scans` row.
- `web/app/api/scan/route.ts` — multipart POST handler.
- `web/app/scan/page.tsx` + `scan-form.tsx` — server shell + client form with
  mobile camera capture and inline result view.

Also fixed a pre-existing migration bug discovered during the first apply:
`supabase/migrations/20260513000001_initial_schema.sql` had a subquery in an
index expression, which Postgres rejects. Replaced with
`sales_item_sold_idx` on `(item_id, sold_at desc)`. Profit view will join
via items.

ADR-004 added: AI gateway via OpenRouter (temporary while Anthropic billing
pending). Env var: `OPEN_ROUTER_API_KEY` (underscored to match Vercel's
existing config).

ADR-005 added: Apify as eBay comp source via `caffein.dev/ebay-sold-listings`
(temporary while Marketplace Insights production approval is in queue). Env
var: `APIFY_TOKEN`.

### PR #6 — hotfix scan timeout ([hotfix: extend /api/scan maxDuration to 60s](https://github.com/AviiDeveloper/presold/pull/6))

First real phone scan timed out at Vercel Hobby's 10s default function
duration. Added `export const maxDuration = 60;` to the route handler.

### PR #7 — prompt v1.1 → v1.2 ([feat(prompts): tighten brand/size identification](https://github.com/AviiDeveloper/presold/pull/7))

Same YSL jacket got confidently labelled "Disney" on v1.1. v1.2 adds explicit
"trust visible labels and tags only; never infer brand from cut, silhouette,
graphic typography, or design-language similarity" language. Cites UK
marketplace bans for counterfeit mis-labelling as the reason. Same rule for
size.

### PR #8 — client-side compression ([feat(scan): compress photo on client before upload](https://github.com/AviiDeveloper/presold/pull/8))

iPhone camera photos (5–10MB) exceeded Vercel Hobby's ~4.5MB request body
limit; the request never reached the function. Added
`web/lib/image-compress.ts` — canvas-based resize to 1600px + JPEG quality
0.85, dropping typical phone photos to ~300–800KB. Falls back to original
file on any failure.

### PR #9 — Sonnet 4.6 upgrade ([feat(ai): upgrade scanner model Haiku 4.5 → Sonnet 4.6](https://github.com/AviiDeveloper/presold/pull/9))

Even with v1.2's stricter prompt, Haiku still wasn't reading visible logos
reliably. Bumped the model to `anthropic/claude-sonnet-4-6`. ADR-006 added
documenting why, cost impact (~3x: $0.002 → $0.006 per scan), and the
switch-back trigger (drop to Haiku once we hit the 75% DoD accuracy bar with
a refined prompt or multi-photo).

PLAN.md §1 and root `CLAUDE.md` updated to reflect the new model.
`docs/ai-prompts.md` header updated. Prompt version constants unchanged
(content identical, only the executing model changed).

**Verified working**: same YSL jacket photo now returns
`brand: "Yves Saint Laurent"`, confidence 0.72, with 20 GBP comps anchoring
a £80 recommended price.

### PR #10 — allow library upload ([feat(scan): allow library upload, not just camera](https://github.com/AviiDeveloper/presold/pull/10))

Removed `capture="environment"` from the file input. iOS Safari now offers
the standard picker: Take Photo / Photo Library / Choose File. Matches the
real workflow — resellers often batch-photograph items, list them later.

### PR #11 — single-photo accuracy bundle ([feat(scan): single-photo accuracy + speed for on-the-go use](https://github.com/AviiDeveloper/presold/pull/11))

User clarified the canonical use case: standing in a charity/thrift shop,
one snap per item, no time to reshoot. Three coordinated tweaks:
- Prompt v1.2 → v1.3 with a new top paragraph telling the model "this is
  the ONLY photo you will see; scan the entire image methodically — front
  and back, neckline, collar, cuffs, hem, every visible tag/hangtag/care-
  label/embossed mark/embroidery, read text in any orientation."
- `MAX_RESULTS` 20 → 12 in Apify (still well above the 3-comp minimum;
  saves ~30% of actor runtime).
- Copy rewrite: photo helper nudges "include any visible brand label or
  size tag in the frame"; category-hint becomes "What is it? (optional, but
  helps a lot)" with reseller-shaped examples.

Image resolution stays at 1600px (Anthropic vision downsamples to ~1568px
internally, larger uploads waste bandwidth).

### PR #12 — single-tier Apify hotfix ([hotfix(scan): single-tier Apify query, drop broaden-on-sparse](https://github.com/AviiDeveloper/presold/pull/12))

After PR #11 merged, user retried and got "Couldn't reach the server."
Apify's run log showed two scan attempts each triggering broaden-on-sparse
across three tiers (full → drop-size → drop-brand), at ~30s per Apify cold
start. Three sequential tiers exceed the 60s function ceiling → function
killed → no body returned.

Fix: do a single specific query; if comps are sparse, the price-guidance
prompt is already designed to flag low confidence honestly. Removed
`MIN_USEFUL_COMPS` constant (now unused).

### PR (this) — Week 1 close-out

- PLAN.md §4: Week 1 marker 🚧 → ✅. D5 marked descoped (with reason).
  Week 2 marker ⏳ → 🚧 with the Xcode bootstrap recipe linked.
- `docs/sessions/NEXT_SESSION.md` fully rewritten for the cumulative
  Week 1 state. Production URL captured. Week 2 bootstrap recipe
  written out step by step (the `.xcodeproj` has to be created in Xcode;
  Claude can't reliably generate one from chat).
- This session log added as the consolidated mirror of PRs #5–#12 plus
  this close-out PR.

## Why (decisions, trade-offs)

The arc this session went on:
1. Ship the wiring.
2. Discover real-world timing and size constraints (Vercel timeouts,
   request-body limits, iPhone photo sizes).
3. Discover real-world accuracy gaps (Haiku confidently wrong on logos).
4. Iterate model and prompt until accuracy is good enough on single
   photos — the canonical use case.
5. Discover the Apify broaden-on-sparse loop was a hidden time bomb on
   cold starts.
6. Land the final shape: Sonnet 4.6 + Prompt v1.3 + single-tier Apify
   + client-side compression + library upload. ~40–60s end-to-end on
   a real phone, correct identification of YSL jacket with sensible
   price guidance.

Three architectural decisions documented as temporary in ADRs:
- **ADR-004**: OpenRouter as AI gateway (switch back to direct Anthropic
  when billing is enabled).
- **ADR-005**: Apify as comp source (switch back to eBay Marketplace
  Insights when production approval lands).
- **ADR-006**: Sonnet 4.6 instead of the PLAN-locked Haiku 4.5 (drop back
  to Haiku if accuracy holds on a refined prompt or with multi-photo).

Each carries its own switch-back trigger so we don't accumulate technical
debt by accident.

D5 (shareable result page + OG image) descoped at user direction. The
inline result view on `/scan` is sufficient for the v1 funnel.

## Files touched

Across the eight PRs covered here, the working set is roughly:

- `web/lib/` — `ai.ts` (was `anthropic.ts`), `apify-ebay.ts`, `comps.ts`,
  `ebay.ts`, `image-compress.ts`, `rate-limit.ts`, `scan.ts`, `types.ts`
- `web/app/scan/` — `page.tsx`, `scan-form.tsx`
- `web/app/api/scan/route.ts`
- `web/.env.local.example` + private `.env.local` (gitignored)
- `web/package.json` — drop `@anthropic-ai/sdk`
- `supabase/migrations/20260513000001_initial_schema.sql` — sales index fix
- `docs/ai-prompts.md` — Prompt 1 v1.0 → v1.1 → v1.2 → v1.3; Prompt 3
  v1.0 → v1.1
- `shared/types/item.schema.json`, `shared/types/price-guidance.schema.json`
- `docs/decisions/004-openrouter-temporary-ai-gateway.md` (new)
- `docs/decisions/005-apify-for-ebay-comps.md` (new)
- `docs/decisions/006-sonnet-for-vision.md` (new)
- `PLAN.md` — §1 stack updates + Week 1 close
- `CLAUDE.md` (root) — model references
- `docs/sessions/NEXT_SESSION.md` — full rewrite for cumulative state
- `docs/sessions/2026-05-13-04-week-1-scan-flow.md` (this file)

## Verification

- `npm run typecheck` / `lint` / `build` clean throughout
- Live smoke tests on `presold-three.vercel.app/scan` on a real iPhone,
  picking the YSL jacket photo from the library:
  - PR #5 result: brand "Disney", confidence 0.85 ❌
  - PR #7 (v1.2): brand null, confidence 0.6 (honest)
  - PR #9 (Sonnet): brand "Yves Saint Laurent", confidence 0.72, £80
    recommended from 20 comps ✅
- Supabase MCP queries verified `price_scans` rows + `scan-photos` bucket
  uploads end-to-end.
- Apify run logs cross-checked to diagnose timeout failures.

## What's next

`week-2/ios-scaffold` per PLAN.md §4 Week 2 D1-2. The Xcode project has to be
created in Xcode itself (Claude Code can't reliably generate a `.xcodeproj`
from chat) — bootstrap recipe is in `docs/sessions/NEXT_SESSION.md`. Once
the project file is committed, the Swift models, services, and views can be
written into it.

Alternative direction the user is considering: reopen ADR-001 and pull
cross-listing automation forward. Would require:
- Revisiting the App Store risk analysis
- Architectural choice (WKWebView vs. server-side headless vs. extension)
- Realistic build estimate (likely +2–3 weeks)

Not started; waiting for explicit go-ahead.

## AI assistance

Co-developed with Claude Code (Claude Opus 4.7). See commits for
`Co-Authored-By` lines.

## Outcome

- PRs: #5, #6, #7, #8, #9, #10, #11, #12, plus this close-out PR
- Final `main` after this close-out merges: TBD
- Production URL: https://presold-three.vercel.app
