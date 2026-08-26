-- ============================================================
-- KAWACH – Core Tables & Row-Level Security
-- ============================================================
-- Every table enforces auth.uid() RLS policies as required by
-- the KAWACH security policy.
-- ============================================================

-- Enable pgcrypto for gen_random_uuid()
create extension if not exists pgcrypto;

-- ── users ───────────────────────────────────────────────────────
create table if not exists users (
  id           uuid primary key default gen_random_uuid(),
  phone        text unique,
  name         text,
  email        text,
  avatar_url   text,
  live_lat     double precision,
  live_lng     double precision,
  live_location_updated_at timestamptz,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

alter table users enable row level security;

create policy "Users can read own profile"
  on users for select using (auth.uid() = id);

create policy "Users can update own profile"
  on users for update using (auth.uid() = id);

-- ── guardians ───────────────────────────────────────────────────
create table if not exists guardians (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references users(id) not null,
  guardian_id  uuid references users(id) not null,
  status       text default 'pending' check (status in ('pending','confirmed','removed')),
  confirmed_at timestamptz,
  removed_at   timestamptz,
  created_at   timestamptz default now()
);

alter table guardians enable row level security;

create policy "Users can view own guardian links"
  on guardians for select
  using (auth.uid() = user_id or auth.uid() = guardian_id);

create policy "Users can insert guardian invitations"
  on guardians for insert
  with check (auth.uid() = user_id);

-- Updates and deletes are handled via the guardians-verify edge function.

-- ── sos_alerts ──────────────────────────────────────────────────
create table if not exists sos_alerts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references users(id) not null,
  lat          double precision,
  lng          double precision,
  trigger      text default 'manual',
  fraud_score  double precision default 0,
  status       text default 'active' check (status in ('active','resolved','flagged')),
  created_at   timestamptz default now(),
  resolved_at  timestamptz
);

alter table sos_alerts enable row level security;

create policy "Users can read own SOS alerts"
  on sos_alerts for select using (auth.uid() = user_id);

create policy "Guardians can read ward SOS alerts"
  on sos_alerts for select using (
    exists (
      select 1 from guardians
      where guardians.user_id = sos_alerts.user_id
        and guardians.guardian_id = auth.uid()
        and guardians.status = 'confirmed'
    )
  );

-- Inserts go through the SOS edge function (rate-limited).

-- ── evidence_items ──────────────────────────────────────────────
-- NO direct SELECT policy: access is exclusively through the
-- sign-evidence-url edge function, which returns signed 15-min URLs.
create table if not exists evidence_items (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users(id) not null,
  sos_alert_id  uuid references sos_alerts(id),
  storage_path  text not null,
  media_type    text check (media_type in ('audio','video','image')),
  encrypted     boolean default true,
  created_at    timestamptz default now()
);

alter table evidence_items enable row level security;

create policy "Users can insert own evidence"
  on evidence_items for insert
  with check (auth.uid() = user_id);

-- SELECT is intentionally omitted; access via sign-evidence-url function.

-- ── community_reports ───────────────────────────────────────────
create table if not exists community_reports (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references users(id) not null,
  category     text,
  description  text,
  lat          double precision,
  lng          double precision,
  geohash      text,
  status       text default 'pending',
  created_at   timestamptz default now()
);

alter table community_reports enable row level security;

create policy "Users can read own reports"
  on community_reports for select using (auth.uid() = user_id);

create policy "Users can insert reports"
  on community_reports for insert with check (auth.uid() = user_id);

-- ── crowd_alerts ────────────────────────────────────────────────
-- CrowdShield peer alerts expose only geohash-5 (~5 km²) for anonymity.
create table if not exists crowd_alerts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references users(id) not null,
  geohash5     text not null,  -- only ~5 km² precision
  alert_type   text,
  message      text,
  created_at   timestamptz default now(),
  expires_at   timestamptz
);

alter table crowd_alerts enable row level security;

create policy "Anyone authenticated can read crowd alerts"
  on crowd_alerts for select using (auth.uid() is not null);

create policy "Users can insert own crowd alerts"
  on crowd_alerts for insert with check (auth.uid() = user_id);

-- ── mesh_messages ───────────────────────────────────────────────
create table if not exists mesh_messages (
  id                uuid primary key default gen_random_uuid(),
  sender_id         uuid references users(id),
  recipient_id      uuid references users(id),
  encrypted_payload bytea not null,
  sender_public_key bytea,
  signature         bytea,
  hop_count         int default 0,
  created_at        timestamptz default now()
);

alter table mesh_messages enable row level security;

create policy "Users can read own mesh messages"
  on mesh_messages for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

create policy "Authenticated users can relay mesh messages"
  on mesh_messages for insert
  with check (auth.uid() is not null);

-- ── activity_logs ───────────────────────────────────────────────
create table if not exists activity_logs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users(id) not null,
  action        text not null,
  resource_id   text,
  resource_type text,
  metadata      jsonb,
  created_at    timestamptz default now()
);

alter table activity_logs enable row level security;

create policy "Users can read own activity logs"
  on activity_logs for select using (auth.uid() = user_id);

-- Inserts are performed by edge functions with service-role key.

-- ── danger_zones ────────────────────────────────────────────────
create table if not exists danger_zones (
  id           uuid primary key default gen_random_uuid(),
  lat          double precision not null,
  lng          double precision not null,
  radius_m     double precision default 300,
  severity     text default 'medium',
  description  text,
  reported_by  uuid references users(id),
  created_at   timestamptz default now()
);

alter table danger_zones enable row level security;

create policy "Authenticated users can read danger zones"
  on danger_zones for select using (auth.uid() is not null);

create policy "Users can report danger zones"
  on danger_zones for insert with check (auth.uid() is not null);
