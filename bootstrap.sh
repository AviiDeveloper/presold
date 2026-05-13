#!/usr/bin/env bash
# =============================================================================
# PreSold — Project Bootstrap
# =============================================================================
# Generates the full project scaffold, context files, and Claude Code config.
#
# Usage:
#   1. cd into the parent directory where you want the project
#   2. Run: bash bootstrap.sh
#   3. cd into ./presold
#   4. Run: claude
#   5. First message to Claude: "Read CLAUDE.md and PLAN.md, then propose
#      what to build first."
#
# This script is idempotent — safe to re-run. It will not overwrite files
# that already exist. To force a clean rebuild, delete the presold/ directory.
# =============================================================================

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-presold}"
ROOT="$(pwd)/${PROJECT_NAME}"

# --- Colours ---
if [ -t 1 ]; then
  BOLD=$(tput bold); DIM=$(tput dim); GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3); RED=$(tput setaf 1); RESET=$(tput sgr0)
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

log()   { echo "${DIM}→${RESET} $*"; }
ok()    { echo "${GREEN}✓${RESET} $*"; }
warn()  { echo "${YELLOW}!${RESET} $*"; }
fail()  { echo "${RED}✗${RESET} $*" >&2; exit 1; }
head1() { echo; echo "${BOLD}$*${RESET}"; }

# --- Safety check ---
if [ -e "${ROOT}" ] && [ "$(ls -A "${ROOT}" 2>/dev/null)" ]; then
  warn "Directory ${ROOT} already exists and is non-empty."
  warn "Will skip files that already exist. Press Ctrl-C to abort, or wait 3s to continue..."
  sleep 3
fi

mkdir -p "${ROOT}"
cd "${ROOT}"

# Helper: write file only if missing
write() {
  local path="$1"
  if [ -e "${path}" ]; then
    log "skip ${path} (exists)"
    return
  fi
  mkdir -p "$(dirname "${path}")"
  cat > "${path}"
  ok "wrote ${path}"
}

# Helper: ensure empty directory exists
ensure_dir() {
  local path="$1"
  mkdir -p "${path}"
  if [ ! -e "${path}/.gitkeep" ]; then
    touch "${path}/.gitkeep"
  fi
}

head1 "Building project at ${ROOT}"

# =============================================================================
# Directory structure
# =============================================================================
head1 "Creating directory structure"

ensure_dir "docs/decisions"
ensure_dir ".claude/commands"
ensure_dir "ios/PreSold/Config"
ensure_dir "ios/PreSold/Models"
ensure_dir "ios/PreSold/Services"
ensure_dir "ios/PreSold/Views/Root"
ensure_dir "ios/PreSold/Views/Capture"
ensure_dir "ios/PreSold/Views/Listing"
ensure_dir "ios/PreSold/Views/Inventory"
ensure_dir "ios/PreSold/Views/Profit"
ensure_dir "ios/PreSold/Views/Settings"
ensure_dir "ios/PreSold/Views/Onboarding"
ensure_dir "ios/PreSold/Views/Components"
ensure_dir "ios/PreSold/Utilities"
ensure_dir "ios/PreSold/Resources"
ensure_dir "ios/ResellTests"
ensure_dir "web/app/(marketing)"
ensure_dir "web/app/scan"
ensure_dir "web/app/api/scan"
ensure_dir "web/app/api/ebay-comps"
ensure_dir "web/app/api/waitlist"
ensure_dir "web/components"
ensure_dir "web/lib"
ensure_dir "web/public"
ensure_dir "supabase/migrations"
ensure_dir "supabase/functions/identify-item"
ensure_dir "supabase/functions/price-scan"
ensure_dir "supabase/functions/ebay-comps"
ensure_dir "supabase/functions/parse-sale-email"
ensure_dir "shared/types"

ok "directory tree created"

# =============================================================================
# Root: CLAUDE.md — first thing Claude Code reads
# =============================================================================
write "CLAUDE.md" <<'EOF'
# Claude Code Instructions — PreSold

You are working on **PreSold**, a UK-first reseller operating system.
Native iOS app (SwiftUI) + Next.js web tool + Supabase backend.

## Read these before doing anything

1. **`PLAN.md`** — master plan, scope, timeline, definition of done. Source of truth.
2. **The `CLAUDE.md` in the subdirectory you're working in** (ios, web, supabase).
3. **Relevant doc(s) in `docs/`** if your task touches them.

If you have not read `PLAN.md` this session, read it now.

## Operating principles

1. **Default to the simpler implementation.** We ship v1, not infrastructure for scale.
2. **Resist scope drift.** If your task touches anything not in v1 scope (cross-listing automation, authentication checking, Android, non-UK platforms), stop and propose deferring.
3. **One thing at a time.** Finish the current section of PLAN.md before starting another.
4. **Write tests for money math only.** `PricingService` and any code that touches profit/fees/sale_price must have tests. Skip tests for UI views and prompts.
5. **Commit messages reference the plan.** Format: `[section X.Y] short description`. Example: `[4.W2.D3] add listing review screen with platform tabs`.
6. **When you find a decision not in the plan, write an ADR.** Place in `docs/decisions/NNN-short-name.md`. Don't make undocumented architectural calls.
7. **Update PLAN.md in the same commit as the code change that contradicts it.** The plan and the code must always agree.

## What v1 IS

Photo capture → AI listing generation → price guidance → inventory → manual copy-to-clipboard for each platform → profit tracking via email-forwarding sale detection.

## What v1 IS NOT

- Cross-listing automation (deferred to v2; see `docs/decisions/001-defer-crosslisting.md`)
- Authentication/counterfeit checking (deferred to v3)
- Android (deferred indefinitely)
- Non-UK platforms (out of scope)
- Multi-tier pricing (one tier, £7.99/month, full stop)
- AI features beyond item identification, listing generation, and price guidance

## What to do when uncertain

| Situation | Default |
|---|---|
| Two valid implementation options | Pick the simpler/boring one. |
| Touches v2 or later scope | Stop. Propose deferring. Ask user. |
| Architectural decision not in plan | Stop. Write an ADR proposal. Ask user. |
| User asks for a feature not in plan | Ask whether to add to v1 (and what to defer) or defer to v2. |
| Test seems painful to write | If it's not money math, skip. If it is money math, write it anyway. |
| Conflicting docs | `PLAN.md` wins. Then this file. Then subdirectory `CLAUDE.md`. Then docs. |

## Custom commands available

- `/plan` — re-read `PLAN.md` and orient
- `/audit` — check current state against `PLAN.md` Definition of Done (section 11)
- `/decide` — start a new ADR in `docs/decisions/`
- `/ship` — pre-commit checks, then commit and push

## Tech stack (locked)

