# PreSold

UK-first reseller operating system. iOS app, web tool, Supabase backend.

## Getting started

1. Read `PLAN.md`
2. Read `CLAUDE.md`
3. Read the `CLAUDE.md` in the subdirectory you're working in
4. Run `claude` from this directory

## Structure

- `ios/` — SwiftUI app
- `web/` — Next.js public web tool + marketing
- `supabase/` — Postgres migrations + edge functions
- `docs/` — architecture, data model, AI prompts, decision records
- `shared/types/` — JSON schemas

## Environment

Copy `.env.example` to `.env.local` and fill in values. Never commit `.env.local`.
