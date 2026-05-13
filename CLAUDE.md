# Claude Code Instructions — PreSold

You are working on **PreSold**, a UK-first reseller operating system.
Native iOS app (SwiftUI) + Next.js web tool + Supabase backend.

## Read these before doing anything

1. **`PLAN.md`** — master plan, scope, timeline, definition of done. Source of truth.
2. **The `CLAUDE.md` in the subdirectory you're working in** (ios, web, supabase).
3. **Relevant doc(s) in `docs/`** if your task touches them.

If you have not read `PLAN.md` this session, read it now.

## Operating principles

1. **Default to the simpler implementation.** We ship v1, not infrastructure for scale.
2. **Resist scope drift.** If your task touches anything not in v1 scope (cross-listing automation, authentication checking, Android, non-UK platforms), stop and propose deferring.
3. **One thing at a time.** Finish the current section of PLAN.md before starting another.
4. **Write tests for money math only.** `PricingService` and any code that touches profit/fees/sale_price must have tests. Skip tests for UI views and prompts.
5. **Commit messages reference the plan.** Format: `[Week N] <type>: <subject>` where type ∈ {feat, fix, chore, docs, refactor, test, build, ci}. Example: `[Week 2] feat: add listing review screen with platform tabs`. One concern per commit. AI-assisted commits include `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`. Full conventions in [`CONTRIBUTING.md`](./CONTRIBUTING.md).
6. **When you find a decision not in the plan, write an ADR.** Place in `docs/decisions/NNN-short-name.md`. Don't make undocumented architectural calls.
7. **Update PLAN.md in the same commit as the code change that contradicts it.** The plan and the code must always agree.

## How we work in this repo (workflow guardrails)

This project is public on GitHub as a portfolio piece + working business. Every change goes through a branch and a PR. No exceptions after the initial scaffold commit.

- **Every session opens a feature branch and closes with a PR.** Branch name: `week-N/short-slug` (e.g. `week-1/landing-page`, `week-2/capture-flow`).
- **The PR body IS the session log.** The template at `.github/pull_request_template.md` auto-populates the required structure: goal, PLAN.md section, what shipped, why, files touched, verification, what's next. Fill every section.
- **Never commit directly to `main`** after the initial scaffold. Branch, push, PR, merge.
- **Mirror merged PR descriptions into `docs/sessions/YYYY-MM-DD-NN-slug.md`** so the project history survives the platform.
- **Before every push:** run `git status` and verify no `.env*`, no `*.xcconfig` (non-example), no `secrets.json`, no `*.pem`/`*.key`. The `.gitignore` catches these but verify.
- **`PLAN.md` carries status markers (✅ done / 🚧 in progress / ⏳ pending).** Update them in the same PR as the code change. Plan and code must always agree.
- **A session ends when its PR merges.** The next session opens by reading [`docs/sessions/NEXT_SESSION.md`](./docs/sessions/NEXT_SESSION.md) (the live handover doc), `PLAN.md` (next ⏳ item), and the most recent entries in `docs/sessions/`.
- **`docs/sessions/NEXT_SESSION.md` is updated as the last edit before opening every PR.** That file is always the live state; the PR's diff includes its update. See the maintenance section at the bottom of that file.
- **Architectural decision not already in the plan?** Write an ADR in `docs/decisions/NNN-short-name.md` in the same PR.

Full conventions: [`CONTRIBUTING.md`](./CONTRIBUTING.md). Session-log format: [`docs/sessions/README.md`](./docs/sessions/README.md).

## What v1 IS

Photo capture → AI listing generation → price guidance → inventory → manual copy-to-clipboard for each platform → profit tracking via email-forwarding sale detection.

## What v1 IS NOT

- Cross-listing automation (deferred to v2; see `docs/decisions/001-defer-crosslisting.md`)
- Authentication/counterfeit checking (deferred to v3)
- Android (deferred indefinitely)
- Non-UK platforms (out of scope)
- Multi-tier pricing (one tier, £7.99/month, full stop)
- AI features beyond item identification, listing generation, and price guidance

## What to do when uncertain

| Situation | Default |
|---|---|
| Two valid implementation options | Pick the simpler/boring one. |
| Touches v2 or later scope | Stop. Propose deferring. Ask user. |
| Architectural decision not in plan | Stop. Write an ADR proposal. Ask user. |
| User asks for a feature not in plan | Ask whether to add to v1 (and what to defer) or defer to v2. |
| Test seems painful to write | If it's not money math, skip. If it is money math, write it anyway. |
| Conflicting docs | `PLAN.md` wins. Then this file. Then subdirectory `CLAUDE.md`. Then docs. |

## Custom commands available

- `/plan` — re-read `PLAN.md` and orient
- `/audit` — check current state against `PLAN.md` Definition of Done (section 11)
- `/decide` — start a new ADR in `docs/decisions/`
- `/ship` — pre-commit checks, then commit and push

## Tech stack (locked)

- **Mobile**: Native iOS, SwiftUI, iOS 17+ minimum
- **Web**: Next.js 15 App Router, Vercel
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions)
- **AI**: Claude Haiku 4.5 (`claude-haiku-4-5`) — vision + text generation
- **Billing**: StoreKit 2 (iOS)
- **Item identification**: Haiku vision
- **Price comps**: eBay Browse API + Marketplace Insights API
- **Analytics**: PostHog
- **Errors**: Sentry

Do not introduce new dependencies without an ADR.

## How to think about quality

This product is for working resellers who flip 10-30 items per week. Every interaction is one they'll do 100 times this month. Optimise for:

1. **Speed of capture-to-listing** — the hero loop. Target sub-30 seconds from camera open to copy-to-clipboard.
2. **Accuracy of AI output** — wrong category or wrong price loses the user immediately. Better to ask user to confirm than to guess wrong.
3. **Reliability of money math** — getting fees, shipping, or profit numbers wrong is reputational damage that the audience talks about.

Polish goes here. Not in animations. Not in onboarding flair. In the speed, accuracy, and correctness of the hero loop.
