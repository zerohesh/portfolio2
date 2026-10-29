-- ZeRo Graphics Supabase schema
-- Run in Supabase SQL Editor. Never put the service-role key in the frontend.
create extension if not exists pgcrypto;
create table if not exists public.portfolio_projects (
 id uuid primary key default gen_random_uuid(), title text not null, category text not null check(category in ('Logos','Posters','Social Media Designs','T-Shirt Designs')),
 description text not null default '', image_url text not null, external_url text, published boolean not null default true, sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.services (
 id text primary key, name text not null, description text not null default '', price text, icon text not null default 'palette', visible boolean not null default true, sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.pricing_packages (
 id uuid primary key default gen_random_uuid(), name text not null, service text not null default 'Design', price numeric(12,2), features jsonb not null default '[]'::jsonb, revisions text not null default 'Agreed in advance', delivery_time text not null default 'Discussed per project', featured boolean not null default false, published boolean not null default true, sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.site_settings (key text primary key, value text not null, updated_at timestamptz not null default now());
create table if not exists public.theme_settings (key text primary key, value text not null, updated_at timestamptz not null default now());
create table if not exists public.social_links (platform text primary key, url text not null default '', visible boolean not null default true, sort_order integer not null default 0, updated_at timestamptz not null default now());

-- RLS: public can only read published content; authenticated admins may edit.
-- Restrict admin membership to explicitly allowlisted Auth user IDs in app_metadata.
create or replace function public.is_site_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select coalesce((auth.jwt() -> 'app_metadata' ->> 'site_admin') = 'true', false);
$$;
alter table public.portfolio_projects enable row level security;
alter table public.services enable row level security;
alter table public.pricing_packages enable row level security;
alter table public.site_settings enable row level security;
alter table public.theme_settings enable row level security;
alter table public.social_links enable row level security;

drop policy if exists "public read published projects" on public.portfolio_projects;
create policy "public read published projects" on public.portfolio_projects for select to anon, authenticated using (published = true or public.is_site_admin());
drop policy if exists "admin manage projects" on public.portfolio_projects;
create policy "admin manage projects" on public.portfolio_projects for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "public read visible services" on public.services;
create policy "public read visible services" on public.services for select to anon, authenticated using (visible = true or public.is_site_admin());
drop policy if exists "admin manage services" on public.services;
create policy "admin manage services" on public.services for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "public read published packages" on public.pricing_packages;
create policy "public read published packages" on public.pricing_packages for select to anon, authenticated using (published = true or public.is_site_admin());
drop policy if exists "admin manage packages" on public.pricing_packages;
create policy "admin manage packages" on public.pricing_packages for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "public read site settings" on public.site_settings;
create policy "public read site settings" on public.site_settings for select to anon, authenticated using (true);
drop policy if exists "admin manage site settings" on public.site_settings;
create policy "admin manage site settings" on public.site_settings for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "public read theme settings" on public.theme_settings;
create policy "public read theme settings" on public.theme_settings for select to anon, authenticated using (true);
drop policy if exists "admin manage theme settings" on public.theme_settings;
create policy "admin manage theme settings" on public.theme_settings for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "public read social links" on public.social_links;
create policy "public read social links" on public.social_links for select to anon, authenticated using (visible = true or public.is_site_admin());
drop policy if exists "admin manage social links" on public.social_links;
create policy "admin manage social links" on public.social_links for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

-- Public portfolio image bucket. Admin write access is checked by RLS policy.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('portfolio','portfolio',true,8388608,array['image/jpeg','image/png','image/webp','image/avif']) on conflict (id) do nothing;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('site-assets','site-assets',true,4194304,array['image/jpeg','image/png','image/webp','image/svg+xml','image/x-icon']) on conflict (id) do nothing;
drop policy if exists "public view portfolio files" on storage.objects;
create policy "public view portfolio files" on storage.objects for select to anon, authenticated using (bucket_id in ('portfolio','site-assets'));
drop policy if exists "admins upload portfolio files" on storage.objects;
create policy "admins upload portfolio files" on storage.objects for insert to authenticated with check (bucket_id in ('portfolio','site-assets') and public.is_site_admin());
drop policy if exists "admins update portfolio files" on storage.objects;
create policy "admins update portfolio files" on storage.objects for update to authenticated using (bucket_id in ('portfolio','site-assets') and public.is_site_admin()) with check (bucket_id in ('portfolio','site-assets') and public.is_site_admin());
drop policy if exists "admins delete portfolio files" on storage.objects;
create policy "admins delete portfolio files" on storage.objects for delete to authenticated using (bucket_id in ('portfolio','site-assets') and public.is_site_admin());

-- Seed service records (prices intentionally unconfirmed).
insert into public.services (id,name,description,price,icon,visible,sort_order) values
 ('logo','Logo Design','Distinctive brand marks built to be remembered.','Set your price','pen',true,1),
 ('poster','Poster Design','Scroll-stopping posters with a clear visual story.','Set your price','palette',true,2),
 ('social','Social Media Design','Consistent content that gives your brand a sharper feed.','Set your price','layers',true,3),
 ('shirt','T-Shirt Design','Wearable artwork with personality and impact.','Set your price','shirt',true,4)
on conflict (id) do nothing;
insert into public.site_settings(key,value) values ('brand','ZeRo Graphics'),('tagline','Design • Motion • Visuals'),('name','Sachintha Heshan'),('intro','Creative graphic designer creating bold, meaningful visuals for brands, businesses, and people with something to say.'),('about','Hi, I’m Sachintha Heshan, a creative graphic designer passionate about creating bold, meaningful, and visually engaging designs. I help brands and individuals communicate their ideas through powerful visuals and creative design.'),('whatsapp','+94 75 269 9830'),('email','hello@zerographics.lk'),('footer','Independent designer. Big ideas, carefully made.'),('seoTitle','ZeRo Graphics — Design • Motion • Visuals'),('seoDescription','Creative graphic design, posters, logos, social media visuals and motion design by Sachintha Heshan.') on conflict(key) do nothing;
insert into public.theme_settings(key,value) values ('background','#080808'),('surface','#141414'),('accent','#C7FF3D'),('text','#FFFFFF'),('muted','#A0A0A0'),('border','#2A2A2A'),('buttonText','#080808') on conflict(key) do nothing;
