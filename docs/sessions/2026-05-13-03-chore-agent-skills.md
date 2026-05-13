# [Week 1] chore: install Supabase agent skills (lockfile only)

## Goal

Install the Supabase agent-skills package alongside the live MCP
connector, and codify a sensible commit pattern for skill artefacts.

## PLAN.md section

[Week 1] — infrastructure adjacent to Day 3-4 (`week-1/scan-flow`).
Not a planned task; pulled forward because the Supabase MCP guidance is
most useful before the first migration is applied from-session and
before `web/lib/database.types.ts` is generated.

## What shipped

- ✅ Installed `supabase/agent-skills` via `npx skills add` (two
  skills: `supabase`, `supabase-postgres-best-practices`)
- ✅ Committed `skills-lock.json` so reinstalls are reproducible
- ✅ Gitignored `.agents/` and `.claude/skills/` (per-machine; symlinks
  don't travel)
- ✅ Updated `docs/sessions/NEXT_SESSION.md` snapshot + follow-ups

## Why (decisions, trade-offs)

The skills installer drops three things into the repo root: `.agents/`
(skill content), `.claude/skills/` (Claude Code symlinks into
`.agents/`), and `skills-lock.json` (versions + hashes). Committing all
three would put broken-on-other-machines symlinks into git and bloat
the repo with content that's trivially reinstallable. Committing
nothing means every fresh clone runs an unpinned install.
Lockfile-only is the standard pattern (cf. `package-lock.json`):
pinned, small, and reproducible via `npx skills install`.

The skills themselves give the Supabase MCP tools (`apply_migration`,
`get_advisors`, `generate_typescript_types`, etc.) opinionated guidance
about Postgres best-practices and Supabase-specific workflows. Useful
before the `price_scans` migration is applied from-session in the next
PR.

No ADR needed — this is tooling configuration, not an architectural
decision.

## Files touched

- `.gitignore` — ignore `.agents/` and `.claude/skills/` (per-machine
  artefacts)
- `skills-lock.json` — new file pinning the two installed skills by
  hash
- `docs/sessions/NEXT_SESSION.md` — snapshot bumped to reflect PR #3
  merge and this chore in flight; follow-up added so fresh clones know
  to run `npx skills install`

## Verification

- ✅ `git status` after install showed only `.gitignore`,
  `skills-lock.json` staged; `.agents/` and `.claude/skills/` correctly
  hidden
- ✅ `cat skills-lock.json` confirmed it contains only version + skill
  hashes, no secrets
- ✅ Supabase MCP tools loaded successfully in-session (post-`/mcp`
  auth)

## What's next

`week-1/scan-flow` (Week 1 D3-4) — unchanged from the previous
handover. Scan UI + API route + `lib/anthropic.ts` + `lib/ebay.ts` + IP
rate limit. With the MCP connector now live and the skills installed,
the workflow becomes: apply `price_scans` migration → `get_advisors` →
`generate_typescript_types` → write the route against the typed
client.

## AI assistance

Co-developed with Claude Code (Claude Opus 4.7). See commits for
`Co-Authored-By` lines.

## Outcome

- PR: https://github.com/AviiDeveloper/presold/pull/4
- Merge commit: `212da63`
- Merged at: 2026-05-13