- **Mobile**: Native iOS, SwiftUI, iOS 17+ minimum
- **Web**: Next.js 15 App Router, Vercel
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions)
- **AI**: Claude Haiku 4.5 (`claude-haiku-4-5`) — vision + text generation
- **Billing**: StoreKit 2 (iOS)
- **Item identification**: Haiku vision
- **Price comps**: eBay Browse API + Marketplace Insights API
- **Analytics**: PostHog
- **Errors**: Sentry

Do not introduce new dependencies without an ADR.

## How to think about quality

This product is for working resellers who flip 10-30 items per week. Every interaction is one they'll do 100 times this month. Optimise for:

1. **Speed of capture-to-listing** — the hero loop. Target sub-30 seconds from camera open to copy-to-clipboard.
2. **Accuracy of AI output** — wrong category or wrong price loses the user immediately. Better to ask user to confirm than to guess wrong.
3. **Reliability of money math** — getting fees, shipping, or profit numbers wrong is reputational damage that the audience talks about.

Polish goes here. Not in animations. Not in onboarding flair. In the speed, accuracy, and correctness of the hero loop.
EOF

# =============================================================================
# Root: PLAN.md — the master plan, the source of truth
# =============================================================================
write "PLAN.md" <<'EOF'
# PreSold — Master Build Plan

> Source of truth. Read in full before any work session. Update in the same commit as any decision that contradicts it.

---

## 0. Product Context

### What we're building
A UK-first reseller operating system. Photo-to-listing AI, price scanner, profit calculator, inventory tracking. v2 adds cross-listing automation.

### Who it's for
UK resellers, 18-35, side-hustle to full-time. They source from charity shops, car boots, online auctions, and personal wardrobes. They list on Vinted (primary), Depop (secondary), and eBay (high-value items). Mobile-first for sourcing and capture, desktop-second for batch listing.

### The painkiller
Writing listings is the most time-consuming part of reselling. A serious reseller writes 10-30 listings per week, each taking 5-15 minutes. We collapse that to 30 seconds via AI listing generation, and we tell them the right price using real sold-comp data so they don't undersell or overprice.

### Why we beat the existing market
Vendoo, List Perfectly, Crosslist, SellerAider are US-built, US-priced ($30-90/month), bloated, and treat UK platforms as afterthoughts. We are UK-native, mobile-first, priced for UK reseller budgets (£7.99/month launch), and built by someone in the community.

### Marketing channel
TikTok influencer-led, UK reseller niche (#ukreseller, #vintedseller, #depopseller). Paid drops £200-500 + 30% recurring affiliate. Free web tool (price scanner) is the top-of-funnel content magnet. Organic on creator's own TikTok and Reddit (r/UKReselling, r/Vinted, r/Depop).

### Success criteria
- £1k/week recurring revenue within 16 weeks of v1 launch
- 200+ active paying users at £7.99/month within 5 months
- One viral TikTok with 100k+ views in first 8 weeks post-launch

### Non-goals (resist these explicitly)
- Cross-listing automation in v1
- Authentication / counterfeit checking
- Multi-currency or non-UK platforms
- Android app in v1
- Features that require >£500/month in API costs at 200 active users
- Any AI feature beyond item identification, listing generation, and price guidance

---

## 1. Architecture Overview

### Stack
- **Mobile**: Native iOS, SwiftUI, iOS 17+
- **Web**: Next.js 15 App Router, Vercel
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions)
- **AI**: Claude Haiku 4.5 (`claude-haiku-4-5`) for vision + text generation
- **Billing**: StoreKit 2 on iOS, Stripe deferred until web has paid features
- **Comps**: eBay Browse API + Marketplace Insights API
- **Analytics**: PostHog (free tier)
- **Errors**: Sentry (free tier)

### Why this stack
- **SwiftUI**: native, fast iteration if fluent, no React Native maintenance tax
- **Next.js**: fastest path to public web tool with email capture and SEO
- **Supabase**: auth + db + storage + edge functions in one, already familiar from SL-MAS
- **Haiku 4.5 vision**: ~£0.002 per item ID + listing generation, fast, sufficient quality

### Data flow
```
iPhone capture → Haiku vision (item ID + listing copy)
              → eBay API (sold comps for price guidance)
              → Supabase (item stored, photo in storage, listing draft)
              → User reviews and edits on phone
              → Manual copy-to-clipboard per platform (v1)
              → User pastes into Vinted/Depop/eBay native app
              → Email forward to <token>@sales.presold.app when sold
              → Supabase updates item status, profit calculated
```

---

## 2. Folder Structure

See actual filesystem. Key locations:

- `CLAUDE.md` — Claude Code primary context (root)
- `PLAN.md` — this file
- `docs/` — architecture, data model, AI prompts, ADRs
- `ios/` — SwiftUI app
- `web/` — Next.js web tool + marketing
- `supabase/` — DB migrations, edge functions
- `shared/types/` — JSON schemas shared between iOS and web

Each subdirectory has its own `CLAUDE.md` with scope and conventions for that layer.

---

## 3. Data Model

See `docs/data-model.md` for full schema and rationale.

Core tables: `users`, `items`, `photos`, `listings`, `sales`, `price_scans`.

---

## 4. Build Timeline

Off-time pace, ~15-20 hrs/week.

### Week 0: Setup (2-3 evenings, parallel work)
1. Buy domain (working name: `presold.app` or chosen brand)
2. Apple Developer account (£79/year, 2-3 day provisioning)
3. eBay Developer account (apply now, ~5 days for production access)
4. Anthropic API key with billing
5. Supabase project created
6. Vercel account linked to GitHub
7. PostHog account
8. Sentry account
9. Run `bootstrap.sh` (this scaffold)
10. First commit

### Week 1: Free web tool ships (4-5 evenings)
**Goal: public price scanner live, email capture working, first TikTok using it.**

- D1-2: Next.js scaffold, landing page, waitlist form, Vercel deploy
- D3-4: `/scan` page, `/api/scan` route, Supabase `price_scans` table + storage, Haiku vision identification, eBay comp lookup
- D5: shareable result page (OG images), polish, post first TikTok

**Deliverable**: live URL, working scanner, first content posted.

### Week 2: iOS app skeleton + capture flow (5-7 evenings)
**Goal: capture an item end-to-end on TestFlight.**

- D1-2: Xcode scaffold, Supabase Swift client, magic-link auth, tab bar
- D3-4: Capture flow (multi-photo capture, upload), `identify-item` edge function, listing display
- D5-7: Listing review screen (Vinted/Depop/eBay tabs), copy-to-clipboard, inventory list, persistence

**Deliverable**: end-to-end capture-to-clipboard working on real iPhone.

### Week 3: Inventory, profit, polish (4-6 evenings)
**Goal: beta-ready product.**

- D1-2: Inventory filters, item detail view, status transitions, manual sold flow
- D3: Profit view, `PricingService` with fee constants
- D4: Email forward setup, `parse-sale-email` edge function
- D5-6: StoreKit 2 integration, capture flow polish, self-dogfood 30 items

