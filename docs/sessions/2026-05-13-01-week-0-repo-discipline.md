# [Week 0] Set up repo discipline (license, workflow, session logs)

## Goal

Before any feature code, set up the public GitHub repo with guardrails:
licensing, branch + PR workflow, session-log convention, and updated
context files so future sessions know exactly how to operate.

## PLAN.md section

[Week 0] — Setup. This PR closes Week 0 by establishing the working
process for every subsequent week.

## What shipped

- ✅ Public GitHub repo created at `github.com/AviiDeveloper/presold`
- ✅ Initial scaffold pushed to `main` as the t=0 baseline commit
- ✅ `LICENSE` — All Rights Reserved (public source, no fork/redistribute)
- ✅ `NOTICE.md` — plain-English explanation of the licence + AI-assistance
  transparency
- ✅ `CONTRIBUTING.md` — branch naming, commit format, PR workflow,
  pre-push checklist
- ✅ `.github/pull_request_template.md` — auto-populates the session-log
  structure on every PR
- ✅ `docs/sessions/README.md` — convention for mirroring PR descriptions
  into the repo
- ✅ First session log entry (this file)
- ✅ `README.md` — upgraded to portfolio-grade (pitch, status, stack,
  reader's guide, licence note)
- ✅ `CLAUDE.md` — workflow guardrails section added, commit format updated
- ✅ `PLAN.md` — status markers (✅/🚧/⏳) on each week heading, timeline
  softened ("goals not deadlines"), Week 0 close-out checklist added

## Why (decisions, trade-offs)

Three decisions worth recording:

1. **Licence: All Rights Reserved, not MIT.** PreSold is a real business
   competing in a US-dominated market. MIT means a competitor can lift the
   whole codebase. ARR keeps the code public for portfolio readers without
   donating it to a competitor. Trade-off: less invitation for contributors,
   which is fine — this is a solo project.

2. **Workflow: feature branches + PRs, not main-only.** Solves two needs at
   once. PR body = session log (no separate sessions/ work required during
   the session), and the diff in the PR is one last guardrail before any
   change hits `main`. Trade-off: small overhead per session. Worth it for
   portfolio polish and mistake prevention.

3. **PR template makes the session log structure mandatory.** The
   alternative was free-form PR descriptions; that drifts within weeks. A
   template enforces "what / why / files touched / what's next" forever.

## Files touched

- `LICENSE` — new; All Rights Reserved terms
- `NOTICE.md` — new; plain-English licence explanation + AI transparency
- `CONTRIBUTING.md` — new; branch, commit, PR conventions
- `.github/pull_request_template.md` — new; session-log structure
- `docs/sessions/README.md` — new; mirroring convention
- `docs/sessions/2026-05-13-01-week-0-repo-discipline.md` — new; this file
- `README.md` — rewritten; portfolio-grade
- `CLAUDE.md` — added workflow guardrails section; updated commit format
  example in operating principles
- `PLAN.md` — added status markers, softened timeline, Week 0 checklist

## Verification

- ✅ `gh repo view AviiDeveloper/presold --json visibility` returns
  `"PUBLIC"`
- ✅ `git log --oneline` on `main` shows the scaffold commit before this
  branch existed
- ✅ PR title and body match the template structure
- ✅ `git diff --cached --name-only | grep -E '\.env|secrets\.json|\.pem|\.key' | grep -v example`
  returns nothing — no secrets staged

## What's next

`week-1/nextjs-scaffold` — open Week 1, Day 1-2 from `PLAN.md`:
Next.js 15 boilerplate (`layout.tsx`, `next.config.js`, `tsconfig.json`,
`globals.css`), marketing landing page, waitlist form wired to a Supabase
insert. Code can be written ahead of Supabase credentials; testing the
waitlist insert end-to-end requires the user to create a Supabase project
and drop keys into `web/.env.local`.

## Outcome

- PR: https://github.com/AviiDeveloper/presold/pull/1
- Merge commit: `4e1930a8cad3f51c737d413c874c37995d712893`
- Merged at: 2026-05-13 16:43 UTC
