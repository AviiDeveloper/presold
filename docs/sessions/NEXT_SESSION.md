# Next session — live handover

> **This file is the live state going INTO the next session.** It is always
> fresh: every PR updates it as its last step before opening. If you are
> picking up the project cold, read this first, then `PLAN.md`, then the
> last entries in this folder.

---

## Snapshot

- **Last updated:** 2026-05-13, after the `chore/adr-007-cross-listing-v1` PR
- **Last merged PR:** #13 (`week-1/close-out` → `main` at `c3f9f49`)
- **In flight:** `chore/adr-007-cross-listing-v1` — reopens ADR-001, pulls cross-listing into v1 in phases, restructures Weeks 3–8 of PLAN.md
- **Repo:** https://github.com/AviiDeveloper/presold (public)
- **Production URL:** https://presold-three.vercel.app (Vercel auto alias)
- **Current PLAN.md state:** Week 0 ✅ · Week 1 ✅ · Week 2 🚧 (iOS scaffold) · Week 3–5 ⏳ (cross-listing phases A/B/C per ADR-007) · Week 6 ⏳ (beta + StoreKit) · Week 7+ ⏳ (launch)

## Read these first, in order

1. [`README.md`](../../README.md) — what the project is, status, stack
2. [`PLAN.md`](../../PLAN.md) — find the next ⏳ item
3. [`CLAUDE.md`](../../CLAUDE.md) — operating principles + workflow guardrails
4. [`CONTRIBUTING.md`](../../CONTRIBUTING.md) — branch/commit/PR conventions
5. The most recent merged session log in this folder — what was done last
6. **This file** — current live state + immediate next step

## What's done (cumulative through end of Week 1)

### Week 0
- ✅ Repo scaffold, public on GitHub, branch+PR workflow, session-log convention.

### Week 1 — full free web scanner shipped
- ✅ **Marketing**: landing page at `/`, waitlist form (server action + API
  route), `waitlist` table + RLS. Live.
- ✅ **Scanner**: `/scan` page + form, `/api/scan` route, full pipeline:
  client-side image compress → Sonnet vision (Prompt 1 v1.3) → Apify
  eBay sold comps → Sonnet price guidance (Prompt 3 v1.1) → public
  `price_scans` row + photo in `scan-photos` bucket.
- ✅ **Supabase live**: 4 migrations applied to project
  `yiowyehukmhkblmogwjy`. 7 tables RLS-on. Both storage buckets created.
- ✅ **AI gateway via OpenRouter** (ADR-004) using
  `anthropic/claude-sonnet-4-6` (bumped from Haiku per ADR-006 after
  live testing showed Haiku unreliable at label OCR).
