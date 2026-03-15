-- ============================================================
-- KAWACH – core tables & RLS policies
-- ============================================================

-- Enable PostGIS if not already enabled (used for geo queries)
create extension if not exists postgis schema public;

-- ────────────────────────────────────────────────────────────
-- 1. sos_alerts
-- ────────────────────────────────────────────────────────────
create table if not exists public.sos_alerts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  status        text not null default 'active'
                  check (status in ('active','resolved','cancelled')),
  triggered_by  text not null default 'manual'
                  check (triggered_by in (
                    'manual','shake','voice','panic','snatch',
                    'safeWalkTimeout','countdown')),
  lat           double precision,
  lng           double precision,
  audio_url     text,
  video_url     text,
  livestream_url text,
  cancel_reason text,
  created_at    timestamptz not null default now(),
  resolved_at   timestamptz
);

create index idx_sos_alerts_user   on public.sos_alerts(user_id);
create index idx_sos_alerts_status on public.sos_alerts(status);

-- ────────────────────────────────────────────────────────────
-- 2. evidence_items
-- ────────────────────────────────────────────────────────────
create table if not exists public.evidence_items (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  sos_alert_id  uuid references public.sos_alerts(id) on delete set null,
  type          text not null default 'audio'
                  check (type in ('audio','video','image')),
  storage_path  text not null,
  encrypted     boolean not null default true,
  mime_type     text,
  size_bytes    bigint,
  lat           double precision,
  lng           double precision,
  created_at    timestamptz not null default now()
);

create index idx_evidence_user on public.evidence_items(user_id);
create index idx_evidence_sos  on public.evidence_items(sos_alert_id);

-- ────────────────────────────────────────────────────────────
-- 3. community_reports
-- ────────────────────────────────────────────────────────────
create table if not exists public.community_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  description text not null,
  image_url   text,
  lat         double precision not null,
  lng         double precision not null,
  address     text,
  severity    text not null default 'low'
                check (severity in ('low','medium','high','critical')),
  upvotes     int not null default 0,
  created_at  timestamptz not null default now()
);

create index idx_reports_geo on public.community_reports(lat, lng);
create index idx_reports_user on public.community_reports(user_id);

-- ────────────────────────────────────────────────────────────
-- 4. guardians
-- ────────────────────────────────────────────────────────────
create table if not exists public.guardians (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  phone         text not null,
  relationship  text not null,
  verified      boolean not null default false,
  fcm_token     text,
  created_at    timestamptz not null default now()
);

create index idx_guardians_user on public.guardians(user_id);

-- ────────────────────────────────────────────────────────────
-- 5. crowd_alerts
-- ────────────────────────────────────────────────────────────
create table if not exists public.crowd_alerts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  lat         double precision not null,
  lng         double precision not null,
  radius_m    int not null default 500,
  message     text,
  alert_type  text not null default 'danger'
                check (alert_type in ('danger','warning','info')),
  expires_at  timestamptz not null default (now() + interval '1 hour'),
  created_at  timestamptz not null default now()
);

create index idx_crowd_geo on public.crowd_alerts(lat, lng);

-- ────────────────────────────────────────────────────────────
-- 6. mesh_messages
-- ────────────────────────────────────────────────────────────
create table if not exists public.mesh_messages (
  id            uuid primary key default gen_random_uuid(),
  sender_id     uuid not null references auth.users(id) on delete cascade,
  payload       text not null,
  relay_count   int not null default 0,
  bloom_hash    text,
  ingested_at   timestamptz not null default now()
);

create index idx_mesh_sender on public.mesh_messages(sender_id);
create index idx_mesh_bloom  on public.mesh_messages(bloom_hash);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.sos_alerts        enable row level security;
alter table public.evidence_items    enable row level security;
alter table public.community_reports enable row level security;
alter table public.guardians         enable row level security;
alter table public.crowd_alerts      enable row level security;
alter table public.mesh_messages     enable row level security;

-- ── sos_alerts ──────────────────────────────────────────────

create policy "Users can read own SOS alerts"
  on public.sos_alerts for select
  using (auth.uid() = user_id);

create policy "Users can insert own SOS alerts"
  on public.sos_alerts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own SOS alerts"
  on public.sos_alerts for update
  using (auth.uid() = user_id);

-- Guardians can read SOS alerts of users they guard
create policy "Guardians can read their user SOS alerts"
  on public.sos_alerts for select
  using (
    exists (
      select 1 from public.guardians g
      where g.phone = (
        select raw_user_meta_data->>'phone' from auth.users where id = auth.uid()
      )
      and g.user_id = sos_alerts.user_id
      and g.verified = true
    )
  );

-- ── evidence_items ──────────────────────────────────────────
-- No direct SELECT – access is through the sign-evidence-url function

create policy "Users can insert own evidence"
  on public.evidence_items for insert
  with check (auth.uid() = user_id);

create policy "Users can read own evidence"
  on public.evidence_items for select
  using (auth.uid() = user_id);

-- ── community_reports ───────────────────────────────────────

create policy "Anyone authenticated can read reports"
  on public.community_reports for select
  using (auth.uid() is not null);

create policy "Users can insert own reports"
  on public.community_reports for insert
  with check (auth.uid() = user_id);

create policy "Users can update own reports"
  on public.community_reports for update
  using (auth.uid() = user_id);

-- ── guardians ───────────────────────────────────────────────

create policy "Users can read own guardians"
  on public.guardians for select
  using (auth.uid() = user_id);

create policy "Users can insert own guardians"
  on public.guardians for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own guardians"
  on public.guardians for delete
  using (auth.uid() = user_id);

create policy "Users can update own guardians"
  on public.guardians for update
  using (auth.uid() = user_id);

-- ── crowd_alerts ────────────────────────────────────────────

create policy "Anyone authenticated can read crowd alerts"
  on public.crowd_alerts for select
  using (auth.uid() is not null);

create policy "Users can insert own crowd alerts"
  on public.crowd_alerts for insert
  with check (auth.uid() = user_id);

-- ── mesh_messages ───────────────────────────────────────────

create policy "Users can insert own mesh messages"
  on public.mesh_messages for insert
  with check (auth.uid() = sender_id);

create policy "Users can read own mesh messages"
  on public.mesh_messages for select
  using (auth.uid() = sender_id);

-- ============================================================
-- Realtime – enable publication for channels
-- ============================================================

alter publication supabase_realtime add table public.sos_alerts;
alter publication supabase_realtime add table public.crowd_alerts;

-- ============================================================
-- Storage bucket for evidence
-- ============================================================

insert into storage.buckets (id, name, public)
values ('evidence', 'evidence', false)
on conflict (id) do nothing;

-- Storage policies: users can upload to their own folder
create policy "Users upload own evidence"
  on storage.objects for insert
  with check (
    bucket_id = 'evidence'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users read own evidence"
  on storage.objects for select
  using (
    bucket_id = 'evidence'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
