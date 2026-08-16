// supabase/functions/sos/index.ts
// POST  /functions/v1/sos  → trigger (body.action == "trigger")
// PATCH /functions/v1/sos  → cancel  (body.action == "cancel")

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import {
  corsHeaders,
  createUserClient,
  errorResponse,
  getAuthUser,
  jsonResponse,
} from '../_shared/utils.ts';

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const user = getAuthUser(req);
  if (!user) return errorResponse('Unauthorized', 401);

  const supabase = createUserClient(req);

  // ── POST: trigger SOS ─────────────────────────────────────
  if (req.method === 'POST') {
    const body = await req.json();
    const { triggered_by, lat, lng } = body;

    const { data, error } = await supabase
      .from('sos_alerts')
      .insert({
        user_id: user.sub,
        triggered_by: triggered_by ?? 'manual',
        lat: lat ?? null,
        lng: lng ?? null,
        status: 'active',
      })
      .select()
      .single();

    if (error) return errorResponse(error.message, 500);

    // Broadcast to realtime channel sos:{user_id}
    await supabase.channel(`sos:${user.sub}`).send({
      type: 'broadcast',
      event: 'sos_triggered',
      payload: data,
    });

    return jsonResponse(data, 201);
  }

  // ── PATCH: cancel SOS ─────────────────────────────────────
  if (req.method === 'PATCH') {
    const url = new URL(req.url);
    const segments = url.pathname.split('/').filter(Boolean);
    // Expected path: /sos/<id>/cancel
    const alertId = segments.length >= 2 ? segments[segments.length - 2] : null;

    const body = await req.json();
    const { cancel_reason } = body;

    if (!alertId) return errorResponse('Missing alert id in path');

    const { data, error } = await supabase
      .from('sos_alerts')
      .update({
        status: 'cancelled',
        cancel_reason: cancel_reason ?? null,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', alertId)
      .eq('user_id', user.sub)
      .select()
      .single();

    if (error) return errorResponse(error.message, 500);

    await supabase.channel(`sos:${user.sub}`).send({
      type: 'broadcast',
      event: 'sos_cancelled',
      payload: data,
    });

    return jsonResponse(data);
  }

  return errorResponse('Method not allowed', 405);
});