- ✅ **eBay sold comps via Apify** (ADR-005) using
  `caffein.dev/ebay-sold-listings`. Single-tier query (broaden-on-sparse
  removed in PR #12 — sequential tiers exceeded Vercel's 60s ceiling).
- ✅ **Vercel deployed**: env vars wired (Supabase, OpenRouter, Apify).
  Production scanner live. Tested end-to-end on phone — YSL jacket
  correctly identified, comps returned, price tiles rendered.
- 🚫 **D5 shareable result page + OG image**: descoped. Inline result
  view on `/scan` is sufficient for v1.

## What's next

**Strategic shift** (ADR-007): cross-listing is now in v1. Launch slips from
Week 4–5 to Week 6–7. The reason is the competitive picture surfaced this
session — AI-scanner-only is commoditised (Listed AI alone has ~60k users)
and the per-feature parity with Voolist / Vendoo / Zipsale becomes load-
bearing for the £9.99/mo pricing pitch.

Order of phases per ADR-007:
- **Week 2** — iOS scaffold (unchanged)
- **Week 3, Phase A** — eBay UK via native Sell Inventory API (sanctioned, lowest risk)
- **Week 4, Phase B** — Vinted via WKWebView
- **Week 5, Phase C** — Depop via WKWebView + carry-over inventory/profit/email work
- **Week 6** — StoreKit + beta polish
- **Week 7+** — App Store submission, launch

**Next branch:** `week-2/ios-scaffold`

**Scope of next session (PLAN.md §4, Week 2 Day 1-2):**

The actual `.xcodeproj` has to be created in Xcode — Claude Code can't
generate a working Xcode project file from chat reliably. The bootstrap
recipe:

1. Open Xcode → File → New → Project → iOS → App.
2. Product Name: `PreSold`. Interface: SwiftUI. Language: Swift.
   Storage: None. Tests: tick "Include Tests".
3. Save the project so the resulting `PreSold/` folder ends up at
   `/Users/Avii/Desktop/PreSold/ios/PreSold/`. The existing
   `ios/PreSold/Config/` directory will be left alongside.
4. Set deployment target to **iOS 17.0** in the project's General tab.
5. Add Swift package `https://github.com/supabase/supabase-swift`
   (Branch: main) via File → Add Package Dependencies.
6. Commit just the new `.xcodeproj` and the auto-generated
   `ContentView.swift` / `PreSoldApp.swift` on a fresh branch
   `week-2/ios-scaffold`.
7. Then Claude can write the Models, Services, Views, etc. into the
   project (you drag them into Xcode once, then they're tracked).

After the project file exists, Week 2 D1-2 work per `ios/CLAUDE.md`:
- `Models/` — `Item`, `Photo`, `Listing`, `Sale`, `PriceScan` Codable
  structs matching `shared/types/*.schema.json`
- `Services/SupabaseClient.swift` — singleton, magic-link auth
- `Services/AIService.swift` — proxies through Supabase edge function
  (not direct to OpenRouter)
- `Views/RootTabView.swift` — tab bar shell (Capture / Inventory /
  Profile)
- `Views/Auth/SignInView.swift` — magic-link entry

## Useful commands for starting the next session

```sh
git checkout main && git pull --ff-only
# After you create the xcodeproj in Xcode at ios/PreSold/PreSold.xcodeproj:
git checkout -b week-2/ios-scaffold
git add ios/PreSold/PreSold.xcodeproj ios/PreSold/PreSold/
git commit -m "[Week 2] feat: scaffold SwiftUI project in Xcode"
# Then Claude writes the Models/Services/Views, drag-in to Xcode, commit again
```

## Prerequisites

**Already in the repo, no setup needed:**

- Supabase migrations applied, schema live, buckets created
- AI prompts (v1.3, identify-item; v1.1 listing-reformat + price-guidance)
- Shared JSON schemas in `shared/types/`
- Web scanner production-deployed
- 6 ADRs documenting deferred features + temporary infra choices

**Needed from user before Week 2 code can RUN:**

| Credential / Tool | Needed for | Status |
| --- | --- | --- |
| Xcode 15+ | Project creation, all iOS work | Should already be installed |
| Apple Developer account (£79/yr, 2-3 days) | TestFlight (Week 4) | ⏳ Apply mid-Week 2 |
| Real iPhone | Camera testing | ✅ (used for web scanner tests) |

**Carried over from Week 1, no longer blocking Week 2 specifically but blocking later weeks:**

- Anthropic direct API key (deferred — OpenRouter covers us, ADR-004)
- eBay Browse API keys (deferred — Apify covers us for sold comps, ADR-005)
- **eBay Sell Inventory API OAuth credentials (BLOCKS Week 3 Phase A — ADR-007)**: separate from Browse keys. Apply at developer.ebay.com for production access to the Sell APIs; allow ~5 business days.
- Real reseller test set of 50 items (PLAN §11 DoD — start collecting now)

## Open follow-ups

- **Supabase advisor warnings** (4 from initial schema apply): function
  `update_updated_at` search_path mutability + `scan-photos` broad
  SELECT policy. Bundle into a small `advisor_fixes` migration. Non-
  blocking.
- **Vercel deploy URL not yet on a custom domain.** Currently
  `presold-three.vercel.app`. When the domain lands, update
  `web/app/layout.tsx` `metadataBase` and OpenRouter `HTTP-Referer`
  header in `web/lib/ai.ts`.
- **`next lint` deprecation** in Next 15 → removed in Next 16. Migrate
  to the ESLint CLI before bumping.
- **AI accuracy test set.** PLAN §11 DoD requires ≥75% on 50 real
  reseller items. Start a `docs/test-items/` folder with photos and
  expected outputs.
- **OpenRouter still temporary** (ADR-004) — switch back to Anthropic
  direct when billing is enabled.
- **Apify still temporary** (ADR-005) — switch back to eBay Marketplace
  Insights when production approval lands.
- **Sonnet still upgrade** (ADR-006) — drop back to Haiku if accuracy
  holds at the DoD bar.
- **Pricing review queued** (ADR-007): £7.99/mo from PLAN §7 might bump
  to £9.99/mo once we have cross-listing in place. Decide after Phase A
  ships and we see early conversion data.
- **Listing-copy generation** (Prompt 2, already specced in
  `docs/ai-prompts.md` v1.0): not yet implemented in code. Cheap
  (~$0.008/item all 3 platforms on Haiku batched). Ships in Week 2 D5-7
  alongside the listing review screen.

## How to maintain this file

This file is **the last thing edited** before opening a PR. The convention:

1. Update **Snapshot** with the new "last updated" date and the upcoming PR's merge SHA placeholder (or fill in retrospectively on the next session's first action).
2. Replace **What's next → Next branch** with the next concrete branch and scope.
3. Move completed items out of **What's next** into **What's done**.
4. Add any new loose ends to **Open follow-ups**; clear them when resolved.
5. Update **Prerequisites** if the next session needs new credentials.

Old state lives in `docs/sessions/YYYY-MM-DD-NN-slug.md`. This file is **never historical** — it is always the live state.
