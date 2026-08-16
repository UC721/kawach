// supabase/functions/guardians-verify/index.ts
// POST /functions/v1/guardians/verify — OTP guardian verification

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
  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405);
  }

  const user = getAuthUser(req);
  if (!user) return errorResponse('Unauthorized', 401);

  const body = await req.json();
  const { guardian_id, otp } = body;

  if (!guardian_id || !otp) {
    return errorResponse('guardian_id and otp are required');
  }

  const admin = createAdminClient();

  // Fetch the guardian row (must belong to requester)
  const { data: guardian, error } = await admin
    .from('guardians')
    .select('*')
    .eq('id', guardian_id)
    .eq('user_id', user.sub)
    .single();

  if (error || !guardian) {
    return errorResponse('Guardian not found', 404);
  }

  if (guardian.verified) {
    return jsonResponse({ message: 'Guardian already verified', guardian });
  }

  // Verify OTP via Supabase Auth (guardian's phone)
  const { error: otpError } = await admin.auth.verifyOtp({
    phone: guardian.phone,
    token: otp,
    type: 'sms',
  });

  if (otpError) {
    return errorResponse('Invalid or expired OTP', 401);
  }

  // Mark guardian as verified
  const { data: updated, error: updateError } = await admin
    .from('guardians')
    .update({ verified: true })
    .eq('id', guardian_id)
    .select()
    .single();

  if (updateError) return errorResponse(updateError.message, 500);

  return jsonResponse({ message: 'Guardian verified', guardian: updated });
});
