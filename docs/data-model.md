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

### `waitlist`

Email captures from the marketing landing page. Public insert, no public read (service role only).

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `email` | text | unique |
| `source` | text nullable | e.g. `landing`, `tiktok`, free-form tag |
| `user_agent` | text nullable | best-effort, for debug only |
| `ip_address` | text nullable | rate limiting / debug |
| `created_at` | timestamptz | |

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
- `waitlist`: anyone can insert; no public read (service role only)
- `users`: user can read own row; service role only can update subscription fields

## Indexes worth having from day one

- `items(user_id, status, updated_at desc)` — inventory list query
- `listings(item_id)` — load all platform drafts for an item
- `sales(user_id, sold_at desc)` — profit view query
- `price_scans(shareable_slug)` — unique constraint covers this
