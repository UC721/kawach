// supabase/functions/evidence-upload/index.ts
// POST /functions/v1/evidence/upload — encrypted multipart upload

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

  const supabase = createUserClient(req);

  const contentType = req.headers.get('content-type') ?? '';

  // ── Multipart upload ──────────────────────────────────────
  if (contentType.includes('multipart/form-data')) {
    const formData = await req.formData();
    const file = formData.get('file') as File | null;
    const sosAlertId = formData.get('sos_alert_id') as string | null;
    const type = (formData.get('type') as string) ?? 'audio';
    const lat = formData.get('lat') as string | null;
    const lng = formData.get('lng') as string | null;

    if (!file) return errorResponse('Missing file in form data');

    const ext = file.name.split('.').pop() ?? 'bin';
    const storagePath = `${user.sub}/${crypto.randomUUID()}.${ext}`;

    // Upload to private evidence bucket
    const { error: uploadError } = await supabase.storage
      .from('evidence')
      .upload(storagePath, file, {
        contentType: file.type,
        upsert: false,
      });

    if (uploadError) return errorResponse(uploadError.message, 500);

    // Insert metadata row
    const { data, error } = await supabase
      .from('evidence_items')
      .insert({
        user_id: user.sub,
        sos_alert_id: sosAlertId ?? null,
        type,
        storage_path: storagePath,
        encrypted: true,
        mime_type: file.type,
        size_bytes: file.size,
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null,
      })
      .select()
      .single();

    if (error) return errorResponse(error.message, 500);

    return jsonResponse(data, 201);
  }

  return errorResponse('Content-Type must be multipart/form-data');
});
