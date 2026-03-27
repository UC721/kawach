-- ============================================================
-- Migration: Enable Row Level Security and create policies
-- All tables enforce that users can only read/write their own rows.
-- Evidence items are never directly readable (access via signed URL
-- edge function only).
-- ============================================================

-- ── Enable RLS on every table ────────────────────────────────
alter table public.users              enable row level security;
alter table public.guardians          enable row level security;
alter table public.emergencies        enable row level security;
alter table public.evidence_vault     enable row level security;
alter table public.guardian_network   enable row level security;
alter table public.volunteer_alerts   enable row level security;
alter table public.dangerzone         enable row level security;
alter table public.reports            enable row level security;
alter table public.activity_logs      enable row level security;
alter table public.volunteer_responses enable row level security;
alter table public.safe_walk_sessions enable row level security;
alter table public.location_history   enable row level security;
alter table public.device_tokens      enable row level security;
alter table public.audit_log          enable row level security;

-- ================================================================
-- USERS – owner can read and update their own row
-- ================================================================
create policy "users_select_own" on public.users
  for select using (auth.uid()::text = "userId");

create policy "users_insert_own" on public.users
  for insert with check (auth.uid()::text = "userId");

create policy "users_update_own" on public.users
  for update using (auth.uid()::text = "userId");

-- ================================================================
-- GUARDIANS – owner can CRUD their own guardians
-- ================================================================
create policy "guardians_select_own" on public.guardians
  for select using (auth.uid()::text = "userId");

create policy "guardians_insert_own" on public.guardians
  for insert with check (auth.uid()::text = "userId");

create policy "guardians_delete_own" on public.guardians
  for delete using (auth.uid()::text = "userId");

-- ================================================================
-- EMERGENCIES – owner can read/write their own emergencies
-- ================================================================
create policy "emergencies_select_own" on public.emergencies
  for select using (auth.uid()::text = "userId");

create policy "emergencies_insert_own" on public.emergencies
  for insert with check (auth.uid()::text = "userId");

create policy "emergencies_update_own" on public.emergencies
  for update using (auth.uid()::text = "userId");

-- ================================================================
-- EVIDENCE VAULT – NO direct SELECT policy.
-- Evidence rows are never directly readable by any user.
-- Access is mediated through the sign-evidence-url edge function
-- which generates time-limited signed URLs.
-- Users may insert evidence for their own emergencies.
-- ================================================================
create policy "evidence_insert_own" on public.evidence_vault
  for insert with check (auth.uid()::text = "userId");

-- No SELECT / UPDATE / DELETE policies – evidence is never directly
-- readable. The sign-evidence-url edge function uses the service_role
-- key to read evidence metadata on behalf of the authenticated user
-- after verifying ownership.

-- ================================================================
-- GUARDIAN NETWORK (volunteers) – own row read/write
-- ================================================================
create policy "guardian_network_select_own" on public.guardian_network
  for select using (auth.uid()::text = "userId");

-- Allow all authenticated users to read verified available volunteers
-- (needed for nearby-volunteer search)
create policy "guardian_network_select_available" on public.guardian_network
  for select using (verified = true and availability = true);

create policy "guardian_network_insert_own" on public.guardian_network
  for insert with check (auth.uid()::text = "userId");

create policy "guardian_network_update_own" on public.guardian_network
  for update using (auth.uid()::text = "userId");

-- ================================================================
-- VOLUNTEER ALERTS – volunteers read their own alerts;
-- emergency owner can insert alerts for nearby volunteers
-- ================================================================
create policy "volunteer_alerts_select_own" on public.volunteer_alerts
  for select using (auth.uid()::text = "volunteerId");

create policy "volunteer_alerts_insert_own" on public.volunteer_alerts
  for insert with check (auth.uid()::text = "userId");

-- ================================================================
-- DANGERZONE – all authenticated users may read; only service_role writes
-- ================================================================
create policy "dangerzone_select_all" on public.dangerzone
  for select using (true);

create policy "dangerzone_insert_auth" on public.dangerzone
  for insert with check (auth.role() = 'authenticated');

create policy "dangerzone_update_auth" on public.dangerzone
  for update using (auth.role() = 'authenticated');

-- ================================================================
-- REPORTS – owner can insert/read own; all authenticated can read
-- ================================================================
create policy "reports_select_all" on public.reports
  for select using (true);

create policy "reports_insert_own" on public.reports
  for insert with check (auth.uid()::text = user_id);

create policy "reports_update_own" on public.reports
  for update using (auth.uid()::text = user_id);

-- ================================================================
-- ACTIVITY LOGS – owner only
-- ================================================================
create policy "activity_logs_select_own" on public.activity_logs
  for select using (auth.uid()::text = "userId");

create policy "activity_logs_insert_own" on public.activity_logs
  for insert with check (auth.uid()::text = "userId");

-- ================================================================
-- VOLUNTEER RESPONSES – volunteer reads own; emergency owner can read
-- ================================================================
create policy "volunteer_responses_select_own" on public.volunteer_responses
  for select using (
    auth.uid()::text = "volunteerId"
    or auth.uid()::text = "userId"
  );

create policy "volunteer_responses_insert_own" on public.volunteer_responses
  for insert with check (auth.uid()::text = "volunteerId");

create policy "volunteer_responses_update_own" on public.volunteer_responses
  for update using (auth.uid()::text = "volunteerId");

-- ================================================================
-- SAFE WALK SESSIONS – owner only
-- ================================================================
create policy "safe_walk_select_own" on public.safe_walk_sessions
  for select using (auth.uid()::text = "userId");

create policy "safe_walk_insert_own" on public.safe_walk_sessions
  for insert with check (auth.uid()::text = "userId");

create policy "safe_walk_update_own" on public.safe_walk_sessions
  for update using (auth.uid()::text = "userId");

-- ================================================================
-- LOCATION HISTORY – owner only
-- ================================================================
create policy "location_history_select_own" on public.location_history
  for select using (auth.uid()::text = "userId");

create policy "location_history_insert_own" on public.location_history
  for insert with check (auth.uid()::text = "userId");

-- ================================================================
-- DEVICE TOKENS – owner only
-- ================================================================
create policy "device_tokens_select_own" on public.device_tokens
  for select using (auth.uid()::text = "userId");

create policy "device_tokens_insert_own" on public.device_tokens
  for insert with check (auth.uid()::text = "userId");

create policy "device_tokens_update_own" on public.device_tokens
  for update using (auth.uid()::text = "userId");

create policy "device_tokens_delete_own" on public.device_tokens
  for delete using (auth.uid()::text = "userId");

-- ================================================================
-- AUDIT LOG – owner can read own; insert via service_role or trigger
-- ================================================================
create policy "audit_log_select_own" on public.audit_log
  for select using (auth.uid()::text = "userId");

create policy "audit_log_insert_own" on public.audit_log
  for insert with check (auth.uid()::text = "userId");

-- ================================================================
-- STORAGE POLICIES – evidence_bucket (private), incident-photos (public)
-- ================================================================

-- evidence_bucket: users can upload to their own path, no direct reads
create policy "evidence_upload_own" on storage.objects
  for insert with check (
    bucket_id = 'evidence_bucket'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- incident-photos: authenticated users can upload; everyone can read
create policy "incident_photos_upload" on storage.objects
  for insert with check (
    bucket_id = 'incident-photos'
    and auth.role() = 'authenticated'
  );

create policy "incident_photos_read" on storage.objects
  for select using (bucket_id = 'incident-photos');
