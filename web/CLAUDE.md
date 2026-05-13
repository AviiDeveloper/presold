# Claude Code — Web Context

You are working in the web codebase. Next.js 15 App Router, TypeScript, Tailwind.

Before any work in this directory, also read:
- `../CLAUDE.md` (root)
- `../PLAN.md`
- `../docs/data-model.md` (for any work touching `price_scans`)
- `../docs/ai-prompts.md` (for `/api/scan`)

## Purpose of the web codebase in v1

The web codebase serves TWO things only:
1. **Marketing site** — landing page, how-it-works, pricing, privacy, ToS
2. **Free price scanner tool** — `/scan` — the top-of-funnel content magnet

It does NOT serve as a full web app for the product. Users do the actual work in the iOS app.

Do not build a web dashboard, user account UI, or inventory views in the web codebase. Those belong in iOS only.

## Conventions

### Routing
- App Router (not Pages Router)
- Route groups: `(marketing)` for everything that's not the scanner

### Styling
- Tailwind for layout and spacing
- CSS variables in `globals.css` for the design tokens (colours, fonts)
- shadcn/ui for primitive components if needed; install one at a time, don't bulk import

### API routes
- All route handlers in `app/api/`
- Server-side Supabase client only; never expose service role key to the browser
- Rate-limit `/api/scan` by IP via Upstash or simple in-memory map for v1

### Forms
- Server actions for waitlist signup
- Standard `<form>` submission for the scanner upload (keep it simple)
- No client-side form library — `useState` is enough at this size

### Fonts and typography
- Use `next/font` to self-host
- One sans serif for everything, no display font

### SEO
- Open Graph image generation in `/scan/result/[slug]` for shareable scan results
- `metadata` exports on each page
- `sitemap.ts` and `robots.ts` at root

## What lives where

| Folder | What goes here |
|---|---|
| `app/` | Routes and route-specific components |
| `app/scan/` | Free price scanner |
| `app/(marketing)/` | Static marketing pages |
| `app/api/` | Route handlers |
| `components/` | Reusable components used across multiple routes |
| `lib/` | Server-side utilities (Supabase, Anthropic, eBay clients) |
| `public/` | Static assets |

## What NOT to do in web code

- Don't build a user dashboard or inventory UI in v1
- Don't implement Stripe billing in v1 (StoreKit only for v1; Stripe deferred until web has paid features)
- Don't expose Anthropic API key or eBay credentials to the client
- Don't add a state management library — server components handle most state
- Don't pre-render scan results — they're user-generated and shouldn't be in the static build
