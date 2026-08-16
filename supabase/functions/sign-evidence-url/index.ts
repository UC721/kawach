// supabase/functions/sign-evidence-url/index.ts
// GET /functions/v1/evidence/:id/url — signed 15-min URL for guardians

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import {
  corsHeaders,
  createAdminClient,
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
  const segments = url.pathname.split('/').filter(Boolean);
  // Expected: /evidence/<id>/url
  const evidenceId = segments.length >= 2 ? segments[segments.length - 2] : null;

  if (!evidenceId) return errorResponse('Missing evidence id');

  // Use admin client to bypass RLS – function handles its own authz
  const admin = createAdminClient();

  // Fetch evidence metadata
  const { data: evidence, error } = await admin
    .from('evidence_items')
    .select('*')
    .eq('id', evidenceId)
    .single();

  if (error || !evidence) return errorResponse('Evidence not found', 404);

  // Authorization: owner OR verified guardian of the owner
  const isOwner = evidence.user_id === user.sub;

  let isGuardian = false;
  if (!isOwner) {
    const { data: guardianRows } = await admin
      .from('guardians')
      .select('id')
      .eq('user_id', evidence.user_id)
      .eq('verified', true);

    if (guardianRows && guardianRows.length > 0) {
      // Check if requester's phone matches any verified guardian
      const { data: requesterUser } = await admin.auth.admin.getUserById(
        user.sub,
      );
      const requesterPhone = requesterUser?.user?.phone;

      if (requesterPhone) {
        const { data: match } = await admin
          .from('guardians')
          .select('id')
          .eq('user_id', evidence.user_id)
          .eq('phone', requesterPhone)
          .eq('verified', true)
          .limit(1);

        isGuardian = (match?.length ?? 0) > 0;
      }
    }
  }

  if (!isOwner && !isGuardian) {
    return errorResponse('Forbidden', 403);
  }

  // Generate signed URL (15 minutes = 900 seconds)
  const { data: signedUrl, error: signError } = await admin.storage
    .from('evidence')
    .createSignedUrl(evidence.storage_path, 900);

  if (signError) return errorResponse(signError.message, 500);

  return jsonResponse({ url: signedUrl.signedUrl, expires_in: 900 });
});
