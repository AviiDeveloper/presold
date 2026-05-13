# PreSold

**A UK-first reseller operating system.** Native iOS for capture, web for the public price scanner, Supabase for everything in between.

> Status: **Week 0 — scaffold complete.** Week 1 (free web tool) starts next.

---

## The problem

UK resellers — Vinted, Depop, eBay — flip 10-30 items a week. Each listing takes 5-15 minutes to write and price correctly. The existing tools (Vendoo, List Perfectly, Crosslist, SellerAider) are US-built, US-priced ($30-90/month), and treat UK platforms as afterthoughts.

PreSold collapses the listing flow to 30 seconds: photo → AI item identification → platform-specific listing copy → real eBay sold-comp price guidance → copy-to-clipboard for Vinted/Depop/eBay. v1 priced at £7.99/month, mobile-first, built by someone in the community.

Full product context, scope boundaries, and timeline live in [`PLAN.md`](./PLAN.md).

---

## Stack

- **iOS**: Native SwiftUI, iOS 17+
- **Web**: Next.js 15 (App Router), Vercel
- **Backend**: Supabase — Postgres, Auth, Storage, Edge Functions
- **AI**: Claude Haiku 4.5 — vision (item ID) + text (listing copy + price reasoning)
- **Comps**: eBay Browse API + Marketplace Insights API
- **Billing**: StoreKit 2 (iOS), no web payments in v1

Tech choices and rationale: [`docs/architecture.md`](./docs/architecture.md). Architectural decisions: [`docs/decisions/`](./docs/decisions/).

---

## Repo structure

```
PreSold/
├── ios/                    SwiftUI app
├── web/                    Next.js public web tool + marketing
├── supabase/               Postgres migrations + edge functions
├── shared/types/           JSON schemas (iOS + web share these)
├── docs/                   Architecture, data model, AI prompts, ADRs
│   ├── decisions/          ADRs (numbered)
│   └── sessions/           Per-session log mirroring merged PRs
├── PLAN.md                 Master plan — source of truth for scope + timeline
├── CLAUDE.md               Working instructions for Claude Code sessions
└── CONTRIBUTING.md         Branch / commit / PR conventions
```

Each subdirectory has its own `CLAUDE.md` with local scope.

---

## How to read this repo

This project is being built in public as a portfolio piece and a real business. The story of the build is recorded explicitly:

1. **Start with [`PLAN.md`](./PLAN.md)** — product context, v1 scope, timeline, definition of done.
2. **Walk the merged PRs in order.** Every PR description is a structured session log: goal, decisions, files touched, what's next. They are mirrored in [`docs/sessions/`](./docs/sessions/) for offline reading.
3. **Architectural decisions** that change the plan live in [`docs/decisions/`](./docs/decisions/) as numbered ADRs.

The [`CONTRIBUTING.md`](./CONTRIBUTING.md) file explains the working conventions in detail.

---

## Running locally

This will fill out as code lands. For now:

```sh
cp .env.example .env.local       # then fill in real values; never commit .env.local
```

Web app (once Week 1 lands):

```sh
cd web && npm install && npm run dev
```

iOS app (once Week 2 lands):

```
open ios/PreSold.xcodeproj
```

Required credentials are listed in [`.env.example`](./.env.example).

---

## Licence

**All Rights Reserved.** Source is public for review only; you do not have permission to fork, copy, or build a product from it. Details: [`LICENSE`](./LICENSE), [`NOTICE.md`](./NOTICE.md).

---

## Built with

[Claude Code](https://claude.com/claude-code) (Claude Opus 4.7) is used as a working collaborator. Most commits include a `Co-Authored-By` line naming the model — transparency, not deflection. Every PR description records the goal and the decisions, so the use of AI is fully visible in the project history.
