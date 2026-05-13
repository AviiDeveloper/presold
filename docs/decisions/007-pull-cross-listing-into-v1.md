# 007. Reopen 001: pull cross-listing automation into v1

Date: 2026-05-13
Status: Accepted (supersedes ADR-001 on the cross-listing decision specifically)

## Context

ADR-001 deferred cross-listing automation to v2 on three grounds:

1. App Store rejection risk for WKWebView automation of third-party sites
2. Maintenance fragility from Vinted/Depop UI changes
3. 2–3 weeks of additional build before v1 ships

That call was defensible given the information at the time. After shipping
the free `/scan` web scanner end-to-end and doing live competitive research,
two of the three assumptions have weakened:

**The competitive picture moved.** ADR-001 was written when the named
competition (Vendoo, List Perfectly, Crosslist, SellerAider) was framed as
US-built, US-priced, bloated. May 2026 research surfaced direct iOS-native
AI-scanner competitors that already exist in App Store:

- **VintSnap** — iOS, Vinted-first, "snap photo → listing + eBay sold data"
- **Listed AI** — ~60,000 reseller users, photos → Vinted/eBay/Depop listings
- **Resell AI** — iOS scan-first, resale value across Vinted/Depop
- **Voolist** — UK/EU focused cross-listing at ~£16/mo
- **Zipsale**, **Vendoo UK**, **Crosslist** — all cross-list to Vinted/Depop/eBay UK

The AI-scanner-only positioning is **commoditised**. Without cross-listing,
PreSold competes head-on with Listed AI's 60k installed base and Voolist's
UK pricing on no wedge except being slightly cheaper than Voolist. The
differentiator that justifies a £9.99/mo subscription is the same one
Voolist and Vendoo charge for: cross-listing.

