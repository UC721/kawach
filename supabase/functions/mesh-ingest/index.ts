// supabase/functions/mesh-ingest/index.ts
// POST /functions/v1/mesh/ingest — bulk encrypted mesh messages

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
  const { messages } = body;

  if (!Array.isArray(messages) || messages.length === 0) {
    return errorResponse('messages array is required and must not be empty');
  }

  const supabase = createUserClient(req);

  // Validate and prepare rows
  const rows = messages.map(
    (msg: { payload: string; relay_count?: number; bloom_hash?: string }) => ({
      sender_id: user.sub,
      payload: msg.payload,
      relay_count: msg.relay_count ?? 0,
      bloom_hash: msg.bloom_hash ?? null,
    }),
  );

  // Deduplicate by bloom_hash — skip messages already ingested
  const hashes = rows
    .map((r: { bloom_hash: string | null }) => r.bloom_hash)
    .filter(Boolean) as string[];

  let existingHashes: Set<string> = new Set();
  if (hashes.length > 0) {
    const { data: existing } = await supabase
      .from('mesh_messages')
      .select('bloom_hash')
      .in('bloom_hash', hashes);
    existingHashes = new Set(
      (existing ?? []).map((e: { bloom_hash: string }) => e.bloom_hash),
    );
  }

  const newRows = rows.filter(
    (r: { bloom_hash: string | null }) =>
      !r.bloom_hash || !existingHashes.has(r.bloom_hash),
  );

  if (newRows.length === 0) {
    return jsonResponse({ inserted: 0, duplicates: rows.length });
  }

  const { data, error } = await supabase
    .from('mesh_messages')
    .insert(newRows)
    .select();

  if (error) return errorResponse(error.message, 500);

  return jsonResponse({
    inserted: data?.length ?? 0,
    duplicates: rows.length - (data?.length ?? 0),
  });
});
