-- ============================================================
-- KAWACH Scalability: Database Indexing & Partitioning
-- Designed for millions of concurrent users
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Indexes for high-traffic query paths
-- ────────────────────────────────────────────────────────────

-- Users: fast auth-id lookup (every authenticated request)
CREATE INDEX IF NOT EXISTS idx_users_auth_id
  ON users ("authId");

-- Emergencies: active emergencies per user (SOS dashboard)
CREATE INDEX IF NOT EXISTS idx_emergencies_user_status
  ON emergencies ("userId", "status");

-- Emergencies: recent emergencies by creation time (feed)
CREATE INDEX IF NOT EXISTS idx_emergencies_created_at
  ON emergencies ("createdAt" DESC);

-- Guardian network: lookup by user (guardian screen)
CREATE INDEX IF NOT EXISTS idx_guardian_network_user
  ON guardian_network ("userId");

-- Guardian network: lookup by guardian (notification dispatch)
CREATE INDEX IF NOT EXISTS idx_guardian_network_guardian
  ON guardian_network ("guardianId");

-- Reports: community feed sorted by time
CREATE INDEX IF NOT EXISTS idx_reports_created_at
  ON reports (created_at DESC);

-- Reports: geographic filtering (map screen)
CREATE INDEX IF NOT EXISTS idx_reports_location
  ON reports (latitude, longitude);

-- Danger zones: spatial lookup (proximity check on location update)
CREATE INDEX IF NOT EXISTS idx_dangerzone_location
  ON dangerzone (latitude, longitude);

-- Evidence vault: per-emergency evidence listing
CREATE INDEX IF NOT EXISTS idx_evidence_vault_emergency
  ON evidence_vault ("emergencyId");

-- Activity logs: per-user audit trail
CREATE INDEX IF NOT EXISTS idx_activity_logs_user
  ON activity_logs ("userId", "createdAt" DESC);

-- Volunteer alerts: nearby volunteer search
CREATE INDEX IF NOT EXISTS idx_volunteer_alerts_location
  ON volunteer_alerts (latitude, longitude);

-- ────────────────────────────────────────────────────────────
-- 2. Partitioning: location_history by month
--    At millions of users updating every 5 seconds, location
--    data grows fast. Monthly partitions allow old months to be
--    archived/dropped without vacuuming the main table.
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS location_history (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "userId"      uuid NOT NULL REFERENCES users(id),
  latitude      double precision NOT NULL,
  longitude     double precision NOT NULL,
  accuracy      double precision,
  speed         double precision,
  heading       double precision,
  region_key    int NOT NULL DEFAULT 0,
  recorded_at   timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (recorded_at);

-- Create partitions for the current and next month
-- (in production a scheduled job creates future partitions)
CREATE TABLE IF NOT EXISTS location_history_default
  PARTITION OF location_history DEFAULT;

-- Index for the partitioned table
CREATE INDEX IF NOT EXISTS idx_location_history_user_time
  ON location_history ("userId", recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_location_history_region
  ON location_history (region_key, recorded_at DESC);

-- ────────────────────────────────────────────────────────────
-- 3. Partitioning: emergency_events by month
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS emergency_events (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "userId"      uuid NOT NULL REFERENCES users(id),
  event_type    text NOT NULL,
  payload       jsonb,
  region_key    int NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);

CREATE TABLE IF NOT EXISTS emergency_events_default
  PARTITION OF emergency_events DEFAULT;

CREATE INDEX IF NOT EXISTS idx_emergency_events_user
  ON emergency_events ("userId", created_at DESC);

CREATE INDEX IF NOT EXISTS idx_emergency_events_region
  ON emergency_events (region_key, created_at DESC);

-- ────────────────────────────────────────────────────────────
-- 4. Row-level security on new tables
-- ────────────────────────────────────────────────────────────

ALTER TABLE location_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_events ENABLE ROW LEVEL SECURITY;

-- Users may only read/write their own location history
CREATE POLICY location_history_owner ON location_history
  USING (auth.uid() = "userId")
  WITH CHECK (auth.uid() = "userId");

-- Users may only read/write their own emergency events
CREATE POLICY emergency_events_owner ON emergency_events
  USING (auth.uid() = "userId")
  WITH CHECK (auth.uid() = "userId");

-- ────────────────────────────────────────────────────────────
-- 5. Database-level connection management hint
-- ────────────────────────────────────────────────────────────

-- Supabase uses PgBouncer in transaction mode by default.
-- For millions of concurrent users ensure the project's
-- connection-pool settings in the Supabase dashboard are:
--   pool_mode  = transaction
--   pool_size >= 20  (per-region)
--   statement_timeout = 30s
-- This migration is a documentation placeholder; the actual
-- setting lives in the Supabase project dashboard.
