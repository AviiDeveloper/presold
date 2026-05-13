# 005. Use Apify for eBay sold comps while waiting for Marketplace Insights

Date: 2026-05-13
Status: Accepted (temporary)

## Context

`docs/ebay-api-notes.md` already names this fallback:

> Edge function scrapes eBay UK sold listings page with rotating User-Agents.
> Same query syntax in URL. Parse with cheerio in Deno edge runtime. Slower,
> fragile, but unblocks the v1 launch if eBay drags on approval.
> Document this as a temporary measure in an ADR if you build it.

eBay Marketplace Insights production access is under review (~5 business
days). The Week 1 scanner ships without real comps until that lands, which
undercuts the value-prop on the first TikTok. We already have an Apify
account with credit — Apify outsources the scrape + proxy rotation +
captcha handling that an in-house edge function would have to build.

## Decision

Use Apify's `caffein.dev/ebay-sold-listings` actor as the temporary comp
source. Called synchronously via the Apify REST endpoint
`/v2/acts/.../run-sync-get-dataset-items`, no polling needed.

- Actor reliably returns ebay.co.uk sold listings in GBP (confirmed in
  smoke test: 10/10 results in ~10s).
- 894 monthly users and 97.6% success rate — battle-tested compared to
  the lite alternative that was 403-blocked by eBay UK on first call.
- Pricing: $0.004 per result + ~$0.00005 actor start. With our
  3-scans-per-IP-per-day cap and the 24h sha256-keyed comp cache, the
  expected steady-state cost stays low.

We keep the official `web/lib/ebay.ts` Marketplace Insights client
intact. A small router in `web/lib/scan.ts` picks `apify-ebay` when
`APIFY_TOKEN` is set, otherwise falls back to the official client.

## Switch-back trigger

Switch to **eBay Marketplace Insights direct** when:
- eBay grants production access for the project's App ID, AND
- A side-by-side comparison on ~30 real reseller queries shows the
  official API returns at least as many GBP-priced GB-marketplace
  results per query.

Switch is a one-line flip: remove `APIFY_TOKEN` from `web/.env.local` and
Vercel; the router falls through to `lib/ebay.ts` automatically.

## Alternatives considered

- **Wait for Marketplace Insights approval.** Blocks the first TikTok by
  ~5 business days. Unacceptable.
- **Build the scrape ourselves in a Supabase edge function** (the
  original `ebay-api-notes.md` fallback). Means we own proxy rotation,
  bot detection, HTML drift. Apify already does this. Save the build
  effort.
- **Use `astronomical_reception/ebay-sold-lite`.** Tried first — cheaper
  flat rate ($0.05/run) and faster (<10s, single HTTP). Got 403'd by
  eBay UK on every retry in the smoke test. The lite path has no
  browser to pass anti-bot checks. Caffein's actor uses heavier proxy
  rotation and worked first try.
- **Enable `detailedSearch: true`** to get per-item condition. Doubles
  cost and time (visits each item page). Skipped for v1 — Haiku
  synthesises with comp-level condition unknown, downgrades confidence
  accordingly.

## Consequences

- Two AI/data vendor dependencies during the testing window (OpenRouter
  for AI, Apify for comps). Both flagged as temporary in their ADRs.
- Apify run latency (~10s) stacks on top of the Haiku vision call
  (~5s); a full scan is now ~15s. UI loading state already exists.
- `condition` is `null` on every comp until detailedSearch is enabled.
  Update the price-guidance prompt only if observation shows Haiku
  outputs degrade without it.
- One more env var: `APIFY_TOKEN`. Mirrors into Vercel.
- Apify HTML scrapes are fragile to eBay UI changes — the same
  fragility the original `ebay-api-notes.md` flagged. Switch-back to
  official API is the durable path; treat this purely as
  unblocker-for-launch.
