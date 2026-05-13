---
description: Pre-commit checks, then commit and push
---

Run the following checks in order. Stop at the first failure.

1. **Plan alignment**: does the work in this commit match a section of `PLAN.md`?
2. **No deferred scope**: confirm no cross-listing automation, authentication, Android, or non-UK platform code added.
3. **Money math tests**: if `PricingService` or any sales/profit code was touched, are there passing tests?
4. **Lint/build**: run `npm run lint` in `web/` if changed. Run `xcodebuild` build if `ios/` changed.
5. **Secrets check**: grep for `sk_`, `ANTHROPIC_API_KEY=`, `SUPABASE_SERVICE_ROLE_KEY=` in staged files. Fail if any found.

If all pass, propose a commit message in the format:
`[section X.Y] short description`

Wait for my approval before running git commit.
