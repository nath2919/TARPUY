-- Initial Supabase schema. Apply manually in a NEW Supabase project.
-- No database is connected by the application in this MVP.
create extension if not exists postgis with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

create table public.plots (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  area_ha numeric not null check (area_ha > 0),
  priority text,
  water_availability text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, owner_id)
);

create table public.locations (
  plot_id uuid primary key,
  owner_id uuid not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  department text, province text, district text,
  altitude_m numeric,
  boundary extensions.geometry(Polygon, 4326),
  source text not null default 'farmer',
  recorded_at timestamptz not null default now(),
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade
);

create table public.soil_tests (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null, owner_id uuid not null,
  sampled_at date not null,
  ph numeric check (ph between 0 and 14),
  organic_matter_percent numeric check (organic_matter_percent between 0 and 100),
  nitrogen_mg_kg numeric check (nitrogen_mg_kg >= 0),
  phosphorus_mg_kg numeric check (phosphorus_mg_kg >= 0),
  potassium_mg_kg numeric check (potassium_mg_kg >= 0),
  texture text,
  laboratory text,
  source text not null,
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade
);

create table public.crops (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  family text not null,
  agronomy jsonb not null default '{}',
  source_url text,
  validation_status text not null default 'pending_regional_validation'
);

create table public.planting_history (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null, owner_id uuid not null,
  crop_id uuid not null references public.crops(id),
  sown_at date not null, harvested_at date,
  yield_kg numeric check (yield_kg >= 0),
  notes text,
  check (harvested_at is null or harvested_at >= sown_at),
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade
);

create table public.rotations (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null, owner_id uuid not null,
  name text not null,
  horizon_years integer not null check (horizon_years in (3, 5, 10)),
  sequence jsonb not null,
  assumptions jsonb not null,
  created_at timestamptz not null default now(),
  unique (id, owner_id),
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade
);

create table public.simulations (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null, owner_id uuid not null,
  rotation_id uuid,
  model_version text not null,
  assumptions jsonb not null,
  results jsonb not null,
  data_type text not null default 'simulated' check (data_type = 'simulated'),
  created_at timestamptz not null default now(),
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade,
  foreign key (rotation_id, owner_id) references public.rotations(id, owner_id)
);

create table public.recommendations (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null, owner_id uuid not null,
  content text not null, rationale text not null,
  limitations text not null,
  evidence jsonb not null,
  engine_version text not null,
  created_at timestamptz not null default now(),
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade
);

create table public.environmental_observations (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null, owner_id uuid not null,
  category text not null check (category in ('meteorological', 'satellite', 'field')),
  dataset_id text not null, provider text not null,
  variable text not null, value double precision,
  unit text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  spatial_resolution text not null, temporal_resolution text not null,
  observation_date timestamptz not null,
  fetched_at timestamptz not null default now(),
  data_type text not null check (data_type in ('observed', 'estimated', 'simulated')),
  quality_flag text not null,
  source_url text not null,
  foreign key (plot_id, owner_id) references public.plots(id, owner_id) on delete cascade,
  unique (plot_id, dataset_id, variable, observation_date, latitude, longitude)
);

create view public.meteorological_records with (security_invoker = true) as
select * from public.environmental_observations where category = 'meteorological';
create view public.satellite_records with (security_invoker = true) as
select * from public.environmental_observations where category = 'satellite';

create table public.market_prices (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  crop_id uuid not null references public.crops(id),
  market_name text not null,
  market_scope text not null check (market_scope in ('local', 'national', 'international')),
  price numeric not null check (price >= 0), currency text not null,
  unit text not null, observed_date date not null,
  fetched_at timestamptz not null default now(),
  source text not null, source_url text,
  data_type text not null check (data_type in ('user_provided', 'observed', 'demo')),
  unique (owner_id, crop_id, market_name, observed_date, source, currency, unit)
);

create index observations_plot_time on public.environmental_observations(plot_id, observation_date desc);
create index locations_boundary on public.locations using gist(boundary);
create index plots_owner on public.plots(owner_id);

-- Ownership is enforced for all records, including cross-table references.
alter table public.profiles enable row level security;
create policy own_profile on public.profiles for all to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
alter table public.crops enable row level security;
create policy read_crop_catalog on public.crops for select to authenticated using (true);
-- Crop catalog writes are restricted to trusted server/admin roles.
do $$
declare target text;
begin
  foreach target in array array['plots','locations','soil_tests','planting_history','rotations','simulations','recommendations','environmental_observations','market_prices'] loop
    execute format('alter table public.%I enable row level security', target);
    execute format('create policy own_records on public.%I for all to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()))', target);
  end loop;
end $$;
