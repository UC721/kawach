// supabase/functions/safety-score/index.ts
// GET /functions/v1/safety/score?lat={}&lng={}&radius=500

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import {
  corsHeaders,
  createUserClient,
  errorResponse,
  getAuthUser,
  jsonResponse,
} from '../_shared/utils.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'GET') {
    return errorResponse('Method not allowed', 405);
  }

  const user = getAuthUser(req);
  if (!user) return errorResponse('Unauthorized', 401);

  const url = new URL(req.url);
  const lat = parseFloat(url.searchParams.get('lat') ?? '');
  const lng = parseFloat(url.searchParams.get('lng') ?? '');
  const radius = parseInt(url.searchParams.get('radius') ?? '500', 10);

  if (isNaN(lat) || isNaN(lng)) {
    return errorResponse('lat and lng are required');
  }

  const supabase = createUserClient(req);

  // Approximate bounding box (1° ≈ 111 km)
  const degOffset = radius / 111_000;
  const latMin = lat - degOffset;
  const latMax = lat + degOffset;
  const lngMin = lng - degOffset;
  const lngMax = lng + degOffset;

  // Count recent SOS alerts in the area (last 30 days)
  const thirtyDaysAgo = new Date(
    Date.now() - 30 * 24 * 60 * 60 * 1000,
  ).toISOString();

  const { count: sosCount } = await supabase
    .from('sos_alerts')
    .select('*', { count: 'exact', head: true })
    .gte('lat', latMin)
    .lte('lat', latMax)
    .gte('lng', lngMin)
    .lte('lng', lngMax)
    .gte('created_at', thirtyDaysAgo);

  // Count community reports in the area
  const { count: reportCount } = await supabase
    .from('community_reports')
    .select('*', { count: 'exact', head: true })
    .gte('lat', latMin)
    .lte('lat', latMax)
    .gte('lng', lngMin)
    .lte('lng', lngMax)
    .gte('created_at', thirtyDaysAgo);

  // Count active crowd alerts in the area
  const { count: crowdCount } = await supabase
    .from('crowd_alerts')
    .select('*', { count: 'exact', head: true })
    .gte('lat', latMin)
    .lte('lat', latMax)
    .gte('lng', lngMin)
    .lte('lng', lngMax)
    .gte('expires_at', new Date().toISOString());

  const incidents = (sosCount ?? 0) + (reportCount ?? 0) + (crowdCount ?? 0);

  // Score: 10 = safest, 0 = most dangerous
  // Each incident reduces score by 1, minimum 0
  const score = Math.max(0, 10 - incidents);

  return jsonResponse({
    lat,
    lng,
    radius,
    score,
    details: {
      sos_alerts: sosCount ?? 0,
      community_reports: reportCount ?? 0,
      crowd_alerts: crowdCount ?? 0,
    },
  });
});
