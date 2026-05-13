# Claude Code — Supabase Context

You are working on database migrations and edge functions.

Before any work in this directory, also read:
- `../CLAUDE.md` (root)
- `../PLAN.md`
- `../docs/data-model.md` — schema reference
- `../docs/ai-prompts.md` — for AI-calling edge functions
- `../docs/ebay-api-notes.md` — for eBay-calling edge functions

## Conventions

### Migrations
- Timestamped: `YYYYMMDDHHMMSS_short_description.sql`
- One concern per migration
- Always reversible where possible
- Run locally first with `supabase db reset`

### RLS
- Enable RLS on every table that touches user data, no exceptions
- Test policies with at least two test users to confirm isolation

### Edge functions
- TypeScript on Deno
- One function per route
- Validate inputs at the function boundary
- Return JSON with consistent shape: `{ data: ..., error: ... }`
- Log errors to Sentry

### Secrets
- Set via `supabase secrets set NAME=value`
- Never commit secrets to migrations or function code
- Reference in functions via `Deno.env.get("NAME")`

## Edge functions to build

| Function | Purpose | Auth |
|---|---|---|
| `identify-item` | Photo → Haiku vision → item data | User JWT required |
| `price-scan` | Public scanner endpoint | Anonymous + IP rate limit |
| `ebay-comps` | eBay sold comp lookup with caching | Internal (called by other functions) |
| `parse-sale-email` | Inbound email webhook for sale detection | Webhook signature validation |

## Testing migrations

```bash
supabase db reset                 # destroys local DB, re-runs all migrations
supabase functions serve          # local edge function server
supabase db lint                  # checks migrations
```

## What NOT to do

- Don't add tables not in `docs/data-model.md` without updating that doc in the same commit
- Don't disable RLS, even temporarily
- Don't put business logic in database triggers — edge functions or app code only
- Don't store API keys in the database
- Don't add a second AI provider — `ANTHROPIC_API_KEY` is the only one
