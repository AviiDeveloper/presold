# Next session — live handover

> **This file is the live state going INTO the next session.** It is always
> fresh: every PR updates it as its last step before opening. If you are
> picking up the project cold, read this first, then `PLAN.md`, then the
> last entries in this folder.

---

## Snapshot

- **Last updated:** 2026-05-13, after the `week-1/scan-flow` PR
- **Last merged PR:** #4 (`chore/agent-skills` → `main` at `212da63`)
- **In flight:** `week-1/scan-flow` — `/scan` price scanner end-to-end (Haiku vision + eBay comps + price guidance + public `price_scans` row)
- **Repo:** https://github.com/AviiDeveloper/presold (public)
- **Current PLAN.md state:** Week 0 ✅ closed · Week 1 🚧 (D1-2 ✅, D3-4 ✅, D5 ⏳)

## Read these first, in order

1. [`README.md`](../../README.md) — what the project is, status, stack
2. [`PLAN.md`](../../PLAN.md) — find the next ⏳ item
3. [`CLAUDE.md`](../../CLAUDE.md) — operating principles + workflow guardrails
4. [`CONTRIBUTING.md`](../../CONTRIBUTING.md) — branch/commit/PR conventions
5. The most recent merged session log in this folder — what was done last
6. **This file** — current live state + immediate next step

## What's done

- ✅ Scaffold generated from `bootstrap.sh`, project renamed to PreSold
- ✅ Public GitHub repo created
- ✅ Repo discipline live: All Rights Reserved licence, branch+PR workflow,
  mandatory PR template, session-log convention, status markers in `PLAN.md`
