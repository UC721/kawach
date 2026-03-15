// supabase/functions/crowd-nearby/index.ts
// GET /functions/v1/crowd/nearby?lat={}&lng={}

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

  if (isNaN(lat) || isNaN(lng)) {
    return errorResponse('lat and lng are required');
  }

  const supabase = createUserClient(req);

  // 500 m ≈ 0.0045 degrees
  const degOffset = 500 / 111_000;

  const { data, error } = await supabase
    .from('crowd_alerts')
    .select('*')
    .gte('lat', lat - degOffset)
    .lte('lat', lat + degOffset)
    .gte('lng', lng - degOffset)
    .lte('lng', lng + degOffset)
    .gte('expires_at', new Date().toISOString())
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) return errorResponse(error.message, 500);

  return jsonResponse(data);
});
