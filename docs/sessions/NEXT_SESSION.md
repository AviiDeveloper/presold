# Next session — live handover

> **This file is the live state going INTO the next session.** It is always
> fresh: every PR updates it as its last step before opening. If you are
> picking up the project cold, read this first, then `PLAN.md`, then the
> last entries in this folder.

---

## Snapshot

- **Last updated:** 2026-05-13, after PR #1 merge
- **Last merged PR:** [#1 — Set up repo discipline](https://github.com/AviiDeveloper/presold/pull/1) (merge commit `4e1930a`)
- **`main` is at:** `4e1930a` (clean)
- **Repo:** https://github.com/AviiDeveloper/presold (public)
- **Current PLAN.md state:** Week 0 ✅ closed · Week 1 ⏳ pending

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
- ✅ Repo discipline live: All Rights Reserved licence, branch+PR workflow, mandatory PR template, session-log convention, status markers in `PLAN.md`
- ✅ Initial scaffold commit + first meta-PR (PR #1) merged

## What's next

**Next branch:** `week-1/nextjs-scaffold`

**Scope of next session (PLAN.md §4, Week 1 Day 1-2):**

- Next.js 15 boilerplate: `web/next.config.js`, `web/tsconfig.json`, `web/app/layout.tsx`, `web/app/globals.css`
- `web/lib/supabase.ts` — server-side Supabase client
- Marketing landing page at `web/app/(marketing)/page.tsx` — pitch, problem, signup form
- Waitlist API route at `web/app/api/waitlist/route.ts` — insert into Supabase
- Tailwind setup (the package already declares no CSS framework; decide and commit before writing UI)
- Vercel deploy (requires Vercel account linked; if not ready, ship the branch as code-only and defer deploy)

Stop short of `/scan` and the AI integration — that's the next branch.

## Useful commands for starting the next session

```sh
git checkout main && git pull --ff-only
git checkout -b week-1/nextjs-scaffold
# do the work
git status                              # confirm no secrets staged
git add <files> && git commit -m "[Week 1] feat: ..."
git push -u origin week-1/nextjs-scaffold
gh pr create                            # template auto-fills the session-log structure
# fill every section of the template; self-review the diff
gh pr merge --merge --delete-branch     # preserve commit history; do NOT squash
git checkout main && git pull --ff-only
```

## Prerequisites

**Already in the repo, no setup needed:**

- Supabase migrations (incl. `price_scans` table) — `supabase/migrations/`
- AI prompts (v1.0, identify-item, listing reformat, price guidance) — `docs/ai-prompts.md`
- Shared JSON schemas — `shared/types/`
- eBay API integration notes — `docs/ebay-api-notes.md`
- All env-var names — `.env.example` and `web/.env.local.example`

**Needed from user before code can RUN (not before code can be WRITTEN):**

| Credential | Needed for | When |
| --- | --- | --- |
| Supabase project URL + anon key + service role key | Waitlist insert, scanner reads | Week 1 D1-2 to actually test waitlist |
| Anthropic API key (billing enabled) | Haiku vision identification | Week 1 D3-4 |
| eBay App ID + Cert ID (production, 5-10 day approval) | Sold-comp lookup | Week 1 D3-4; sandbox fallback documented in `docs/ebay-api-notes.md` |
| Vercel account linked to GitHub | Deploy step | Week 1 D2 deploy; defer if not ready |
| Domain (`presold.app` or chosen brand) | Production URL | Anytime before launch |
| PostHog account | Analytics | Week 1+ |
| Sentry account | Error tracking | Week 1+ |
| Apple Developer account (£79/yr, 2-3 days) | TestFlight | Week 4 |

## Open follow-ups

_(None at the time of this handover. As work uncovers loose ends, list them here and clear them on completion.)_

## How to maintain this file

This file is **the last thing edited** before opening a PR. The convention:

1. Update **Snapshot** with the new "last updated" date and the upcoming PR's merge SHA placeholder (or fill in retrospectively on the next session's first action).
2. Replace **What's next → Next branch** with the next concrete branch and scope.
3. Move completed items out of **What's next** into **What's done**.
4. Add any new loose ends to **Open follow-ups**; clear them when resolved.
5. Update **Prerequisites** if the next session needs new credentials.

Old state lives in `docs/sessions/YYYY-MM-DD-NN-slug.md`. This file is **never historical** — it is always the live state.
