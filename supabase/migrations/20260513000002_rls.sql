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
