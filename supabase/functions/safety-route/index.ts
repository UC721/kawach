// supabase/functions/safety-route/index.ts
// GET /functions/v1/safety/route?from={lat,lng}&to={lat,lng}

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
  const from = url.searchParams.get('from'); // "lat,lng"
  const to = url.searchParams.get('to'); // "lat,lng"

  if (!from || !to) {
    return errorResponse('from and to query params are required (lat,lng)');
  }

  const [fromLat, fromLng] = from.split(',').map(Number);
  const [toLat, toLng] = to.split(',').map(Number);

  if ([fromLat, fromLng, toLat, toLng].some(isNaN)) {
    return errorResponse('Invalid coordinate format. Use lat,lng');
  }

  const supabase = createUserClient(req);

  // Build bounding box encompassing both endpoints with padding
  const latMin = Math.min(fromLat, toLat) - 0.01;
  const latMax = Math.max(fromLat, toLat) + 0.01;
  const lngMin = Math.min(fromLng, toLng) - 0.01;
  const lngMax = Math.max(fromLng, toLng) + 0.01;

  const thirtyDaysAgo = new Date(
    Date.now() - 30 * 24 * 60 * 60 * 1000,
  ).toISOString();

  // Fetch incidents along the route corridor
  const { data: sosAlerts } = await supabase
    .from('sos_alerts')
    .select('lat, lng')
    .gte('lat', latMin)
    .lte('lat', latMax)
    .gte('lng', lngMin)
    .lte('lng', lngMax)
    .gte('created_at', thirtyDaysAgo);

  const { data: reports } = await supabase
    .from('community_reports')
    .select('lat, lng, severity')
    .gte('lat', latMin)
    .lte('lat', latMax)
    .gte('lng', lngMin)
    .lte('lng', lngMax)
    .gte('created_at', thirtyDaysAgo);

  const incidents = [
    ...(sosAlerts ?? []).map((a) => ({
      lat: a.lat,
      lng: a.lng,
      weight: 2,
    })),
    ...(reports ?? []).map((r) => ({
      lat: r.lat,
      lng: r.lng,
      weight: r.severity === 'critical' ? 3 : r.severity === 'high' ? 2 : 1,
    })),
  ];

  const totalWeight = incidents.reduce((sum, i) => sum + i.weight, 0);
  const score = Math.max(0, 10 - totalWeight);

  return jsonResponse({
    from: { lat: fromLat, lng: fromLng },
    to: { lat: toLat, lng: toLng },
    score,
    incident_count: incidents.length,
    incidents,
  });
});