**Deliverable**: beta-ready product, used on 30 real items.

### Week 4: Beta + marketing prep (3-4 evenings)
**Goal: 10 beta users, first influencer scheduled, App Store submitted.**

- D1: Onboarding polish, privacy, ToS, support email, TestFlight invite
- D2: Outreach to 5-10 TikTok creators, 10 friends-of-friends for beta
- D3-4: Fix beta feedback, App Store submission

**Deliverable**: TestFlight live, App Store review submitted, first influencer drop scheduled.

### Week 5+: Launch and iterate
- App Store approval (3-7 days)
- First influencer drop, paid post + 30% affiliate
- £30-50/day Meta ads to demo video
- Weekly iteration on PostHog data

---

## 5. AI Prompts

See `docs/ai-prompts.md`. All prompts versioned and centralised.

---

## 6. Platform-Specific Notes

See `docs/ebay-api-notes.md` for eBay specifics. Vinted and Depop notes below.

### Vinted (UK)
- No public listing API
- v1: copy-to-clipboard only
- Fee: 0% to seller (buyer pays Buyer Protection)
- Title max: 50 chars
- Categories: deeply nested

### Depop
- No public listing API
- v1: copy-to-clipboard only
- ToS permits cross-listing tools
- Fee: 10% to seller
- First line of description = effective title
- Tags: max 5, critical for discovery
- Photos: up to 4

### eBay UK
- Public API (Browse, Selling, Marketplace Insights)
- v1: copy-to-clipboard
- v1.1: optional direct posting via eBay API for users who connect their account
- Fee: 12.8% final value + £0.30
- Title: 80 chars max
- Photos: up to 12

---

## 7. Pricing Logic

### Subscription
- 14-day trial, no credit card
- £7.99/month after trial
- £69/year (28% discount)
- Single tier

### Profit math
```
gross_proceeds = sale_price
platform_fee   = sale_price * rate + fixed
net_proceeds   = gross_proceeds - platform_fee - shipping_cost
profit         = net_proceeds - cost_basis
margin_percent = profit / gross_proceeds * 100
```

### Platform fee constants
- Vinted: 0% + £0
- Depop: 10% + £0
- eBay: 12.8% + £0.30

Shipping defaults to user-set value or category estimate.

---

## 8. Risks and Mitigations

### Build risks
- **SwiftUI fluency**: if slower than expected, ship v1 without ProfitView, add in v1.1
- **eBay API approval delay**: fallback to scraping eBay sold listings via edge function
- **App Store rejection**: keep v1 free of WKWebView automation; position as "inventory and listing assistant"

### Marketing risks
- **First influencer doesn't convert**: budget 3 attempts at £400-500 before iterating product
- **AI listing quality mediocre**: spend a real week on prompts with 100+ real reseller items as test set before launch
- **Pricing wrong**: if month-1 churn high, drop to £4.99 + ad-supported free tier before killing the product

### Operational risks
- **eBay API rate limits**: cache comp data per (item_category, query) for 24h
- **AI cost spike from web tool abuse**: rate-limit free scanner to 3 scans per IP per day
- **Supabase quota**: monitor storage and DB egress, upgrade before hitting limits

---

## 9. What Claude Code Should Do When Uncertain

1. Default to the simpler implementation. Ship v1.
2. If feature touches "cross-listing automation," defer to v2.
3. If UI choice is between minimal and feature-rich, choose minimal.
4. If adding a third tier of pricing, a second AI model, or a non-UK platform, stop and re-read section 0.
5. Tests for `PricingService` and any code touching money. Skip UI tests.
6. Commit messages reference the plan section.
7. Architectural decisions not in this plan → ADR in `docs/decisions/`, update this plan.

---

## 10. Brand and Tone

### Voice
- Direct, dry, no hype
- "Lists faster, sells smarter" — not "revolutionise your reselling"
- Reseller language: flip, haul, sourced from, tagged, listed

### Visual
- High contrast, monochrome with one accent
- Photography-led
- No stock images, no AI art
- Real photos of real items in screenshots

---

## 11. Definition of Done for v1

The product is ready for first influencer drop when:

- [ ] User signs up via email magic link
- [ ] User captures 1-6 photos of an item
- [ ] AI returns item details with ≥75% accuracy on test set of 50 real reseller items
- [ ] AI returns listing copy for Vinted/Depop/eBay with platform-correct formatting
- [ ] Price guidance returns sensible range with sold comp citations
- [ ] User copies listing to clipboard per platform
- [ ] Inventory view shows all items with status
- [ ] User manually marks item sold, sees profit
- [ ] Email forwarding parses real Vinted/Depop/eBay sale emails correctly
- [ ] StoreKit subscription works with 14-day trial
- [ ] App passes App Store review
- [ ] Public web scanner live and converting waitlist signups
- [ ] PostHog tracking key events (signup, first_item, first_listing, first_sale)
- [ ] You have personally used the app on 30+ real items

If any are not true, do not launch. Fix first, ship second.

---

End of plan. Update in the same commit as any decision that contradicts it.
EOF

# =============================================================================
# Root: README, .gitignore, .env.example
# =============================================================================
write "README.md" <<'EOF'
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
EOF

write ".gitignore" <<'EOF'
# Environments
.env
.env.local
.env.*.local
*.xcconfig
!*.xcconfig.example

