# PreSold — Master Build Plan

> Source of truth. Read in full before any work session. Update in the same commit as any decision that contradicts it.

---

## 0. Product Context

### What we're building
A UK-first reseller operating system. Photo-to-listing AI, price scanner, profit calculator, inventory tracking. v2 adds cross-listing automation.

### Who it's for
UK resellers, 18-35, side-hustle to full-time. They source from charity shops, car boots, online auctions, and personal wardrobes. They list on Vinted (primary), Depop (secondary), and eBay (high-value items). Mobile-first for sourcing and capture, desktop-second for batch listing.

### The painkiller
Writing listings is the most time-consuming part of reselling. A serious reseller writes 10-30 listings per week, each taking 5-15 minutes. We collapse that to 30 seconds via AI listing generation, and we tell them the right price using real sold-comp data so they don't undersell or overprice.

### Why we beat the existing market
Vendoo, List Perfectly, Crosslist, SellerAider are US-built, US-priced ($30-90/month), bloated, and treat UK platforms as afterthoughts. We are UK-native, mobile-first, priced for UK reseller budgets (£7.99/month launch), and built by someone in the community.

### Marketing channel
TikTok influencer-led, UK reseller niche (#ukreseller, #vintedseller, #depopseller). Paid drops £200-500 + 30% recurring affiliate. Free web tool (price scanner) is the top-of-funnel content magnet. Organic on creator's own TikTok and Reddit (r/UKReselling, r/Vinted, r/Depop).

### Success criteria
- £1k/week recurring revenue within 16 weeks of v1 launch
- 200+ active paying users at £7.99/month within 5 months
- One viral TikTok with 100k+ views in first 8 weeks post-launch

### Non-goals (resist these explicitly)
- Authentication / counterfeit checking
- Multi-currency or non-UK platforms
- Android app in v1
- Features that require >£500/month in API costs at 200 active users
- Any AI feature beyond item identification, listing generation, and price guidance

(Cross-listing was previously a v1 non-goal per ADR-001; ADR-007 pulls it back into v1 in phases — eBay UK via native API, Vinted and Depop via WKWebView automation. See `docs/decisions/007-pull-cross-listing-into-v1.md`.)

---

## 1. Architecture Overview

### Stack
- **Mobile**: Native iOS, SwiftUI, iOS 17+
- **Web**: Next.js 15 App Router, Vercel
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions)
- **AI**: Claude Sonnet 4.6 (`claude-sonnet-4-6`) for vision + text generation. Bumped from Haiku 4.5 after live testing showed Haiku unreliable at reading brand labels on garments — see `docs/decisions/006-sonnet-for-vision.md`. Drop back to Haiku once accuracy target is met on a refined prompt or with multi-photo input.
- **Billing**: StoreKit 2 on iOS, Stripe deferred until web has paid features
- **Comps**: eBay Browse API + Marketplace Insights API
- **Analytics**: PostHog (free tier)
- **Errors**: Sentry (free tier)

### Why this stack
- **SwiftUI**: native, fast iteration if fluent, no React Native maintenance tax
- **Next.js**: fastest path to public web tool with email capture and SEO
- **Supabase**: auth + db + storage + edge functions in one, already familiar from SL-MAS
- **Sonnet 4.6 vision**: ~£0.006 per item ID + listing generation. Bumped from Haiku 4.5 (ADR-006) — better OCR on small labels and logos, the actual operation a reseller scanner depends on. Cost still well under the per-user budget after the 3-scan-per-IP-per-day cap and the 24h Apify cache

### Data flow
```
iPhone capture → Haiku vision (item ID + listing copy)
              → eBay API (sold comps for price guidance)
              → Supabase (item stored, photo in storage, listing draft)
              → User reviews and edits on phone
              → Manual copy-to-clipboard per platform (v1)
              → User pastes into Vinted/Depop/eBay native app
              → Email forward to <token>@sales.presold.app when sold
              → Supabase updates item status, profit calculated
```

---

## 2. Folder Structure

See actual filesystem. Key locations:

- `CLAUDE.md` — Claude Code primary context (root)
- `PLAN.md` — this file
- `docs/` — architecture, data model, AI prompts, ADRs
- `ios/` — SwiftUI app
- `web/` — Next.js web tool + marketing
- `supabase/` — DB migrations, edge functions
- `shared/types/` — JSON schemas shared between iOS and web

Each subdirectory has its own `CLAUDE.md` with scope and conventions for that layer.

---

## 3. Data Model

See `docs/data-model.md` for full schema and rationale.

Core tables: `users`, `items`, `photos`, `listings`, `sales`, `price_scans`.

---

## 4. Build Timeline

Off-time pace, ~15-20 hrs/week. **Weeks and days are goals, not deadlines** — move faster where possible. Status markers next to each week's heading reflect actual state:

- ✅ done
- 🚧 in progress
- ⏳ pending

Update the marker in the same PR that completes (or starts) the work.

