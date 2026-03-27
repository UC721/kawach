-- ============================================================
-- Migration: Create existing application tables
-- Tables: users, guardians, emergencies, evidence_vault,
--         guardian_network, volunteer_alerts, dangerzone,
--         reports, activity_logs
-- ============================================================

-- Enable required extensions
create extension if not exists "pgcrypto";

-- ── users ────────────────────────────────────────────────────
create table if not exists public.users (
  "userId"                  text primary key,
  name                      text not null,
  phone                     text not null,
  email                     text,
  guardians                 jsonb default '[]'::jsonb,
  "emergencyProfile"        jsonb,
  "createdAt"               timestamptz not null default now(),
  "liveLat"                 double precision,
  "liveLng"                 double precision,
  "liveLocationUpdatedAt"   timestamptz
);

-- ── guardians ────────────────────────────────────────────────
create table if not exists public.guardians (
  "guardianId"  text primary key default gen_random_uuid()::text,
  "userId"      text not null references public.users("userId") on delete cascade,
  name          text not null,
  phone         text not null,
  relationship  text not null,
  "fcmToken"    text
);

-- ── emergencies ──────────────────────────────────────────────
create table if not exists public.emergencies (
  "emergencyId"       text primary key,
  "userId"            text not null references public.users("userId") on delete cascade,
  status              text not null default 'active'
                        check (status in ('active', 'resolved', 'cancelled')),
  "triggeredBy"       text not null
                        check ("triggeredBy" in (
                          'manual','shake','voice','panic',
                          'snatch','safeWalkTimeout','countdown')),
  lat                 double precision,
  lng                 double precision,
  "audioUrl"          text,
  "videoUrl"          text,
  "livestreamUrl"     text,
  "createdAt"         timestamptz not null default now(),
  "resolvedAt"        timestamptz,
  "locationUpdatedAt" timestamptz
);

-- ── evidence_vault ───────────────────────────────────────────
create table if not exists public.evidence_vault (
  "evidenceId"   text primary key default gen_random_uuid()::text,
  "userId"       text not null references public.users("userId") on delete cascade,
  "emergencyId"  text not null references public.emergencies("emergencyId") on delete cascade,
  "audioUrl"     text,
  "videoUrl"     text,
  lat            double precision,
  lng            double precision,
  timestamp      timestamptz not null default now()
);

-- ── guardian_network (volunteers) ────────────────────────────
create table if not exists public.guardian_network (
  "volunteerId"  text primary key,
  "userId"       text not null references public.users("userId") on delete cascade,
  name           text not null,
  lat            double precision,
  lng            double precision,
  verified       boolean not null default false,
  availability   boolean not null default true,
  phone          text,
  "lastSeen"     timestamptz
);

-- ── volunteer_alerts ─────────────────────────────────────────
create table if not exists public.volunteer_alerts (
  id             bigint generated always as identity primary key,
  "volunteerId"  text not null references public.guardian_network("volunteerId") on delete cascade,
  "emergencyId"  text not null references public.emergencies("emergencyId") on delete cascade,
  "userId"       text not null references public.users("userId") on delete cascade,
  lat            double precision,
  lng            double precision,
  "sentAt"       timestamptz not null default now(),
  status         text not null default 'pending'
                   check (status in ('pending', 'acknowledged'))
);

-- ── dangerzone ───────────────────────────────────────────────
create table if not exists public.dangerzone (
  id            text primary key,
  latitude      double precision not null,
  longitude     double precision not null,
  severity      text not null default 'low'
                  check (severity in ('low', 'medium', 'high', 'critical')),
  report_count  integer default 0,
  created_at    timestamptz not null default now(),
  description   text
);

-- ── reports ──────────────────────────────────────────────────
create table if not exists public.reports (
  id          bigint generated always as identity primary key,
  user_id     text not null references public.users("userId") on delete cascade,
  description text not null,
  image_url   text,
  latitude    double precision,
  longitude   double precision,
  location    text,
  address     text,
  created_at  timestamptz not null default now(),
  upvotes     integer not null default 0
);

-- ── activity_logs ────────────────────────────────────────────
create table if not exists public.activity_logs (
  id          bigint generated always as identity primary key,
  "userId"    text not null references public.users("userId") on delete cascade,
  event       text not null,
  "createdAt" timestamptz not null default now()
);

-- ── Indexes ──────────────────────────────────────────────────
create index if not exists idx_guardians_user     on public.guardians ("userId");
create index if not exists idx_emergencies_user   on public.emergencies ("userId");
create index if not exists idx_emergencies_status on public.emergencies (status);
create index if not exists idx_evidence_user      on public.evidence_vault ("userId");
create index if not exists idx_evidence_emergency on public.evidence_vault ("emergencyId");
create index if not exists idx_guardian_net_avail on public.guardian_network (availability, verified);
create index if not exists idx_vol_alerts_vol     on public.volunteer_alerts ("volunteerId");
create index if not exists idx_reports_user       on public.reports (user_id);
create index if not exists idx_activity_user      on public.activity_logs ("userId");

-- ── Storage buckets ──────────────────────────────────────────
insert into storage.buckets (id, name, public)
values
  ('evidence_bucket',  'evidence_bucket',  false),
  ('incident-photos',  'incident-photos',  true)
on conflict (id) do nothing;
