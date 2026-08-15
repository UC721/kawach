// supabase/functions/sign-evidence-url/index.ts
//
// Edge function that mediates access to evidence items.
// Evidence rows are never directly readable — this function verifies
// ownership via the service_role key, then returns a time-limited
// signed URL for the requested evidence file.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SIGNED_URL_EXPIRY_SECONDS = 300; // 5 minutes

serve(async (req: Request) => {
  // Only accept POST requests
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Extract the user's JWT from the Authorization header
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Missing authorization" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
  const userJwt = authHeader.replace("Bearer ", "");

  // Parse request body
  let body: { evidenceId?: string; fileType?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { evidenceId, fileType } = body;
  if (!evidenceId || !fileType) {
    return new Response(
      JSON.stringify({ error: "evidenceId and fileType are required" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (!["audio", "video"].includes(fileType)) {
    return new Response(
      JSON.stringify({ error: "fileType must be 'audio' or 'video'" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // ── Authenticate the calling user ──────────────────────────
  const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: `Bearer ${userJwt}` } },
    auth: { persistSession: false },
  });

  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser(userJwt);

  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── Use service_role to bypass RLS and look up the evidence row ──
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: evidence, error: fetchError } = await adminClient
    .from("evidence_vault")
    .select("evidenceId, userId, audioUrl, videoUrl")
    .eq("evidenceId", evidenceId)
    .single();

  if (fetchError || !evidence) {
    return new Response(JSON.stringify({ error: "Evidence not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── Verify ownership – user may only access their own evidence ──
  if (evidence.userId !== user.id) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── Determine the storage path ─────────────────────────────
  const urlField = fileType === "audio" ? "audioUrl" : "videoUrl";
  const fileUrl: string | null = evidence[urlField];

  if (!fileUrl) {
    return new Response(
      JSON.stringify({ error: `No ${fileType} file for this evidence` }),
      { status: 404, headers: { "Content-Type": "application/json" } },
    );
  }

  // Extract the storage path from the public/full URL
  // Supabase storage URLs follow: .../storage/v1/object/public/<bucket>/<path>
  const pathMatch = fileUrl.match(/evidence_bucket\/(.+)$/);
  if (!pathMatch) {
    return new Response(
      JSON.stringify({ error: "Unable to resolve storage path" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
  const storagePath = pathMatch[1];

  // ── Generate signed URL ────────────────────────────────────
  const { data: signed, error: signError } = await adminClient.storage
    .from("evidence_bucket")
    .createSignedUrl(storagePath, SIGNED_URL_EXPIRY_SECONDS);

  if (signError || !signed?.signedUrl) {
    return new Response(
      JSON.stringify({ error: "Failed to generate signed URL" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({
      signedUrl: signed.signedUrl,
      expiresIn: SIGNED_URL_EXPIRY_SECONDS,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
