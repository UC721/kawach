-- ============================================================
-- Migration: Create additional tables
-- Tables: volunteer_responses, safe_walk_sessions,
--         location_history (partitioned), device_tokens,
--         audit_log
-- ============================================================

-- ── volunteer_responses ──────────────────────────────────────
create table if not exists public.volunteer_responses (
  id              text primary key default gen_random_uuid()::text,
  "volunteerId"   text not null references public.guardian_network("volunteerId") on delete cascade,
  "emergencyId"   text not null references public.emergencies("emergencyId") on delete cascade,
  "userId"        text not null references public.users("userId") on delete cascade,
  status          text not null default 'pending'
                    check (status in ('pending','accepted','declined','en_route','arrived','completed')),
  "respondedAt"   timestamptz,
  "arrivedAt"     timestamptz,
  lat             double precision,
  lng             double precision,
  "createdAt"     timestamptz not null default now()
);

-- ── safe_walk_sessions ───────────────────────────────────────
create table if not exists public.safe_walk_sessions (
  id               text primary key default gen_random_uuid()::text,
  "userId"         text not null references public.users("userId") on delete cascade,
  "guardianId"     text references public.guardians("guardianId") on delete set null,
  status           text not null default 'active'
                     check (status in ('active','completed','expired','emergency_triggered')),
  "startLat"       double precision,
  "startLng"       double precision,
  "destLat"        double precision,
  "destLng"        double precision,
  "durationSeconds" integer not null default 1800,
  "startedAt"      timestamptz not null default now(),
  "endedAt"        timestamptz,
  "createdAt"      timestamptz not null default now()
);

-- ── location_history (partitioned by week) ───────────────────
create table if not exists public.location_history (
  id           text not null default gen_random_uuid()::text,
  "userId"     text not null,
  lat          double precision not null,
  lng          double precision not null,
  accuracy     double precision,
  "recordedAt" timestamptz not null default now(),
  primary key (id, "recordedAt")
) partition by range ("recordedAt");

-- Create partitions for the current and next 4 weeks, plus a default
-- A scheduled job (pg_cron) should create future partitions automatically.
do $$
declare
  start_date date := date_trunc('week', current_date)::date;
  end_date   date;
  part_name  text;
  i          integer;
begin
  for i in 0..4 loop
    end_date  := start_date + interval '7 days';
    part_name := 'location_history_w' || to_char(start_date, 'YYYYMMDD');
    execute format(
      'create table if not exists public.%I partition of public.location_history
         for values from (%L) to (%L)',
      part_name, start_date, end_date
    );
    start_date := end_date;
  end loop;
end $$;

-- Default partition for rows outside existing ranges
create table if not exists public.location_history_default
  partition of public.location_history default;

-- ── device_tokens ────────────────────────────────────────────
create table if not exists public.device_tokens (
  id          text primary key default gen_random_uuid()::text,
  "userId"    text not null references public.users("userId") on delete cascade,
  token       text not null,
  platform    text not null check (platform in ('android', 'ios', 'web')),
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  unique ("userId", token)
);

-- ── audit_log ────────────────────────────────────────────────
create table if not exists public.audit_log (
  id           text primary key default gen_random_uuid()::text,
  "userId"     text not null references public.users("userId") on delete cascade,
  action       text not null,
  table_name   text,
  record_id    text,
  old_data     jsonb,
  new_data     jsonb,
  ip_address   inet,
  "createdAt"  timestamptz not null default now()
);

-- ── Indexes ──────────────────────────────────────────────────
create index if not exists idx_vol_resp_volunteer
  on public.volunteer_responses ("volunteerId");
create index if not exists idx_vol_resp_emergency
  on public.volunteer_responses ("emergencyId");
create index if not exists idx_safe_walk_user
  on public.safe_walk_sessions ("userId");
create index if not exists idx_safe_walk_status
  on public.safe_walk_sessions (status);
create index if not exists idx_loc_hist_user
  on public.location_history ("userId", "recordedAt");
create index if not exists idx_device_tokens_user
  on public.device_tokens ("userId");
create index if not exists idx_audit_log_user
  on public.audit_log ("userId");
create index if not exists idx_audit_log_table
  on public.audit_log (table_name);