- ✅ Initial scaffold commit + first meta-PR (PR #1) merged
- ✅ **Web scaffold** (Week 1 D1-2): Next.js 15 App Router, Tailwind v4,
  Inter via `next/font`, monochrome design tokens
- ✅ **Landing page** at `/` — hero, three-step how-it-works, problem
  section, dry copy per PLAN §10
- ✅ **Waitlist** end-to-end (no creds yet): form (server action +
  client component), API route, shared `lib/waitlist.ts` helper,
  `waitlist` table migration + RLS, `data-model.md` updated
- ✅ **Supabase MCP connector** registered at project scope; agent-skills
  lockfile committed for reproducible install
- ✅ **Price scanner** (Week 1 D3-4): `/scan` page + form, `/api/scan`
  route, `lib/ai.ts` (Haiku 4.5 via OpenRouter — ADR-004),
  `lib/ebay.ts` (Marketplace Insights with 24h comp cache +
  broaden-on-sparse query), `lib/rate-limit.ts` (3/IP/day in-memory),
  `lib/scan.ts` orchestrator. Photos land in the `scan-photos` bucket
  keyed by `shareable_slug`.
- ✅ **Supabase live**: 4 migrations applied to project
  `yiowyehukmhkblmogwjy`. 7 tables RLS-on (users, items, photos,
  listings, sales, price_scans, waitlist) + buckets `item-photos`
  (private) and `scan-photos` (public). One bug fix on the sales index
  expression along the way.
- ✅ **AI gateway live via OpenRouter** (ADR-004): `web/.env.local`
  populated with Supabase URL/anon/service-role + OpenRouter key. eBay
  vars empty pending production approval (scanner degrades gracefully).

## What's next

**Next branch:** `week-1/scan-result`

**Scope of next session (PLAN.md §4, Week 1 Day 5):**

- `web/app/scan/result/[slug]/page.tsx` — shareable read-only result page
  served from the `price_scans` row keyed by `shareable_slug`
- `web/app/scan/result/[slug]/opengraph-image.tsx` — dynamic OG image so
  TikTok / link previews show the item + price tiles
- Polish the `/scan` page after the first real run-through (mobile UX,
  loading state, copy)
- Post the first TikTok demo using the live tool

Carries over from D3-4 (blocked on creds, not code):
- End-to-end exercise of the scan flow once `ANTHROPIC_API_KEY`,
  `EBAY_APP_ID`, `EBAY_CERT_ID`, and `SUPABASE_SERVICE_ROLE_KEY` land in
  `web/.env.local`. Haiku vision call is the only required path; eBay
  failure falls back to comps=[] gracefully.

## Useful commands for starting the next session

```sh
git checkout main && git pull --ff-only
git checkout -b week-1/scan-flow
cd web
npm install                            # if dependencies have changed
cp .env.local.example .env.local       # fill ANTHROPIC + EBAY + SUPABASE
npm run dev                            # http://localhost:3000
# do the work
git status                              # confirm no secrets staged
git add <files> && git commit -m "[Week 1] feat: ..."
git push -u origin week-1/scan-flow
gh pr create                            # template auto-fills the session-log structure
gh pr merge --merge --delete-branch     # preserve commit history; do NOT squash
git checkout main && git pull --ff-only
```

## Prerequisites

**Already in the repo, no setup needed:**

- Supabase migrations (incl. `waitlist` + `price_scans` + storage buckets)
  — `supabase/migrations/`
- AI prompts (v1.0, identify-item, listing reformat, price guidance) —
  `docs/ai-prompts.md`
- Shared JSON schemas — `shared/types/`
- eBay API integration notes — `docs/ebay-api-notes.md`
- All env-var names — `.env.example` and `web/.env.local.example`
- **Web scaffold + waitlist + /scan** — code written, build green,
  awaiting creds to run

**Needed from user before the next session's code can RUN (not before code can be WRITTEN):**

| Credential | Needed for | When |
| --- | --- | --- |
| Supabase project URL + anon key + service role key | Waitlist insert, `/scan` writes | **Now blocking** waitlist + scan E2E |
| Anthropic API key (billing enabled) | Haiku vision + price guidance | **Now blocking** scan E2E |
| eBay App ID + Cert ID (production) | Sold-comp lookup | Scan E2E (degrades gracefully if missing) |
| Vercel account linked to GitHub | Deploy step | Week 1 D5 deploy |
| Domain (`presold.app` or chosen brand) | Production URL | Anytime before launch |
| PostHog account | Analytics | Week 1+ |
| Sentry account | Error tracking | Week 1+ |
| Apple Developer account (£79/yr, 2-3 days) | TestFlight | Week 4 |

## Open follow-ups

- **Vercel env vars set, deploy URL not yet captured here.** User added
  the keys to Vercel during the OpenRouter switch — confirm the prod
  deploy succeeds and add the URL to this file on the next pass.
- **eBay credentials waiting on production approval.** Marketplace
  Insights production access is ~5 business days. Scanner degrades to
  `comps=[]` until then; Haiku still produces a result with low
  confidence (`docs/ebay-api-notes.md`).
- **Supabase security advisors flagged 4 warnings on first apply.** All
  WARN-level, none block the scan flow:
    1. `update_updated_at` function has mutable `search_path` — fix with
       `alter function ... set search_path = public, pg_temp`.
    2. `price_scans` INSERT policy `WITH CHECK (true)` — intentional per
       data-model.md, advisor doesn't have that context.
    3. `waitlist` INSERT policy `WITH CHECK (true)` — same, intentional.
    4. `scan-photos` public bucket has a broad SELECT policy on
       `storage.objects` — public URL access doesn't need it; safe to
       drop the `scan_photos_public_read` policy. Bundle (1) and (4)
       into a small `advisor_fixes` migration.
- **`next lint` deprecation warning.** Next 15 prints a notice that
  `next lint` is removed in Next 16. Migrate to the ESLint CLI before
  bumping to Next 16; not urgent.
- **Agent skills installed via `npx skills add supabase/agent-skills`.**
  Lockfile committed; `.agents/` and `.claude/skills/` are gitignored.
  Fresh clones run `npx skills install` to materialise.
- **OpenRouter is a temporary AI gateway.** See
  `docs/decisions/004-openrouter-temporary-ai-gateway.md`. Switch back
  to Anthropic direct once billing is live.

## How to maintain this file

This file is **the last thing edited** before opening a PR. The convention:

1. Update **Snapshot** with the new "last updated" date and the upcoming PR's merge SHA placeholder (or fill in retrospectively on the next session's first action).
2. Replace **What's next → Next branch** with the next concrete branch and scope.
3. Move completed items out of **What's next** into **What's done**.
4. Add any new loose ends to **Open follow-ups**; clear them when resolved.
5. Update **Prerequisites** if the next session needs new credentials.

Old state lives in `docs/sessions/YYYY-MM-DD-NN-slug.md`. This file is **never historical** — it is always the live state.
