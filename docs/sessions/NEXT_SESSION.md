# Next session — live handover

> **This file is the live state going INTO the next session.** It is always
> fresh: every PR updates it as its last step before opening. If you are
> picking up the project cold, read this first, then `PLAN.md`, then the
> last entries in this folder.

---

## Snapshot

- **Last updated:** 2026-05-13, after the `week-1/nextjs-scaffold` PR
- **Last merged PR:** _to be filled in once merged_
- **`main` will be at:** _merge commit of this PR_
- **Repo:** https://github.com/AviiDeveloper/presold (public)
- **Current PLAN.md state:** Week 0 ✅ closed · Week 1 🚧 (D1-2 ✅, D3-4 ⏳, D5 ⏳)

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

## What's next

**Next branch:** `week-1/scan-flow`

**Scope of next session (PLAN.md §4, Week 1 Day 3-4):**

- `web/app/scan/page.tsx` — upload UI (photo + optional category hint)
- `web/app/api/scan/route.ts` — accepts photo, writes to `scan-photos`
  bucket, inserts `price_scans` row, calls Haiku vision + eBay comps
- `web/lib/anthropic.ts` — server-side Anthropic client
- `web/lib/ebay.ts` — eBay Browse / Marketplace Insights wrapper with
  per-(category, query) 24h cache (PLAN §8)
- IP rate limit: 3 scans / IP / day (PLAN §8). In-memory map is fine for
  v1; revisit if we need durability
- Use `claude-haiku-4-5` per PLAN §1 and the identify-item prompt in
  `docs/ai-prompts.md`

Stop short of the shareable result page (`/scan/result/[slug]` with OG
image generation) — that's Day 5.

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

- Supabase migrations (incl. `waitlist` + `price_scans`) — `supabase/migrations/`
- AI prompts (v1.0, identify-item, listing reformat, price guidance) — `docs/ai-prompts.md`
- Shared JSON schemas — `shared/types/`
- eBay API integration notes — `docs/ebay-api-notes.md`
- All env-var names — `.env.example` and `web/.env.local.example`
- **Web scaffold + waitlist** — code written, build green, awaiting creds to run

**Needed from user before the next session's code can RUN (not before code can be WRITTEN):**

| Credential | Needed for | When |
| --- | --- | --- |
| Supabase project URL + anon key + service role key | Waitlist insert, `/scan` writes | **Now blocking** the existing waitlist E2E; required for `/scan` |
| Anthropic API key (billing enabled) | Haiku vision identification | **Week 1 D3-4** (next session) |
| eBay App ID + Cert ID (production) | Sold-comp lookup | **Week 1 D3-4** (next session); sandbox fallback documented in `docs/ebay-api-notes.md` |
| Vercel account linked to GitHub | Deploy step | Week 1 D2 deploy (deferred); can ship next session as code-only |
| Domain (`presold.app` or chosen brand) | Production URL | Anytime before launch |
| PostHog account | Analytics | Week 1+ |
| Sentry account | Error tracking | Week 1+ |
| Apple Developer account (£79/yr, 2-3 days) | TestFlight | Week 4 |

## Open follow-ups

- **Vercel deploy not yet wired.** Defer until the user links an account.
  Once linked, a one-line `vercel.json` may be needed to pin the
  monorepo root to `web/`.
- **Waitlist insert not exercised against real Supabase.** Drop credentials
  into `web/.env.local`, run `npm run dev`, submit the form, check the
  `waitlist` table.
- **`next lint` deprecation warning.** Next 15 prints a notice that
  `next lint` is removed in Next 16. Migrate to the ESLint CLI before
  bumping to Next 16; not urgent.

## How to maintain this file

This file is **the last thing edited** before opening a PR. The convention:

1. Update **Snapshot** with the new "last updated" date and the upcoming PR's merge SHA placeholder (or fill in retrospectively on the next session's first action).
2. Replace **What's next → Next branch** with the next concrete branch and scope.
3. Move completed items out of **What's next** into **What's done**.
4. Add any new loose ends to **Open follow-ups**; clear them when resolved.
5. Update **Prerequisites** if the next session needs new credentials.

Old state lives in `docs/sessions/YYYY-MM-DD-NN-slug.md`. This file is **never historical** — it is always the live state.