**App Store risk re-evaluated against observed practice.** Vendoo Mobile,
List Perfectly Mobile, and Crosslister all ship App-Store-approved iOS
apps using WKWebView to automate Vinted/Depop listing creation. The
pattern has cleared Apple review for years. The risk in ADR-001 was
hypothetical; in May 2026 it is empirically surmountable with the right
positioning ("seller's assistant" / "we type for you," not "we automate
the platform").

**eBay UK has a sanctioned native API.** ADR-001's blanket "all three
platforms need WKWebView" assumption was wrong. eBay's Sell Inventory API
with user OAuth lets us post listings cleanly with zero automation tricks
and zero maintenance risk. One of the three target platforms is free.

## Decision

Pull cross-listing into v1, **phased** so each phase ships independently
behind a feature flag and we can call it good after Phase A if B or C run
into trouble.

### Phase A — eBay UK via native API (≈1 week)

- eBay Sell Inventory API + Account OAuth 2.0
- User connects their eBay UK account once; tokens stored encrypted in
  `users.ebay_oauth_token_encrypted` (new column, small migration)
- Listings created via `POST /sell/inventory/v1/inventory_item` →
  `POST /sell/inventory/v1/offer` → `POST /sell/inventory/v1/offer/{id}/publish`
- Photos uploaded to eBay's photo endpoint first, referenced by URL
- Sanctioned. Zero maintenance risk. Validates the cross-listing pitch
  on day one with one platform.

### Phase B — Vinted via WKWebView (≈2 weeks)

- WKWebView embedding `m.vinted.co.uk`
- Persistent cookie store; user logs into their own Vinted account once
  inside the WebView; we never see credentials
- JavaScript injection via `WKUserContentController` fills title,
  description, brand, category, size, condition, materials, price
- Photo upload: read user-selected `UIImage`s from `PHPickerViewController`,
  encode JPEG, POST to Vinted's upload endpoint with the WebView's session
  cookies
- **Submit is always a user-initiated tap** on the in-WebView "Post"
  button. We pre-fill; we never auto-submit. This is the line App Store
  reviewers care about.
- Failure mode: if Vinted updates HTML and selectors break, fall back to
  clipboard handoff (current copy-paste flow) gracefully — never crash.

### Phase C — Depop via WKWebView (≈1–2 weeks)

- Same architecture as Phase B with Depop-specific selectors and
  endpoints. Substantial code reuse from the Vinted automation harness.

**Timeline impact:** v1 launch slips from Week 4–5 to **Week 6–7**.
~2 weeks slip vs current plan; about 1 week shorter than the worst case
("ship without, add later in v1.1") because the retention problem of
launching without cross-listing would force the v1.1 work anyway.

## Architecture details

### eBay (Phase A)

- New `EBAY_OAUTH_CLIENT_ID` and `EBAY_OAUTH_CLIENT_SECRET` env vars
  (separate from the Browse API keys requested in Week 0)
- Redirect URI: `https://presold.app/auth/ebay/callback` (web-mediated
  OAuth even from iOS — opens Safari for the auth flow per Apple guidance)
- Token refresh handled server-side; iOS app gets a short-lived bearer
- Migration: `alter table users add column ebay_oauth_token_encrypted text`
- All eBay API calls proxy through a Supabase edge function — keys never
  on device, per `ios/CLAUDE.md` networking rules

### Vinted / Depop (Phases B and C)

- `WKWebViewConfiguration` with:
  - `WKWebsiteDataStore.default()` (persistent across launches)
  - Custom User-Agent matching Vinted/Depop's mobile-web expected client
  - JavaScript bridge via `WKScriptMessageHandler` for in-WebView events
- Per-platform module: `VintedAutomation`, `DepopAutomation`, each with:
  - `loginRequired() -> Bool`
  - `fillListing(_ listing: Listing, photos: [UIImage]) async throws`
  - `currentDraftURL() -> URL?`
  - `selectorVersion: String` for tracking when HTML changes break us
- Maintenance test: daily run against a sandbox Vinted/Depop account
  (real account, real listings created as drafts, deleted after) via
  GitHub Actions on a macOS runner. Alerts on selector breakage.

## App Store positioning

- App description: "PreSold helps you list faster on Vinted, Depop, and
  eBay UK. AI writes your listings; you stay in control."
- **Never** describe as "automate Vinted," "post listings for you," or
  similar. Avoid words like "automation" in marketing copy.
- The act of posting on Vinted/Depop is always a user tap inside the
  embedded platform UI — user sees what they're posting before they post.
- Vinted/Depop branding never appears in our app icon, app name, or
  primary App Store screenshots. Screenshots use generic "Listed on
  eBay UK ✓" indicators, not platform logos.

This matches the pattern that has cleared Apple review for Vendoo Mobile
and List Perfectly Mobile.

## Maintenance plan

- Daily automated test (GitHub Actions macOS runner) creates a draft
  listing on each platform via the same code path the app uses; alerts
  Slack on failure
- Hotfix turnaround target: 24 hours when selectors break
- Expected effort: ~2 hours/month at Vinted/Depop's historical
  ~6-week UI-change cadence
- If maintenance exceeds 10 hours/month, re-evaluate (Phase D Chrome
  extension as desktop alternative; or accept reduced platform coverage)

## Switch-back / failure modes

Cross-listing as decided is durable. The scenarios that would force a
partial revert:

- **App Store rejects three iterations** of submission citing WKWebView
  automation as the reason → fall back to clipboard handoff for
  Vinted/Depop; keep eBay native API. Communicate as "we type your
  listing for you; tap to post" not "automated cross-listing."
- **Vinted/Depop add explicit anti-automation language to their ToS
  targeting our pattern** → review with legal; likely continue until
  cease-and-desist; communicate transparently.
- **Maintenance burden exceeds 10 hours/month sustained** → drop the
  costlier of the two platforms (likely Depop), keep Vinted + eBay.

## Alternatives considered (rejected)

- **Server-side headless browser automation.** Requires storing user
  Vinted credentials; GDPR + security risk; Vinted IP-blocks data centre
  IPs; Vinted ToS prohibits credential-based scraping. Hard no.
- **Chrome extension only.** Targets a different user (desktop
  power-seller, not the on-the-go mobile-first reseller in PLAN §0).
  May ship later as a complement, not as the primary v1 mechanism.
- **Vinted/Depop deep links.** Don't exist for new-listing-with-data.
- **Stay with copy-paste.** Current v1 plan. Insufficient
  differentiation per the competitive analysis above.

## Consequences

- v1 launch slips Week 4–5 → **Week 6–7**.
- PLAN.md §0 "Non-goals" — remove "Cross-listing automation in v1."
- PLAN.md §4 — Week 3/4 timeline restructured to include Phase A/B/C.
- CLAUDE.md (root) "What v1 IS NOT" — remove the cross-listing line and
  the ADR-001 reference.
- ADR-001 is **superseded on the cross-listing decision specifically**.
  Its rejections of Android, non-UK platforms, and server-side
  automation remain in force.
- Apple Developer account becomes urgent — Phase B requires on-device
  testing. Submit application immediately.
- New env vars: `EBAY_OAUTH_CLIENT_ID`, `EBAY_OAUTH_CLIENT_SECRET`.
- `listings` table schema already supports this — `status: copied / posted / sold` already
  captures the workflow. No data-model migration needed.
- Pricing: capability supports a Pro tier at £12.99/mo with cross-listing
  included, or a unified £9.99/mo with cross-listing for everyone.
  Decision deferred to a post-Phase-A review when we have early conversion data.

## What stays from ADR-001

ADR-001's reasoning still rules out:
- Cross-listing on Android (Android deferred indefinitely)
- Cross-listing for non-UK platforms (out of scope)
- Server-side credential-stored automation
- WKWebView-as-product-replacement (e.g. "PreSold is just a wrapped Vinted")

ADR-007 only flips the call on **client-side WKWebView automation for v1
on iOS for Vinted/Depop**, and adds eBay native API as a separate
Phase A path.
