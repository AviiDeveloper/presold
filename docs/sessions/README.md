# Session logs

Every working session on this project closes with a merged pull request.
Each PR description is a structured **session log**: what shipped, why,
what's next.

This folder is the **offline mirror** of those PR descriptions. If GitHub
ever moves or disappears, the history of the project still lives here.

## File naming

```
YYYY-MM-DD-NN-short-slug.md
```

- `YYYY-MM-DD` — date the session merged
- `NN` — two-digit ordinal for that day (`01`, `02`, …)
- `short-slug` — matches the branch name (`week-0/repo-discipline` →
  `week-0-repo-discipline`)

Example: `2026-05-13-01-week-0-repo-discipline.md`

## What goes in a session log

Same structure as `.github/pull_request_template.md`, plus an **Outcome**
section at the bottom listing the merged PR URL and merge commit hash.

A canonical template:

```markdown
# [Week N, Day X] <short title>

## Goal
<one sentence>

## PLAN.md section
[Week N, Day X] — <quote or link>

## What shipped
- ✅ item
- ✅ item

## Why (decisions, trade-offs)
<short prose; link ADRs>

## Files touched
- `path/to/file` — what changed and why

## Verification
- ✅ how I tested

## What's next
<the next session's starting line>

## Outcome
- PR: <url>
- Merge commit: <sha>
- Merged at: YYYY-MM-DD HH:MM
```

## When to write it

Two options, both fine:

1. **Write it as you work** in `docs/sessions/`, then paste it into the PR
   body before opening the PR. After merge, append the Outcome section.
2. **Write the PR body first** via `gh pr create`, then mirror it back into
   `docs/sessions/` after merge.

The second is less work in the moment; the first gives you the discipline of
thinking about "what's next" while the session is still open.

## How to read this folder

Walk the files chronologically. The story of the project — every decision,
every reversal, every shipped feature — is here in order.
