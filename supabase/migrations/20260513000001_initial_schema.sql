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
-- Note: data-model.md describes a composite (user_id, sold_at) index for the profit view,
-- but `user_id` is not on `sales` — it's derived via items. Postgres rejects subqueries in
-- index expressions, so we index on (item_id, sold_at) for now. The profit view query
-- joins items and filters by item.user_id; planner uses items_user_status_idx + this one.
create index sales_item_sold_idx on public.sales (item_id, sold_at desc);

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
