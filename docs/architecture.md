# Architecture

## Component map

```
┌─────────────────────┐    ┌─────────────────────┐
│  iOS app (SwiftUI)  │    │  Web (Next.js)      │
│  — Capture          │    │  — Marketing site   │
│  — Inventory        │    │  — Free scanner     │
│  — Profit           │    │  — Waitlist         │
│  — Subscription     │    │                     │
└──────────┬──────────┘    └──────────┬──────────┘
           │                          │
           └────────────┬─────────────┘
                        ▼
           ┌─────────────────────────┐
           │   Supabase              │
           │   — Auth (magic link)   │
           │   — Postgres            │
           │   — Storage (photos)    │
           │   — Edge Functions      │
           └────────────┬────────────┘
                        │
       ┌────────────────┼────────────────┐
       ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Anthropic   │  │ eBay API    │  │ Email       │
│ (Haiku 4.5) │  │ (comps)     │  │ webhook     │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Why this shape

- **iOS as primary surface**: resellers capture on phones. Native Swift gives us the camera and photo UX we need, fast.
- **Web as funnel**: free scanner is the marketing hook and shareable content unit. Not a full product surface.
- **Supabase as the spine**: one tool for auth, DB, storage, and edge compute means one set of credentials, one set of permissions, one mental model. Worth the platform lock-in trade-off at v1.
- **Edge functions for AI calls**: keeps Anthropic API key off-device, lets us cache and rate-limit centrally.

## Trust boundaries

| From | To | Trust |
|---|---|---|
| iOS app | Supabase | Authenticated via JWT, RLS-enforced |
| Web (scanner) | Supabase | Anonymous, rate-limited by IP, RLS-enforced |
| Edge function | Anthropic | Server-side key, never exposed |
| Edge function | eBay API | Server-side credentials |
| Email webhook | Supabase | Validated by user-specific token in to-address |

## What does NOT live on our servers

- User credentials for Vinted, Depop, eBay (we never ask for these in v1)
- Payment details (StoreKit handles all of this)
- Anything that would be regulated PII beyond email address

## Failure modes worth designing for

1. **Anthropic API outage during a capture**: queue the photo, retry; show user "identifying..." not "failed".
2. **eBay rate limit hit**: serve cached comps if available, otherwise show "price guidance unavailable, you can still list manually".
3. **App Store review rejection**: have a Plan B description framing the app as inventory/note-taking, not automation.
4. **Email forwarding misparses**: failed parses go to a manual review queue, never silently lose a sale.
