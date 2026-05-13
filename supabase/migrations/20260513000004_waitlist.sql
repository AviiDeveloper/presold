-- Waitlist for the marketing landing page
-- Captures email + optional source/referrer until the iOS app opens for signups.
-- Public insert, no public read. See docs/data-model.md.

create table public.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  source text,
  user_agent text,
  ip_address text,
  created_at timestamptz default now() not null,
  unique (email)
);

create index waitlist_created_idx on public.waitlist (created_at desc);

alter table public.waitlist enable row level security;

-- Anyone can sign up; nobody can read via anon key (service role bypasses RLS).
create policy waitlist_anyone_insert on public.waitlist
  for insert with check (true);
