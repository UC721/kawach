// supabase/functions/crowd-alert/index.ts
// POST /functions/v1/crowd/alert — notify users within 500 m

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
  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405);
  }

  const user = getAuthUser(req);
  if (!user) return errorResponse('Unauthorized', 401);

  const body = await req.json();
  const { lat, lng, message, alert_type } = body;

  if (lat == null || lng == null) {
    return errorResponse('lat and lng are required');
  }

  const supabase = createUserClient(req);

  const { data, error } = await supabase
    .from('crowd_alerts')
    .insert({
      user_id: user.sub,
      lat,
      lng,
      radius_m: 500,
      message: message ?? null,
      alert_type: alert_type ?? 'danger',
    })
    .select()
    .single();

  if (error) return errorResponse(error.message, 500);

  // Compute geohash prefix (5 chars ≈ ±2.4 km cell) for broadcast channel
  const geohash5 = simpleGeohash(lat, lng, 5);

  await supabase.channel(`crowd:${geohash5}`).send({
    type: 'broadcast',
    event: 'crowd_alert',
    payload: data,
  });

  return jsonResponse(data, 201);
});

/** Minimal geohash encoder (returns first `precision` characters). */
function simpleGeohash(
  lat: number,
  lng: number,
  precision: number,
): string {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  let minLat = -90,
    maxLat = 90;
  let minLng = -180,
    maxLng = 180;
  let hash = '';
  let bit = 0;
  let ch = 0;
  let isLng = true;

  while (hash.length < precision) {
    if (isLng) {
      const mid = (minLng + maxLng) / 2;
      if (lng >= mid) {
        ch = ch | (1 << (4 - bit));
        minLng = mid;
      } else {
        maxLng = mid;
      }
    } else {
      const mid = (minLat + maxLat) / 2;
      if (lat >= mid) {
        ch = ch | (1 << (4 - bit));
        minLat = mid;
      } else {
        maxLat = mid;
      }
    }
    isLng = !isLng;
    bit++;
    if (bit === 5) {
      hash += base32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return hash;
}
