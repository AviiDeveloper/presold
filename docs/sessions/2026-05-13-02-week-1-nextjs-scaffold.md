# [Week 1, Day 1-2] Next.js scaffold, landing page, waitlist

## Goal

Stand up the web codebase: Next.js 15 App Router with Tailwind v4, the
marketing landing page, and a working waitlist signup wired to Supabase.
Stop short of `/scan` and AI — that's the next branch.

## PLAN.md section

[Week 1, Day 1-2] — "Next.js scaffold, landing page, waitlist form,
Vercel deploy". Vercel deploy is deferred to the next session because the
Vercel account isn't linked yet; everything else lands here.

## What shipped

- ✅ Next.js 15 boilerplate (`next.config.js`, `tsconfig.json`,
  `next-env.d.ts`, `.eslintrc.json`, `.gitignore`)
- ✅ Tailwind v4 set up via `@tailwindcss/postcss` with `globals.css`
  declaring monochrome design tokens + one accent (PLAN §10)
- ✅ Root layout (`app/layout.tsx`) with self-hosted Inter via `next/font`,
  metadata, viewport, OG defaults
- ✅ Marketing landing page (`app/(marketing)/page.tsx`) — hero, three-step
  how-it-works, "the bit that hurts" problem section, footer. Dry,
  direct voice per PLAN §10
- ✅ Waitlist form (`app/(marketing)/waitlist-form.tsx` + `actions.ts`) —
  Server Action with `useActionState`/`useFormStatus` progressive UX
- ✅ Waitlist API route (`app/api/waitlist/route.ts`) — JSON POST for
  non-browser callers (iOS, curl). Both entry points share
  `lib/waitlist.ts`
- ✅ Server-side Supabase client (`lib/supabase.ts`) — service-role,
  `server-only` import on the waitlist helper to guarantee the key never
  reaches the browser
- ✅ Supabase migration `20260513000004_waitlist.sql` — `waitlist` table,
  RLS on, public insert, no public read
- ✅ `docs/data-model.md` updated in the same commit (required by
  `supabase/CLAUDE.md`)

## Why (decisions, trade-offs)

1. **Server Action + API route, not one or the other.** `web/CLAUDE.md`
   specifies server actions for the waitlist form; `NEXT_SESSION.md` also
   asked for an API route. Both exist and call a single helper
   (`lib/waitlist.ts`) so duplicate-email handling, validation, and error
   shapes can't drift. The API route lets the iOS app or external clients
   hit the same endpoint later.

2. **Tailwind v4 via the new PostCSS plugin, no `tailwind.config.js`.**
   Tokens live in `globals.css` under `@theme`. This is the v4-native
   path; the older JS-config approach is supported but not the default.
   `autoprefixer` removed — Tailwind v4 handles it via Lightning CSS.

3. **Monochrome + single green accent (`#16a34a`).** PLAN §10 says
   "high contrast, monochrome with one accent." Green hints at money /
   "sells smarter" without resorting to TikTok-bright. Easy to change
   later if a designer disagrees.

4. **No client-side form library; `useActionState` is enough.** Per
   `web/CLAUDE.md`: "No client-side form library — `useState` is enough
   at this size."

5. **Duplicate email = success.** Returning success on a unique-violation
   keeps the UX honest (user sees "you're on the list") without leaking
   which addresses are already registered.

6. **`outputFileTracingRoot` pinned to `web/`.** A stray
   `~/package-lock.json` was confusing Next's workspace-root inference.
   Pinning is a one-line fix vs. asking the user to clean up their home
   directory.

## Files touched

- `supabase/migrations/20260513000004_waitlist.sql` — new; `waitlist`
  table + RLS
- `docs/data-model.md` — added the `waitlist` row in the schema table
  and a line in the RLS section
- `web/next.config.js` — new; strict mode, tracing root pinned
- `web/tsconfig.json` — new; standard App Router config + `@/*` alias
- `web/next-env.d.ts` — new (Next auto-managed)
- `web/.eslintrc.json` — new; extends `next/core-web-vitals`
- `web/.gitignore` — new; Next, env, vercel
- `web/package.json` — added `@tailwindcss/postcss`, removed
  `autoprefixer`
- `web/postcss.config.mjs` — new; Tailwind v4 plugin
- `web/app/globals.css` — new; `@theme` tokens, body defaults
- `web/app/layout.tsx` — new; Inter via `next/font`, metadata, viewport
- `web/lib/supabase.ts` — new; lazy admin client, throws if env missing
- `web/lib/waitlist.ts` — new; `server-only` insert helper, shared
  validation
- `web/app/api/waitlist/route.ts` — new; POST handler
- `web/app/(marketing)/page.tsx` — new; landing copy
- `web/app/(marketing)/waitlist-form.tsx` — new; client component
- `web/app/(marketing)/actions.ts` — new; server action
- `web/README.md` — `pnpm` → `npm` (pnpm isn't installed locally; both
  work, npm matches what was used to verify)
- `PLAN.md` — Week 1 marker ⏳ → 🚧, D1-2 ✅, D3-4 + D5 ⏳

## Verification

- ✅ `npm install` clean (357 packages, 2 moderate audit warnings —
  transitive only)
- ✅ `npm run typecheck` — no errors
- ✅ `npm run lint` — clean
- ✅ `npm run build` — production build succeeds, `/` prerendered as
  static, `/api/waitlist` registered as dynamic
- ⚠ End-to-end waitlist insert NOT tested — requires real Supabase
  credentials. Code path exercised statically by the build; real run
  blocked on user dropping keys into `web/.env.local`
- ✅ No secret-shaped files staged

## What's next

`week-1/scan-flow` — Week 1, Day 3-4: `/scan` page, `/api/scan` route,
storage upload to `scan-photos`, Haiku vision identification, eBay comp
lookup. Migration for `price_scans` already exists. Needs Anthropic +
eBay credentials available, but the scaffolding and prompts can be
written ahead of keys.

## AI assistance

Co-developed with Claude Code (Claude Opus 4.7). See commits for
`Co-Authored-By` lines.

## Outcome

<!-- Filled retrospectively after merge -->
- PR:
- Merge commit:
- Merged at:
