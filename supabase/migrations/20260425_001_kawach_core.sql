create extension if not exists pgcrypto;

create table if not exists public.users (
  user_id uuid primary key,
  name text not null default '',
  phone text not null default '',
  email text,
  guardians text[] not null default '{}',
  guardian_ids text[] not null default '{}',
  emergency_profile jsonb,
  live_lat double precision,
  live_lng double precision,
  live_location_updated_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.guardians (
  guardian_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(user_id) on delete cascade,
  name text not null,
  phone text not null,
  relationship text not null,
  fcm_token text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sos_alerts (
  emergency_id uuid primary key,
  user_id uuid not null references public.users(user_id) on delete cascade,
  status text not null,
  triggered_by text not null,
  lat double precision,
  lng double precision,
  audio_url text,
  video_url text,
  livestream_url text,
  last_location_payload text,
  location_updated_at timestamptz,
  stream_started_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.locations (
  id bigint generated always as identity primary key,
  emergency_id uuid not null references public.sos_alerts(emergency_id) on delete cascade,
  user_id uuid not null references public.users(user_id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  speed double precision,
  heading double precision,
  accuracy double precision,
  source text not null default 'device',
  encrypted_payload text,
  recorded_at timestamptz not null
);

create index if not exists idx_locations_emergency_recorded_at
  on public.locations (emergency_id, recorded_at desc);

create table if not exists public.evidence (
  evidence_id uuid primary key,
  user_id uuid not null references public.users(user_id) on delete cascade,
  emergency_id uuid not null references public.sos_alerts(emergency_id) on delete cascade,
  audio_url text,
  video_url text,
  lat double precision,
  lng double precision,
  timestamp timestamptz not null
);

create table if not exists public.guardian_network (
  volunteer_id uuid primary key,
  user_id uuid not null references public.users(user_id) on delete cascade,
  name text not null,
  lat double precision,
  lng double precision,
  verified boolean not null default false,
  availability boolean not null default true,
  phone text,
  last_seen timestamptz
);

create table if not exists public.volunteer_alerts (
  alert_id uuid primary key default gen_random_uuid(),
  volunteer_id uuid not null references public.guardian_network(volunteer_id) on delete cascade,
  emergency_id uuid not null references public.sos_alerts(emergency_id) on delete cascade,
  user_id uuid not null references public.users(user_id) on delete cascade,
  user_name text,
  lat double precision,
  lng double precision,
  status text not null default 'pending',
  sent_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_volunteer_alerts_volunteer_sent_at
  on public.volunteer_alerts (volunteer_id, sent_at desc);

create table if not exists public.mesh_packets (
  packet_id uuid primary key,
  emergency_id uuid not null references public.sos_alerts(emergency_id) on delete cascade,
  user_id uuid not null references public.users(user_id) on delete cascade,
  payload text not null,
  lat double precision,
  lng double precision,
  hops integer not null default 0,
  relay_source text not null default 'supabase',
  acknowledged boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null
);

create table if not exists public.mesh_acknowledgements (
  id bigint generated always as identity primary key,
  packet_id uuid not null references public.mesh_packets(packet_id) on delete cascade,
  volunteer_id uuid not null references public.guardian_network(volunteer_id) on delete cascade,
  acknowledged_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.activity_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.users(user_id) on delete cascade,
  event text not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.users enable row level security;
alter table public.guardians enable row level security;
alter table public.sos_alerts enable row level security;
alter table public.locations enable row level security;
alter table public.evidence enable row level security;
alter table public.guardian_network enable row level security;
alter table public.volunteer_alerts enable row level security;
alter table public.mesh_packets enable row level security;
alter table public.mesh_acknowledgements enable row level security;
alter table public.activity_logs enable row level security;

drop policy if exists "users own profile" on public.users;
create policy "users own profile"
  on public.users
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users own guardians" on public.guardians;
create policy "users own guardians"
  on public.guardians
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users own sos alerts" on public.sos_alerts;
create policy "users own sos alerts"
  on public.sos_alerts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users own locations" on public.locations;
create policy "users own locations"
  on public.locations
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users own evidence" on public.evidence;
create policy "users own evidence"
  on public.evidence
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "volunteers manage presence" on public.guardian_network;
create policy "volunteers manage presence"
  on public.guardian_network
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "volunteers receive alerts" on public.volunteer_alerts;
create policy "volunteers receive alerts"
  on public.volunteer_alerts
  for select
  using (
    exists (
      select 1
      from public.guardian_network g
      where g.volunteer_id = volunteer_id
        and g.user_id = auth.uid()
    )
  );

drop policy if exists "users insert volunteer alerts" on public.volunteer_alerts;
create policy "users insert volunteer alerts"
  on public.volunteer_alerts
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "mesh packets visible to responders" on public.mesh_packets;
create policy "mesh packets visible to responders"
  on public.mesh_packets
  for select
  using (true);

drop policy if exists "users write mesh packets" on public.mesh_packets;
create policy "users write mesh packets"
  on public.mesh_packets
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "responders ack mesh packets" on public.mesh_acknowledgements;
create policy "responders ack mesh packets"
  on public.mesh_acknowledgements
  for insert
  with check (
    exists (
      select 1
      from public.guardian_network g
      where g.volunteer_id = volunteer_id
        and g.user_id = auth.uid()
    )
  );

drop policy if exists "users own activity logs" on public.activity_logs;
create policy "users own activity logs"
  on public.activity_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
