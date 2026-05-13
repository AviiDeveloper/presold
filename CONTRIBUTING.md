# Contributing — how we work in this repo

This is a solo project, but it is run with the same hygiene as a team
project: every change goes through a branch and a PR. The reason is twofold.

1. **Guardrails.** Branching and PRs catch mistakes before they hit `main`.
   The diff in a PR is one last chance to spot an unintended secret, a wrong
   path, a half-finished thought.
2. **Portfolio + future-session legibility.** Every PR description is a
   session log: what shipped, why, and what's next. A reader walking the
   merged PRs in order should be able to reconstruct the project from
   nothing.

If you are the author working on this repo: follow these conventions
without exception.

---

## Branch model

- **`main`** is the trunk. Always green, always shippable.
- All work happens on feature branches named **`week-N/short-slug`**.
  - `N` is the PLAN.md week number (`week-0`, `week-1`, `week-2`, …).
  - `short-slug` is a 2-4 word kebab-case description.
  - Examples: `week-1/landing-page`, `week-1/waitlist-form`,
    `week-2/capture-flow`, `week-3/profit-view`.
- One concern per branch. If you find yourself needing to do two unrelated
  things, open a second branch.
- A branch's lifetime is a single session. If you stop mid-session, push the
  branch as WIP and finish on the next session, but **do not let branches
  accumulate**.

---

## Commit format

```
[Week N] <type>: <subject in lowercase, no trailing period>

<body explaining WHY, not what — the diff shows what>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

**Types:**
- `feat` — new functionality
- `fix` — bug fix
- `chore` — scaffolding, config, dependency bumps
- `docs` — documentation only
- `refactor` — code change that neither fixes a bug nor adds a feature
- `test` — adding or fixing tests
- `build` — build system or external dependency changes
- `ci` — CI configuration

**Rules:**
- One concern per commit. Three small commits beat one big one.
- Subject line under ~72 chars.
- Body explains motivation, trade-offs, and links to PLAN.md sections or
  ADRs when relevant.
- The `Co-Authored-By` line on AI-assisted commits is non-negotiable
  transparency.

---

## Pull request workflow

1. **Update [`docs/sessions/NEXT_SESSION.md`](./docs/sessions/NEXT_SESSION.md)** as
   the last edit of the session. Move completed items out of "What's next"
   into "What's done", set the upcoming "Next branch", add or clear any
   open follow-ups. This keeps the live handover always fresh — the PR's
   diff includes the update.
2. Open the PR with `gh pr create`. The template (in
   `.github/pull_request_template.md`) auto-populates the body.
3. Fill **every** section of the template. The PR body is the session log.
4. Self-review the diff before merging.
5. Merge with `gh pr merge --merge --delete-branch` (preserve commit history;
   we split commits intentionally — squashing destroys that signal).
6. After merge, fill the Outcome section of the matching
   `docs/sessions/YYYY-MM-DD-NN-slug.md` file with the merged PR URL +
   merge commit SHA. This is the first action of the next session, on the
   next branch.

**Never:**
- Merge a red PR (CI failures, broken tests, broken build).
- Force-push to `main`.
- Skip the template.
- Commit secrets. `.env*` and `*.xcconfig` (non-example) are gitignored;
  verify with `git status` before every push.

---

## Pre-push checklist

Before `git push`, run:

```sh
git status                              # nothing untracked or unstaged you didn't mean to add
git diff --cached --stat                # only files you expect
git log --oneline -10                   # commits look right, types correct, Co-Authored-By present
```

And specifically confirm no secret-shaped files are staged:

```sh
git diff --cached --name-only | grep -E '(^|/)\.env($|\.local$|\..*\.local$)|\.xcconfig$|secrets\.json$|\.pem$|\.key$' \
  | grep -v '\.example$' && echo "STOP — secret staged" || echo "secrets check ok"
```

---

## Session log mirroring

PR descriptions live on GitHub. They also live in `docs/sessions/` as
mirrored markdown files. If GitHub goes away, the project history survives.
See [`docs/sessions/README.md`](./docs/sessions/README.md) for the
convention.

---

## Updating PLAN.md

`PLAN.md` carries status markers next to each week's heading:

- ✅ done
- 🚧 in progress
- ⏳ pending

When a week's work completes, update the marker in the same PR that
finishes it. The plan and the code must always agree.

If you make an architectural decision not already in the plan, write an
ADR in `docs/decisions/NNN-short-name.md` in the same PR.