# Node
node_modules/
.next/
out/
.vercel
dist/
build/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# iOS / Xcode
ios/build/
ios/DerivedData/
ios/*.xcuserstate
ios/**/xcuserdata/
ios/Pods/
ios/*.xcworkspace/xcuserdata/
*.ipa
*.dSYM.zip

# Supabase
supabase/.branches
supabase/.temp

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*~

# Secrets
secrets.json
*.pem
*.key

# Claude Code
.claude/cache/
EOF

write ".env.example" <<'EOF'
# =============================================================================
# PreSold — environment variables template
# Copy this file to .env.local and fill in real values.
# Never commit .env.local.
# =============================================================================

# --- Supabase ---
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=   # server-side only, never expose to client

# --- Anthropic ---
ANTHROPIC_API_KEY=

# --- eBay (apply at developer.ebay.com) ---
EBAY_APP_ID=
EBAY_CERT_ID=
EBAY_DEV_ID=
EBAY_ENV=PRODUCTION          # or SANDBOX

# --- Analytics ---
POSTHOG_API_KEY=
POSTHOG_HOST=https://eu.posthog.com

# --- Errors ---
SENTRY_DSN=

# --- Email forwarding (for sale detection) ---
SALES_EMAIL_DOMAIN=sales.presold.app
EOF

# =============================================================================
# .claude/ — Claude Code settings and custom commands
# =============================================================================
write ".claude/settings.json" <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings",
  "instructions": "Read CLAUDE.md and PLAN.md at the start of every session. Defer to PLAN.md as the source of truth.",
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(pnpm:*)",
      "Bash(yarn:*)",
      "Bash(supabase:*)",
      "Bash(xcodebuild:*)",
      "Bash(swift:*)",
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(rg:*)",
      "Edit",
      "Read",
      "Write"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)"
    ]
  },
  "env": {
    "ANTHROPIC_MODEL_DEFAULT": "claude-haiku-4-5"
  }
}
EOF

write ".claude/commands/plan.md" <<'EOF'
---
description: Re-read PLAN.md and orient on current scope
---

Read `PLAN.md` in full. Then:

1. Summarise the current section of the build timeline (section 4) we should be in based on what's been committed so far.
2. List the next 3 concrete tasks from the plan.
3. Flag any work-in-progress that doesn't match the plan.
4. Stop and wait for direction.
EOF

write ".claude/commands/audit.md" <<'EOF'
---
description: Audit current state against PLAN.md Definition of Done
---

Read `PLAN.md` section 11 (Definition of Done for v1). For each checkbox:

1. Determine if it's complete based on the code in this repo.
2. If complete, state the file(s) that implement it.
3. If incomplete, state what's missing and the estimated effort.
4. Output a single table: criterion | status (done / partial / not started) | notes.

Do not make changes. This is read-only.
EOF

write ".claude/commands/decide.md" <<'EOF'
---
description: Start a new Architecture Decision Record
---

We need to record an architectural decision.

Ask me:
1. What is the decision in one sentence?
2. What alternatives did we consider?
3. Why did we choose this option?
4. What does it cost us?

Then create `docs/decisions/NNN-short-name.md` (next available number) with the structure:

```
# NNN. Title

Date: YYYY-MM-DD
Status: Accepted

## Context
[what triggered this decision]

## Decision
[what we decided]

## Alternatives
[what else we considered]

## Consequences
[trade-offs we accepted]
```

After writing, update `PLAN.md` if this decision contradicts anything there.
EOF

write ".claude/commands/ship.md" <<'EOF'
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
EOF

# =============================================================================
# docs/ — supporting documentation
# =============================================================================
write "docs/architecture.md" <<'EOF'
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
EOF

write "docs/data-model.md" <<'EOF'
# Data Model

All tables in Postgres via Supabase. RLS enabled on every table touching user data.

## Tables

### `users` (extension of `auth.users`)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | FK to `auth.users.id` |
| `email` | text | mirrored from auth |
| `created_at` | timestamptz | default now() |
| `subscription_status` | text | enum: trial, active, cancelled, expired |
| `subscription_provider` | text | enum: storekit, stripe |
| `subscription_expires_at` | timestamptz | |
| `sale_email_token` | text | unique, used for `<token>@sales.presold.app` |

### `items`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK | users.id |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |
| `title` | text | universal title |
| `description` | text | universal description |
| `category` | text | |
| `brand` | text | |
| `size` | text | |
| `color` | text | |
| `condition` | text | enum: new_with_tags, new_without_tags, very_good, good, satisfactory |
| `cost_basis` | numeric(10,2) | what user paid |
| `target_price` | numeric(10,2) | user's chosen list price |
| `weight_grams` | integer | for shipping calc |
| `status` | text | enum: draft, listed, sold, archived |
| `ai_confidence` | numeric(3,2) | 0-1 from Haiku |
| `ai_prompt_version` | text | for prompt iteration tracking |
| `notes` | text | |

### `photos`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `item_id` | uuid FK | items.id |
| `storage_path` | text | path in `item-photos` bucket |
| `order_index` | integer | 0 = primary |
| `is_primary` | boolean | |
| `width` | integer | |
| `height` | integer | |
| `created_at` | timestamptz | |

### `listings`

Per-platform listing drafts. One item can have up to three listings.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `item_id` | uuid FK | items.id |
| `platform` | text | enum: vinted, depop, ebay |
| `title` | text | platform-specific |
| `description` | text | platform-specific |
| `category_id` | text | platform-specific ID |
| `tags` | text[] | depop only, max 5 |
| `price` | numeric(10,2) | |
| `status` | text | enum: draft, copied, posted, sold |
| `posted_at` | timestamptz nullable | |
| `posted_url` | text nullable | if user pastes back |

### `sales`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `item_id` | uuid FK | items.id |
| `listing_id` | uuid FK nullable | |
| `platform` | text | |
| `sale_price` | numeric(10,2) | gross |
| `platform_fee` | numeric(10,2) | calculated |
| `shipping_cost` | numeric(10,2) | |
| `net_proceeds` | numeric(10,2) | |
| `profit` | numeric(10,2) | |
| `sold_at` | timestamptz | |
| `source` | text | enum: email, manual |

### `price_scans`

Public, used by free web tool. Rate-limited per IP.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `email` | text nullable | captured for full result |
| `ip_address` | text | rate limiting |
| `created_at` | timestamptz | |
| `item_data` | jsonb | identified item details |
| `comp_data` | jsonb | sold comp results |
| `shareable_slug` | text unique | for /scan/result/[slug] |

## Storage buckets

- **`item-photos`** — private, signed URLs only, lifecycle: never deleted
- **`scan-photos`** — public, signed URLs expiring after 30 days

## RLS policies

- `items`, `photos`, `listings`, `sales`: `user_id = auth.uid()` on all operations
- `price_scans`: anyone can insert; anyone can read by `shareable_slug` for sharing
- `users`: user can read own row; service role only can update subscription fields

## Indexes worth having from day one

- `items(user_id, status, updated_at desc)` — inventory list query
- `listings(item_id)` — load all platform drafts for an item
- `sales(user_id, sold_at desc)` — profit view query
- `price_scans(shareable_slug)` — unique constraint covers this
EOF

write "docs/ai-prompts.md" <<'EOF'
# AI Prompts

All prompts use `claude-haiku-4-5`. Centralised here so iOS and web share the same source of truth.

When you change a prompt:
1. Bump the version in this doc.
2. Update the version constant in `ios/PreSold/Services/AIService.swift` and `web/lib/anthropic.ts`.
3. Store the version with each item in `items.ai_prompt_version`.

---

## Prompt 1: Item identification + universal listing
**Version**: `v1.0`
**Used by**: iOS `Capture` flow, web `/scan` endpoint

### System
```
You are a UK reseller's assistant. You look at photos of a second-hand item and identify it, then write listing copy.

Be conservative. If you cannot tell the brand or size from the photos, return null for that field — never guess. UK resellers are punished for inaccurate listings.

Always return valid JSON matching the schema. Never include commentary outside the JSON.
```

### User
```
Photos: [1-6 image inputs]

Optional context from user (may be empty): {user_context}

Return JSON matching this schema:
{
  "title": "string, max 60 chars, sentence case, no clickbait",
  "description": "string, 2-4 short paragraphs, factual, mention condition and any flaws visible",
  "brand": "string or null",
  "category": "string, broad category like 'Women's tops' or 'Men's trainers'",
  "size": "string or null, UK sizing if clothing",
  "color": "string, primary colour",
  "condition": "one of: new_with_tags, new_without_tags, very_good, good, satisfactory",
  "weight_grams_estimate": "integer, for shipping",
  "confidence": "number 0-1, how sure you are about brand and category"
}
```

---

## Prompt 2: Platform-specific listing reformatting
**Version**: `v1.0`
**Used by**: iOS `Listing` flow (after Prompt 1)

### System
```
You take a universal item listing and rewrite it for a specific UK reselling platform. Follow the platform's conventions exactly.
```

### User
```
Item:
{universal_item_json}

Target platform: {platform}

Rules per platform:
- vinted: title max 50 chars, no hashtags in title or description, include brand prominently
- depop: first line of description IS the title (max 65 chars), description can include up to 5 tags as #tags at the end, casual tone
- ebay: title max 80 chars, keyword-stuffed (include brand + colour + size + size + key descriptor), description more formal

Return JSON:
{
  "title": "string",
  "description": "string",
  "tags": ["array of strings, max 5, depop only otherwise empty array"]
}
```

---

## Prompt 3: Price guidance synthesis
**Version**: `v1.0`
**Used by**: edge function `price-scan` and iOS after `identify-item`

### System
```
You are a UK reseller pricing assistant. You receive an identified item and a list of recent sold comp prices from eBay. You return a price recommendation with reasoning.

If comps are sparse (under 3) or have wide variance (>50% spread), say so honestly. Do not invent confidence you don't have.
```

### User
```
Item:
{universal_item_json}

eBay sold comps (last 90 days):
{comps_json}

Return JSON:
{
  "price_low": "number, GBP, conservative quick-sale price",
  "price_recommended": "number, GBP, balanced price",
  "price_high": "number, GBP, patient-seller price",
  "sell_speed_estimate": "one of: fast (days), medium (1-2 weeks), slow (a month or more), uncertain",
  "reasoning": "string, 1-2 sentences, cite the comp data",
  "comp_count": "integer",
  "confidence": "number 0-1"
}
```

---

## Versioning rules

- Prompt changes that affect output shape: major version bump (e.g. v1.0 → v2.0)
- Prompt changes that improve quality but preserve output shape: minor bump (v1.0 → v1.1)
- Track version in items so we can A/B compare quality over time
EOF

write "docs/ebay-api-notes.md" <<'EOF'
# eBay API Notes

## APIs we use

1. **Browse API** — find similar active listings (not used in v1)
2. **Marketplace Insights API** — sold comp data, last 90 days, this is the one we care about

## Marketplace Insights gotchas

- Requires production access, **not** sandbox. Sandbox returns empty comp arrays.
- Production access requires a real eBay account in good standing and an app submission. Allow 5-10 business days.
- Rate limits: 5 calls/second, 5,000/day on free tier. Cache aggressively.
- The "sold" filter requires `filter=conditionIds:{...}&filter=buyingOptions:{...}` syntax — read the docs carefully.

## Auth

OAuth 2.0 client credentials grant for application-level calls (sold comp lookup is application-level, not user-level).

```
POST https://api.ebay.com/identity/v1/oauth2/token
Authorization: Basic base64(EBAY_APP_ID:EBAY_CERT_ID)
grant_type=client_credentials&scope=https://api.ebay.com/oauth/api_scope
```

Token lasts 2 hours. Cache and refresh.

## Query strategy

For each item identification, we issue ONE query:
```
GET /buy/marketplace_insights/v1_beta/item_sales/search
  ?q={brand} {category} {size}
  &filter=conditionIds:{1500|3000|4000}        # used conditions
  &limit=50
  &marketplace_ids=EBAY_GB
```

If results sparse (<3), broaden by dropping size. If still sparse, drop brand. Mark `confidence` accordingly.

## Cache strategy

- Cache key: `sha256(query_string)`
- TTL: 24 hours
- Storage: Supabase `cache` table or Vercel KV (decide in week 1)

## Fallback if API approval delayed

Edge function scrapes eBay UK sold listings page with rotating User-Agents. Same query syntax in URL. Parse with cheerio in Deno edge runtime. Slower, fragile, but unblocks the v1 launch if eBay drags on approval.

Document this as a temporary measure in an ADR if you build it.
EOF

write "docs/decisions/001-defer-crosslisting.md" <<'EOF'
# 001. Defer cross-listing automation to v2

Date: 2026-05-13
Status: Accepted

## Context

Cross-listing automation (one-tap post to Vinted + Depop + eBay) is the headline value prop of competitors like Vendoo, List Perfectly, Crosslist. It is also the most technically fragile feature: Vinted and Depop have no public APIs, every UI change on those platforms breaks integration, and the App Store has rejected apps that primarily automate third-party websites in WebViews.

We considered three architectures:
- WKWebView automation inside the iOS app
- Server-side headless browsers
- Chrome extension companion

All three carry meaningful risk for v1.

## Decision

v1 ships **without** cross-listing automation. Instead:
- AI generates platform-specific listing copy for Vinted, Depop, eBay
- User taps copy-to-clipboard per platform
- User pastes into the platform's native app manually

v2 adds WKWebView-based automation for Vinted and Depop, eBay API for direct posting.

## Alternatives

- **Ship cross-listing in v1**: build slips by 2-3 weeks, launch is gated on the most fragile feature, App Store risk is non-zero, single bug can kill all credibility.
- **Ship server-side automation**: legal/operational sinkhole, platforms ban server IPs, GDPR exposure from storing third-party credentials.

## Consequences

- v1 launch is faster (saves ~2 weeks)
- Marketing positioning loses "one-tap everywhere" promise; reframed as "AI writes your listing in 30 seconds, copy to each platform"
- Retention may be lower than competitors because copy-paste friction remains
- v2 has a clear value-add to justify a price increase or feature gate
- App Store risk on v1 is essentially zero
EOF

write "docs/decisions/002-native-swift-not-rn.md" <<'EOF'
# 002. Native SwiftUI, not React Native

Date: 2026-05-13
Status: Accepted

## Context

Mobile-first product. Choice between:
- React Native (one codebase, iOS + Android)
- Native SwiftUI (iOS only)

## Decision

Native SwiftUI, iOS only for v1.

## Alternatives

- **React Native**: covers Android, but founder is already fluent in SwiftUI from prior projects; camera UX matters here and is harder to polish in RN; RN adds a dependency layer that breaks unpredictably.
- **Native Swift + native Android (Kotlin)**: doubles build time.

## Consequences

- Lose ~35% of UK reseller market (Android users) at launch
- Camera capture and photo UX is best-in-class on iOS
- Future Android port is a real cost; budget 3-4 weeks of off-time if we do it
- Plan to add Android in v3 if v2 traction justifies it
EOF

write "docs/decisions/003-no-mobile-crosslisting-v1.md" <<'EOF'
# 003. Cross-listing deferred and copy-to-clipboard in v1

Date: 2026-05-13
Status: Accepted

## Context

Even with cross-listing deferred (see 001), we needed to decide how the user transfers AI-generated listing copy from our app to Vinted/Depop/eBay in v1.

## Decision

Per-platform copy-to-clipboard. Three buttons in the listing review screen (Vinted, Depop, eBay), each copies the platform-formatted listing to clipboard. User then opens the target platform's native app, paste into the title and description fields, attach photos manually for v1.

## Alternatives

- **Deep linking**: open Vinted/Depop/eBay app with pre-filled fields via URL scheme. Coverage is inconsistent (Vinted has no public deep link spec) and photos can't be pre-attached.
- **Share sheet integration**: technically possible, but UX is confusing for users who don't know which "share to" option to pick.

## Consequences

- v1 UX is "copy, switch app, paste, attach photos, post" — about 90 seconds per platform
- Still meaningfully faster than writing the listing from scratch
- Photos remain a friction point; users have to re-pick from camera roll in the target app
- v2 will fix all of this with WKWebView automation
EOF

# =============================================================================
# ios/CLAUDE.md
# =============================================================================
write "ios/CLAUDE.md" <<'EOF'
# Claude Code — iOS Context

You are working in the iOS app. Native SwiftUI, iOS 17+ minimum.

Before any work in this directory, also read:
- `../CLAUDE.md` (root)
- `../PLAN.md`
- `../docs/data-model.md` (for any work touching persistence)
- `../docs/ai-prompts.md` (for any AI integration)

## Conventions

### File organisation
- One type per file
- View + ViewModel pair lives in the same folder, named e.g. `CaptureView.swift` + `CaptureViewModel.swift`
- Services are singletons accessed via `ServiceName.shared` for now; we'll refactor to DI when the app exceeds 30 screens (it won't in v1)
- Models are plain structs, Codable where they cross the wire

### View patterns
- Use `@Observable` (iOS 17+) over `ObservableObject`
- Prefer `.task { ... }` over `.onAppear { Task { ... } }`
- Long-running work in ViewModels, not Views
- No business logic in Views — Views render, ViewModels decide

### State management
- Local UI state: `@State`
- Cross-view state: `@Observable` view models passed via initialiser
- App-wide state: `@Environment` (only for things like current user, never for transient state)

### Networking
- All Supabase calls through `SupabaseClient.shared`
- All Claude API calls through `AIService.shared` (which proxies through Supabase edge function, never directly from device)
- All eBay calls through Supabase edge function — never directly from device

### Error handling
- Network errors: surface as `Result<T, AppError>` to ViewModel
- Show user-friendly message via `@State var errorMessage: String?` pattern
- Log to Sentry in production

### Money math
- ALWAYS use `Decimal` for prices, fees, profits. Never `Double` or `Float`.
- All formatting through `CurrencyFormatter.gbp` (in Utilities)
- `PricingService` is the only place that calculates fees and profit. Tested.

### Concurrency
- Async/await throughout
- `@MainActor` on ViewModels by default
- Background work explicitly marked with `Task.detached` only when needed

## What lives where

| Folder | What goes here |
|---|---|
| `Models/` | Codable structs, enums, value types |
| `Services/` | Network, persistence, system integrations (camera, StoreKit) |
| `Views/` | SwiftUI views + view models |
| `Views/Components/` | Reusable UI building blocks |
| `Utilities/` | Pure functions, formatters, helpers |
| `Config/` | Environment configuration, never secrets |
| `Resources/` | Strings, fonts, assets references |

## What NOT to do in iOS code

- Don't add WKWebView automation for cross-listing (v2, see ADR 001)
- Don't store user credentials for Vinted/Depop/eBay
- Don't call Anthropic or eBay APIs directly from the app
- Don't use Combine — async/await throughout
- Don't add a routing library — NavigationStack is enough for v1
- Don't add a state management library — `@Observable` is enough for v1
EOF

write "ios/README.md" <<'EOF'
# PreSold iOS

Native SwiftUI app for UK resellers.

## Setup

1. Open `PreSold.xcodeproj` in Xcode 15+
2. Copy `PreSold/Config/Secrets.xcconfig.example` to `PreSold/Config/Secrets.xcconfig`
3. Fill in values from project Supabase + Anthropic accounts
4. Run on a real device for camera testing (simulator camera is limited)

## Architecture

See `CLAUDE.md` in this directory.

## Conventions

See `CLAUDE.md` in this directory.
EOF

# =============================================================================
# web/CLAUDE.md
# =============================================================================
write "web/CLAUDE.md" <<'EOF'
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
EOF

write "web/README.md" <<'EOF'
# PreSold Web

Next.js 15 app for marketing site and free price scanner.

## Setup

```bash
cd web
pnpm install
cp .env.local.example .env.local   # fill in values
pnpm dev
```

## What it is

- Landing page + marketing
- Free price scanner (top-of-funnel)
- Waitlist signup for iOS app

## What it is NOT

- A web version of the iOS app
- A user dashboard
- A billing portal

See `CLAUDE.md` in this directory.
EOF

# =============================================================================
# supabase/CLAUDE.md
# =============================================================================
write "supabase/CLAUDE.md" <<'EOF'
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
EOF

# =============================================================================
# shared/CLAUDE.md
# =============================================================================
write "shared/CLAUDE.md" <<'EOF'
# Claude Code — Shared Types Context

JSON schemas shared between iOS and web for AI prompt outputs and inter-service contracts.

## Why this exists

When iOS and web both consume the output of the same AI prompt or edge function, the schema should be defined once and consumed in both languages. This directory holds JSON Schema files that are the source of truth.

## Conventions

- One schema per file, named after the type
- Use JSON Schema draft 2020-12
- Each schema has a `$id`, `title`, `description`, and `$schema`
- Match exactly to the prompt output in `docs/ai-prompts.md`

## Files

- `item.schema.json` — Output of `identify-item`
- `listing.schema.json` — Output of platform reformatting
- `price-guidance.schema.json` — Output of price guidance
- `platform.schema.json` — Enum of platforms

## How to keep in sync

When you change a prompt output:
1. Update the prompt in `docs/ai-prompts.md` (bump version)
2. Update the schema here
3. Regenerate Swift types (manually for now) in `ios/PreSold/Models/`
4. Regenerate TypeScript types in `web/lib/types.ts`

Manual sync is fine in v1. If it becomes painful, add a codegen step in v2.
EOF

# =============================================================================
# Initial schema migration
# =============================================================================
write "supabase/migrations/20260513000001_initial_schema.sql" <<'EOF'
-- Initial schema for PreSold
-- See docs/data-model.md for rationale

-- USERS extension
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  created_at timestamptz default now() not null,
  subscription_status text default 'trial' check (subscription_status in ('trial','active','cancelled','expired')),
  subscription_provider text check (subscription_provider in ('storekit','stripe')),
  subscription_expires_at timestamptz,
  sale_email_token text unique not null default replace(gen_random_uuid()::text, '-', '')
);

-- ITEMS
create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  title text,
  description text,
  category text,
  brand text,
  size text,
  color text,
  condition text check (condition in ('new_with_tags','new_without_tags','very_good','good','satisfactory')),
  cost_basis numeric(10,2),
  target_price numeric(10,2),
  weight_grams integer,
  status text default 'draft' check (status in ('draft','listed','sold','archived')),
  ai_confidence numeric(3,2),
  ai_prompt_version text,
  notes text
);
create index items_user_status_idx on public.items (user_id, status, updated_at desc);

-- PHOTOS
create table public.photos (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  storage_path text not null,
  order_index integer default 0 not null,
  is_primary boolean default false not null,
  width integer,
  height integer,
  created_at timestamptz default now() not null
);
create index photos_item_idx on public.photos (item_id);

-- LISTINGS
create table public.listings (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  platform text not null check (platform in ('vinted','depop','ebay')),
  title text,
  description text,
  category_id text,
  tags text[] default '{}',
  price numeric(10,2),
  status text default 'draft' check (status in ('draft','copied','posted','sold')),
  posted_at timestamptz,
  posted_url text,
  unique (item_id, platform)
);
create index listings_item_idx on public.listings (item_id);

-- SALES
create table public.sales (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  listing_id uuid references public.listings(id) on delete set null,
  platform text not null check (platform in ('vinted','depop','ebay')),
  sale_price numeric(10,2) not null,
  platform_fee numeric(10,2) not null default 0,
  shipping_cost numeric(10,2) not null default 0,
  net_proceeds numeric(10,2) not null,
  profit numeric(10,2) not null,
  sold_at timestamptz not null,
  source text not null check (source in ('email','manual'))
);
create index sales_user_sold_idx on public.sales ((select user_id from public.items where id = item_id), sold_at desc);

-- PRICE SCANS (public, free tool)
create table public.price_scans (
  id uuid primary key default gen_random_uuid(),
  email text,
  ip_address text,
  created_at timestamptz default now() not null,
  item_data jsonb,
  comp_data jsonb,
  shareable_slug text unique not null default replace(gen_random_uuid()::text, '-', '')
);

-- Trigger: updated_at on items
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger items_updated_at
  before update on public.items
  for each row execute function public.update_updated_at();
EOF

write "supabase/migrations/20260513000002_rls.sql" <<'EOF'
-- Row Level Security
-- All tables that touch user data must enforce ownership

-- Enable RLS
alter table public.users enable row level security;
alter table public.items enable row level security;
alter table public.photos enable row level security;
alter table public.listings enable row level security;
alter table public.sales enable row level security;
alter table public.price_scans enable row level security;

-- USERS: self-access only
create policy users_select_own on public.users
  for select using (auth.uid() = id);
create policy users_update_own on public.users
  for update using (auth.uid() = id);

-- ITEMS: user owns
create policy items_all_own on public.items
  for all using (auth.uid() = user_id);

-- PHOTOS: via item ownership
create policy photos_all_own on public.photos
  for all using (
    exists (select 1 from public.items where items.id = photos.item_id and items.user_id = auth.uid())
  );

-- LISTINGS: via item ownership
create policy listings_all_own on public.listings
  for all using (
    exists (select 1 from public.items where items.id = listings.item_id and items.user_id = auth.uid())
  );

-- SALES: via item ownership
create policy sales_all_own on public.sales
  for all using (
    exists (select 1 from public.items where items.id = sales.item_id and items.user_id = auth.uid())
  );

-- PRICE_SCANS: anonymous insert, public read by slug
create policy price_scans_anyone_insert on public.price_scans
  for insert with check (true);
create policy price_scans_public_read on public.price_scans
  for select using (true);  -- intentionally public, slug acts as access token
EOF

write "supabase/migrations/20260513000003_storage.sql" <<'EOF'
-- Storage buckets

insert into storage.buckets (id, name, public) values ('item-photos', 'item-photos', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public) values ('scan-photos', 'scan-photos', true)
on conflict (id) do nothing;

-- Item photos: users access their own only
create policy "item_photos_select_own"
  on storage.objects for select
  using (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "item_photos_insert_own"
  on storage.objects for insert
  with check (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "item_photos_delete_own"
  on storage.objects for delete
  using (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Scan photos: anonymous upload (rate limited at function level)
create policy "scan_photos_anon_insert"
  on storage.objects for insert
  with check (bucket_id = 'scan-photos');

create policy "scan_photos_public_read"
  on storage.objects for select
  using (bucket_id = 'scan-photos');
EOF

# =============================================================================
# Stub edge function files (so the structure is clear)
# =============================================================================
write "supabase/functions/identify-item/index.ts" <<'EOF'
// identify-item — photo(s) → Haiku vision → universal item data
// Requires user JWT. Called by iOS Capture flow.
//
// See ../../docs/ai-prompts.md (Prompt 1) for the prompt this uses.
// Bump version in lockstep with the prompt.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 2, Day 3-4
  // 1. Validate JWT
  // 2. Read photo URLs from request body
  // 3. Call Anthropic API with Prompt 1
  // 4. Return JSON matching shared/types/item.schema.json
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    { status: 501, headers: { "Content-Type": "application/json" } },
  );
});
EOF

write "supabase/functions/price-scan/index.ts" <<'EOF'
// price-scan — public endpoint for the free web scanner
// No auth, rate-limited by IP.
//
// Called by web/app/api/scan/route.ts.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 1, Day 3-4
  // 1. Check rate limit (3/IP/day)
  // 2. Receive photo, upload to scan-photos bucket
  // 3. Call identify-item logic (Prompt 1)
  // 4. Call ebay-comps for sold comp data
  // 5. Call Prompt 3 for price guidance
  // 6. Insert into price_scans table
  // 7. Return result with shareable_slug
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    { status: 501, headers: { "Content-Type": "application/json" } },
  );
});
EOF

write "supabase/functions/ebay-comps/index.ts" <<'EOF'
// ebay-comps — internal endpoint for sold comp lookup
// Called by identify-item and price-scan. Caches results.
//
// See ../../docs/ebay-api-notes.md for API details.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 1, Day 3-4 (web tool first, then iOS uses it)
  // 1. Hash query, check cache
  // 2. OAuth client_credentials grant if needed (cache token 2hr)
  // 3. Call Marketplace Insights API with progressive broadening
  // 4. Cache result 24hr
  // 5. Return normalised comps array
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    { status: 501, headers: { "Content-Type": "application/json" } },
  );
});
EOF

write "supabase/functions/parse-sale-email/index.ts" <<'EOF'
// parse-sale-email — inbound email webhook for sale detection
// User forwards Vinted/Depop/eBay sale notifications to <token>@sales.presold.app
//
// Webhook from email forwarding provider (e.g. Postmark inbound, Cloudflare Email Workers)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // TODO: implement in Week 3, Day 4
  // 1. Validate webhook signature
  // 2. Extract token from to-address
  // 3. Look up user by sale_email_token
  // 4. Parse email: detect platform from sender, extract item/price
  // 5. Match to item in DB (by title fuzzy match, then by manual review queue)
  // 6. Insert into sales, mark item sold
  // 7. Failed parses → log to manual review table
  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
EOF

# =============================================================================
# Shared types — placeholder JSON schemas
# =============================================================================
write "shared/types/item.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://presold.app/schemas/item.json",
  "title": "Item",
  "description": "Universal item data output by identify-item (Prompt 1, see docs/ai-prompts.md)",
  "type": "object",
  "required": ["title", "description", "category", "color", "condition", "weight_grams_estimate", "confidence"],
  "properties": {
    "title": { "type": "string", "maxLength": 60 },
    "description": { "type": "string" },
    "brand": { "type": ["string", "null"] },
    "category": { "type": "string" },
    "size": { "type": ["string", "null"] },
    "color": { "type": "string" },
    "condition": {
      "type": "string",
      "enum": ["new_with_tags", "new_without_tags", "very_good", "good", "satisfactory"]
    },
    "weight_grams_estimate": { "type": "integer", "minimum": 0 },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 }
  }
}
EOF

write "shared/types/listing.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://presold.app/schemas/listing.json",
  "title": "Listing",
  "description": "Platform-specific listing output by platform reformatting (Prompt 2)",
  "type": "object",
  "required": ["title", "description", "tags"],
  "properties": {
    "title": { "type": "string" },
    "description": { "type": "string" },
    "tags": {
      "type": "array",
      "items": { "type": "string" },
      "maxItems": 5
    }
  }
}
EOF

write "shared/types/price-guidance.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://presold.app/schemas/price-guidance.json",
  "title": "PriceGuidance",
  "description": "Price guidance output by Prompt 3",
  "type": "object",
  "required": ["price_low", "price_recommended", "price_high", "sell_speed_estimate", "reasoning", "comp_count", "confidence"],
  "properties": {
    "price_low": { "type": "number", "minimum": 0 },
    "price_recommended": { "type": "number", "minimum": 0 },
    "price_high": { "type": "number", "minimum": 0 },
    "sell_speed_estimate": {
      "type": "string",
      "enum": ["fast", "medium", "slow", "uncertain"]
    },
    "reasoning": { "type": "string" },
    "comp_count": { "type": "integer", "minimum": 0 },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 }
  }
}
EOF

write "shared/types/platform.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://presold.app/schemas/platform.json",
  "title": "Platform",
  "description": "Supported reselling platforms",
  "type": "string",
  "enum": ["vinted", "depop", "ebay"]
}
EOF

# =============================================================================
# Web scaffold — minimal package.json so structure is real
# =============================================================================
write "web/package.json" <<'EOF'
{
  "name": "presold-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@supabase/supabase-js": "^2.45.0",
    "@anthropic-ai/sdk": "^0.30.0"
  },
  "devDependencies": {
    "@types/node": "^22",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "typescript": "^5",
    "tailwindcss": "^4",
    "postcss": "^8",
    "autoprefixer": "^10",
    "eslint": "^9",
    "eslint-config-next": "^15"
  }
}
EOF

write "web/.env.local.example" <<'EOF'
# Public (exposed to browser)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=https://eu.posthog.com

# Server only (NEVER expose)
SUPABASE_SERVICE_ROLE_KEY=
ANTHROPIC_API_KEY=
EBAY_APP_ID=
EBAY_CERT_ID=
EBAY_ENV=PRODUCTION
EOF

# =============================================================================
# iOS scaffold — placeholder config example
# =============================================================================
write "ios/PreSold/Config/Secrets.xcconfig.example" <<'EOF'
// Copy this file to Secrets.xcconfig and fill in values.
// Secrets.xcconfig is gitignored. Never commit it.

SUPABASE_URL = https:/$()/your-project.supabase.co
SUPABASE_ANON_KEY = your_anon_key_here
POSTHOG_API_KEY = your_posthog_key_here
SENTRY_DSN = your_sentry_dsn_here
EOF

# =============================================================================
# Git init
# =============================================================================
head1 "Initialising git repository"

if [ ! -d ".git" ]; then
  git init -b main >/dev/null 2>&1 || git init >/dev/null 2>&1
  ok "git initialised"
else
  log "git already initialised"
fi

# =============================================================================
# Summary
# =============================================================================
head1 "Done"

cat <<SUMMARY

${GREEN}Project ready at:${RESET} ${ROOT}

${BOLD}Files created:${RESET}
  Root context:        CLAUDE.md, PLAN.md, README.md, .gitignore, .env.example
  Claude Code config:  .claude/settings.json + 4 custom commands
  Documentation:       docs/architecture.md, data-model.md, ai-prompts.md, ebay-api-notes.md
  Decision records:    docs/decisions/001-003 (already-made decisions)
  Subdirectory context: ios/CLAUDE.md, web/CLAUDE.md, supabase/CLAUDE.md, shared/CLAUDE.md
  Database:            3 SQL migrations (schema + RLS + storage)
  Edge function stubs: 4 functions with TODO markers tied to plan weeks
  Shared types:        4 JSON schemas
  Web/iOS scaffold:    package.json, .env templates, xcconfig template

${BOLD}Next steps:${RESET}
  ${YELLOW}1.${RESET} cd ${PROJECT_NAME}
  ${YELLOW}2.${RESET} git add -A && git commit -m "[Week 0] initial scaffold from bootstrap.sh"
  ${YELLOW}3.${RESET} Run: ${BOLD}claude${RESET}
  ${YELLOW}4.${RESET} First message: ${DIM}"Read CLAUDE.md and PLAN.md, then propose what to build first."${RESET}

${BOLD}Then in parallel (Week 0 setup):${RESET}
  - Buy your domain
  - Apply for Apple Developer account (£79/year, 2-3 days to provision)
  - Apply for eBay Developer Marketplace Insights API access (5-10 business days)
  - Create Supabase project, paste credentials into ${DIM}.env.local${RESET}
  - Get Anthropic API key with billing set up
  - Create Vercel, PostHog, Sentry accounts

${DIM}This scaffold is your source of truth. Edit PLAN.md as decisions change.
The structure is deliberately complete — every CLAUDE.md, every doc, every
edge function stub is referenced by the build timeline. Don't delete things
you haven't yet got to; the references in PLAN.md point at them.${RESET}

SUMMARY
