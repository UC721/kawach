import {
  getAuthUserId,
  getServiceClient,
  corsHeaders,
  errorResponse,
  jsonResponse,
} from "../_shared/utils.ts";

/**
 * Sign Evidence URL Edge Function
 *
 * Generates a signed 15-minute URL for guardian access to evidence files.
 * Every access is audit-logged with the requesting user ID and timestamp.
 *
 * Evidence items have NO direct SELECT RLS policy — access is exclusively
 * through this function, which verifies the caller is a confirmed guardian.
 */
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const userId = await getAuthUserId(req);
    const db = getServiceClient();

    const { evidence_id } = await req.json() as { evidence_id: string };
    if (!evidence_id) {
      return errorResponse("evidence_id is required");
    }

    // 1. Fetch evidence metadata (service-role bypasses RLS)
    const { data: evidence, error: evErr } = await db
      .from("evidence_items")
      .select("id, user_id, storage_path")
      .eq("id", evidence_id)
      .single();

    if (evErr || !evidence) {
      return errorResponse("Evidence not found", 404);
    }

    // 2. Verify the caller is either the owner or a confirmed guardian
    const isOwner = evidence.user_id === userId;

    if (!isOwner) {
      const { data: guardian } = await db
        .from("guardians")
        .select("id")
        .eq("user_id", evidence.user_id)
        .eq("guardian_id", userId)
        .eq("status", "confirmed")
        .single();

      if (!guardian) {
        return errorResponse("Forbidden: not a confirmed guardian", 403);
      }
    }

    // 3. Generate a signed URL valid for 15 minutes (900 seconds)
    const { data: signedUrl, error: signErr } = await db.storage
      .from("evidence")
      .createSignedUrl(evidence.storage_path as string, 900);

    if (signErr || !signedUrl) {
      return errorResponse("Failed to generate signed URL", 500);
    }

    // 4. Audit log the access
    await db.from("activity_logs").insert({
      user_id: userId,
      action: "evidence_access",
      resource_id: evidence_id,
      resource_type: "evidence_item",
      metadata: {
        evidence_owner: evidence.user_id,
        is_owner: isOwner,
      },
      created_at: new Date().toISOString(),
    });

    return jsonResponse({ signed_url: signedUrl.signedUrl, expires_in: 900 });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Internal error";
    const status = message === "Unauthorized" ? 401 : 500;
    return errorResponse(message, status);
  }
});
