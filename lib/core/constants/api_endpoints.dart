/// Supabase REST / Edge Function endpoint paths for KAWACH.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth (Supabase native)
  static const String authToken = '/auth/v1/token';

  // SOS
  static const String sosTrigger = '/functions/v1/sos/trigger';
  static String sosCancel(String id) => '/functions/v1/sos/$id/cancel';
  static const String sosHistory = '/rest/v1/sos_alerts';

  // Evidence
  static const String evidenceUpload = '/functions/v1/evidence/upload';
  static String evidenceUrl(String id) => '/functions/v1/evidence/$id/url';

  // Community
  static const String communityReports = '/rest/v1/community_reports';

  // Safety scores
  static const String safetyScore = '/functions/v1/safety/score';
  static const String safetyRoute = '/functions/v1/safety/route';

  // CrowdShield
  static const String crowdAlert = '/functions/v1/crowd/alert';
  static const String crowdNearby = '/functions/v1/crowd/nearby';

  // Guardians
  static const String guardians = '/rest/v1/guardians';
  static String guardiansDelete(String id) => '/rest/v1/guardians/$id';
  static const String guardiansVerify = '/functions/v1/guardians/verify';

  // Mesh
  static const String meshIngest = '/functions/v1/mesh/ingest';

  // Realtime channel names
  static String sosChannel(String userId) => 'sos:$userId';
  static String crowdChannel(String geohash5) => 'crowd:$geohash5';
  static String locationChannel(String sessionId) => 'location:$sessionId';
}