### Week 0: Setup ✅ (2-3 evenings, parallel work)
1. Buy domain (working name: `presold.app` or chosen brand)
2. Apple Developer account (£79/year, 2-3 day provisioning)
3. eBay Developer account (apply now, ~5 days for production access)
4. Anthropic API key with billing
5. Supabase project created
6. Vercel account linked to GitHub
7. PostHog account
8. Sentry account
9. Run `bootstrap.sh` (this scaffold)
10. First commit

**Week 0 close-out status:**

Done in-repo:
- ✅ Scaffold generated from `bootstrap.sh` and renamed to PreSold
- ✅ Public GitHub repo at `github.com/AviiDeveloper/presold`
- ✅ Repo discipline: LICENSE (All Rights Reserved), CONTRIBUTING, PR template, session-log convention
- ✅ Initial commit + first meta-PR (this week's work) on `main`

Blocked on external accounts (parallel user work, not blocking Week 1 code):
- ⏳ Buy domain (working name: `presold.app`)
- ⏳ Apple Developer account (£79/year, 2-3 day provisioning) — needed for Week 4 TestFlight
- ⏳ eBay Developer account application (~5 days for production access) — needed for Week 1 comps; sandbox fallback documented
- ⏳ Anthropic API key with billing — needed for Week 1 scanner
- ⏳ Supabase project created + keys copied to `web/.env.local` — needed for Week 1 waitlist
- ⏳ Vercel account linked to GitHub — needed for Week 1 deploy
- ⏳ PostHog account — Week 1+
- ⏳ Sentry account — Week 1+

### Week 1: Free web tool ships ✅ (closed 2026-05-13)
**Goal: public price scanner live, email capture working, first TikTok using it.**

- ✅ D1-2: Next.js scaffold, landing page, waitlist form. Live on Vercel.
- ✅ D3-4: `/scan` page, `/api/scan` route, Supabase `price_scans` table + storage, Sonnet 4.6 vision identification (ADR-006), Apify-sourced eBay sold comps (ADR-005), OpenRouter as AI gateway (ADR-004), client-side image compression, library upload, prompt v1.3 tuned for charity-shop single-photo use, single-tier Apify (60s function ceiling fit).
- 🚫 D5: **Descoped.** Shareable result page + OG image generation not built — the inline `/scan` result page is enough for the v1 use case. First TikTok is a marketing action, not code.

**Deliverable**: live URL, working scanner, first content posted.

### Week 2: iOS app skeleton + capture flow 🚧 (5-7 evenings)
**Goal: capture an item end-to-end on TestFlight, listing copy generated.**

- D1-2: Xcode scaffold (requires user to create `PreSold.xcodeproj` in Xcode — see `docs/sessions/NEXT_SESSION.md` for the bootstrap recipe), Supabase Swift client, magic-link auth, tab bar
- D3-4: Capture flow (multi-photo capture, upload), `identify-item` edge function, listing display
- D5-7: Listing review screen (Vinted/Depop/eBay tabs), AI-generated listing copy per platform (Prompt 2), inventory list, persistence

### Week 3: Cross-listing Phase A — eBay UK native API ⏳ (3-4 evenings)
**Goal: one-tap publish to eBay UK from the app.**

Per ADR-007. eBay has a sanctioned API, lowest risk, validates the cross-listing pitch on day one.

- D1: eBay OAuth 2.0 flow, token storage (`users.ebay_oauth_token_encrypted`), Supabase edge function proxy
- D2: Sell Inventory API integration — `inventory_item` → `offer` → `publish`. Photo upload to eBay's image endpoint
- D3: `ListingDetailView` "Publish to eBay" button, status indicators, error handling
- D4: Profit calculation reflects eBay's posted-listing state; manual edit fallback

### Week 4: Cross-listing Phase B — Vinted via WKWebView ⏳ (4-5 evenings)
**Goal: pre-fill Vinted's new-listing form; user taps Post.**

Per ADR-007. Highest-volume UK platform.

- D1: WKWebView host, persistent cookie store, user login flow inside the WebView
- D2-3: JavaScript form-fill (title, brand, category, size, condition, materials, price). Photo upload via JS bridge from `PHPickerViewController`
- D4: Selector versioning + failure fallback to clipboard handoff
- D5: Daily automated selector-break test (GitHub Actions macOS runner)

### Week 5: Cross-listing Phase C — Depop via WKWebView ⏳ (3-4 evenings)
**Goal: same as Phase B, on Depop.**

- D1-2: Depop-specific automation module, reusing the Vinted harness
- D3: Profit, inventory, manual sold flow (carried over from original Week 3 plan)
- D4: Email forward setup, `parse-sale-email` edge function

### Week 6: Beta + StoreKit + polish ⏳ (4-5 evenings)
**Goal: TestFlight ready, billing wired, used on 30+ real items by founder.**

- D1: StoreKit 2 integration, 14-day trial logic, £9.99/mo + £79/yr SKUs (subject to ADR-007 post-Phase-A pricing review)
- D2: Onboarding polish, privacy, ToS, support email
- D3-4: Self-dogfood 30+ real items, prompt accuracy iteration
- D5: TestFlight invite, 10 beta users from friends-of-friends

**Deliverable**: beta-ready product with cross-listing to eBay + Vinted + Depop, used on 30 real items.

### Week 7: Marketing prep + App Store submission ⏳ (3-4 evenings)
**Goal: App Store submitted, first influencer drop scheduled.**

- D1-2: Outreach to 5-10 TikTok creators, fix beta feedback
- D3-4: App Store submission, marketing site polish, demo video shoot

**Deliverable**: App Store review submitted, first influencer drop scheduled, beta users actively flipping items.

### Week 8+: Launch and iterate ⏳
- App Store approval (3-7 days)
- First influencer drop, paid post + 30% affiliate
- £30-50/day Meta ads to demo video
- Weekly iteration on PostHog data

---

## 5. AI Prompts

See `docs/ai-prompts.md`. All prompts versioned and centralised.

---

## 6. Platform-Specific Notes

See `docs/ebay-api-notes.md` for eBay specifics. Vinted and Depop notes below.

### Vinted (UK)
- No public listing API
- v1: copy-to-clipboard only
- Fee: 0% to seller (buyer pays Buyer Protection)
- Title max: 50 chars
- Categories: deeply nested

### Depop
- No public listing API
- v1: copy-to-clipboard only
- ToS permits cross-listing tools
- Fee: 10% to seller
- First line of description = effective title
- Tags: max 5, critical for discovery
- Photos: up to 4

### eBay UK
- Public API (Browse, Selling, Marketplace Insights)
- v1: copy-to-clipboard
- v1.1: optional direct posting via eBay API for users who connect their account
- Fee: 12.8% final value + £0.30
- Title: 80 chars max
- Photos: up to 12

---

## 7. Pricing Logic

### Subscription
- 14-day trial, no credit card
- £7.99/month after trial
- £69/year (28% discount)
- Single tier

### Profit math
```
gross_proceeds = sale_price
platform_fee   = sale_price * rate + fixed
net_proceeds   = gross_proceeds - platform_fee - shipping_cost
profit         = net_proceeds - cost_basis
margin_percent = profit / gross_proceeds * 100
```

### Platform fee constants
- Vinted: 0% + £0
- Depop: 10% + £0
- eBay: 12.8% + £0.30

Shipping defaults to user-set value or category estimate.

---

## 8. Risks and Mitigations

### Build risks
- **SwiftUI fluency**: if slower than expected, ship v1 without ProfitView, add in v1.1
- **eBay API approval delay**: fallback to scraping eBay sold listings via edge function
- **App Store rejection**: keep v1 free of WKWebView automation; position as "inventory and listing assistant"

### Marketing risks
- **First influencer doesn't convert**: budget 3 attempts at £400-500 before iterating product
- **AI listing quality mediocre**: spend a real week on prompts with 100+ real reseller items as test set before launch
- **Pricing wrong**: if month-1 churn high, drop to £4.99 + ad-supported free tier before killing the product

### Operational risks
- **eBay API rate limits**: cache comp data per (item_category, query) for 24h
- **AI cost spike from web tool abuse**: rate-limit free scanner to 3 scans per IP per day
- **Supabase quota**: monitor storage and DB egress, upgrade before hitting limits

---

## 9. What Claude Code Should Do When Uncertain

1. Default to the simpler implementation. Ship v1.
2. If feature touches "cross-listing automation," defer to v2.
3. If UI choice is between minimal and feature-rich, choose minimal.
4. If adding a third tier of pricing, a second AI model, or a non-UK platform, stop and re-read section 0.
5. Tests for `PricingService` and any code touching money. Skip UI tests.
6. Commit messages reference the plan section.
7. Architectural decisions not in this plan → ADR in `docs/decisions/`, update this plan.

---

## 10. Brand and Tone

### Voice
- Direct, dry, no hype
- "Lists faster, sells smarter" — not "revolutionise your reselling"
- Reseller language: flip, haul, sourced from, tagged, listed

### Visual
- High contrast, monochrome with one accent
- Photography-led
- No stock images, no AI art
- Real photos of real items in screenshots

---

## 11. Definition of Done for v1

The product is ready for first influencer drop when:

- [ ] User signs up via email magic link
- [ ] User captures 1-6 photos of an item
- [ ] AI returns item details with ≥75% accuracy on test set of 50 real reseller items
- [ ] AI returns listing copy for Vinted/Depop/eBay with platform-correct formatting
- [ ] Price guidance returns sensible range with sold comp citations
- [ ] User copies listing to clipboard per platform
- [ ] Inventory view shows all items with status
- [ ] User manually marks item sold, sees profit
- [ ] Email forwarding parses real Vinted/Depop/eBay sale emails correctly
- [ ] StoreKit subscription works with 14-day trial
- [ ] App passes App Store review
- [ ] Public web scanner live and converting waitlist signups
- [ ] PostHog tracking key events (signup, first_item, first_listing, first_sale)
- [ ] You have personally used the app on 30+ real items

If any are not true, do not launch. Fix first, ship second.

---

End of plan. Update in the same commit as any decision that contradicts it.
