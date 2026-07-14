-- ============================================================
-- REV NATION JAIPUR — Supabase Schema (Phase 2)
-- Run this once in Supabase → SQL Editor → New query → Run.
-- Safe to re-run: uses IF NOT EXISTS / ON CONFLICT where possible.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- TABLES
-- ------------------------------------------------------------

create table if not exists services (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,                 -- 'modification' | 'protection' | 'detailing'
  description text,
  icon text,
  sort_order int default 0,
  created_at timestamptz default now()
);

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  car_make text,
  car_model text,
  service_type text,             -- shown as the tag on the build card
  cover_image text,              -- public URL from project-images bucket
  before_url text,
  after_url text,
  published boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

create table if not exists frame_sequences (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  folder_path text not null,     -- e.g. frame-sequences/<project_id>/hero/
  frame_count int not null,
  section_key text,              -- 'hero' | 'ppf' | 'mods'
  created_at timestamptz default now()
);

create table if not exists testimonials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text,
  car text,
  quote text not null,
  rating int default 5,
  published boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

create table if not exists stats (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  value int not null,
  suffix text default '',
  sort_order int default 0
);

create table if not exists leads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  city text,
  car text,
  service text,
  message text,
  status text default 'new',     -- new | contacted | closed
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- Public visitors: read published content, insert leads only.
-- Signed-in admin (any authenticated user): full read/write.
-- ------------------------------------------------------------

alter table services enable row level security;
alter table projects enable row level security;
alter table frame_sequences enable row level security;
alter table testimonials enable row level security;
alter table stats enable row level security;
alter table leads enable row level security;

drop policy if exists "public read services" on services;
create policy "public read services" on services for select using (true);

drop policy if exists "public read published projects" on projects;
create policy "public read published projects" on projects for select using (published = true);

drop policy if exists "public read frame_sequences" on frame_sequences;
create policy "public read frame_sequences" on frame_sequences for select using (true);

drop policy if exists "public read published testimonials" on testimonials;
create policy "public read published testimonials" on testimonials for select using (published = true);

drop policy if exists "public read stats" on stats;
create policy "public read stats" on stats for select using (true);

drop policy if exists "public insert leads" on leads;
create policy "public insert leads" on leads for insert with check (true);

drop policy if exists "admin full access services" on services;
create policy "admin full access services" on services for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin full access projects" on projects;
create policy "admin full access projects" on projects for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin full access frame_sequences" on frame_sequences;
create policy "admin full access frame_sequences" on frame_sequences for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin full access testimonials" on testimonials;
create policy "admin full access testimonials" on testimonials for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin full access stats" on stats;
create policy "admin full access stats" on stats for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin full access leads" on leads;
create policy "admin full access leads" on leads for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- STORAGE BUCKETS
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('project-images', 'project-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('frame-sequences', 'frame-sequences', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('site-assets', 'site-assets', true)
on conflict (id) do nothing;

drop policy if exists "public read project-images" on storage.objects;
create policy "public read project-images" on storage.objects for select using (bucket_id = 'project-images');

drop policy if exists "public read frame-sequences" on storage.objects;
create policy "public read frame-sequences" on storage.objects for select using (bucket_id = 'frame-sequences');

drop policy if exists "public read site-assets" on storage.objects;
create policy "public read site-assets" on storage.objects for select using (bucket_id = 'site-assets');

drop policy if exists "admin write project-images" on storage.objects;
create policy "admin write project-images" on storage.objects for insert with check (bucket_id = 'project-images' and auth.role() = 'authenticated');
drop policy if exists "admin update project-images" on storage.objects;
create policy "admin update project-images" on storage.objects for update using (bucket_id = 'project-images' and auth.role() = 'authenticated');
drop policy if exists "admin delete project-images" on storage.objects;
create policy "admin delete project-images" on storage.objects for delete using (bucket_id = 'project-images' and auth.role() = 'authenticated');

drop policy if exists "admin write frame-sequences" on storage.objects;
create policy "admin write frame-sequences" on storage.objects for insert with check (bucket_id = 'frame-sequences' and auth.role() = 'authenticated');
drop policy if exists "admin update frame-sequences" on storage.objects;
create policy "admin update frame-sequences" on storage.objects for update using (bucket_id = 'frame-sequences' and auth.role() = 'authenticated');
drop policy if exists "admin delete frame-sequences" on storage.objects;
create policy "admin delete frame-sequences" on storage.objects for delete using (bucket_id = 'frame-sequences' and auth.role() = 'authenticated');

drop policy if exists "admin write site-assets" on storage.objects;
create policy "admin write site-assets" on storage.objects for insert with check (bucket_id = 'site-assets' and auth.role() = 'authenticated');
drop policy if exists "admin update site-assets" on storage.objects;
create policy "admin update site-assets" on storage.objects for update using (bucket_id = 'site-assets' and auth.role() = 'authenticated');
drop policy if exists "admin delete site-assets" on storage.objects;
create policy "admin delete site-assets" on storage.objects for delete using (bucket_id = 'site-assets' and auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- SEED DATA — matches what's currently hardcoded on the live site,
-- so switching to Supabase doesn't change anything visually at first.
-- Edit these later from the admin panel.
-- ------------------------------------------------------------

insert into stats (label, value, suffix, sort_order) values
  ('Vehicles Serviced', 4200, '+', 1),
  ('Studio Area', 28, 'k sq.ft', 2),
  ('Installation Bays', 12, '', 3),
  ('Certified Installers', 24, '', 4),
  ('Cities Served', 9, '', 5),
  ('Experience', 11, 'yrs', 6);

insert into testimonials (name, city, car, quote, sort_order) values
  ('Aditya R.', 'Jaipur', 'Mahindra Thar', 'The wrap and wheel swap turned heads I didn''t expect. Cleanest install I''ve seen in Jaipur.', 1),
  ('Meher K.', 'Udaipur', 'Audi Q8', 'Booked an inspection expecting a week-long wait. Was in the bay in three days, and the edge work is cleaner than the factory finish.', 2),
  ('Karan V.', 'Jodhpur', 'Mercedes GLE', 'Two years in Rajasthan heat and dust, and the coating still beads water like day one. Worth every rupee.', 3);
