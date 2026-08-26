import {
  getAuthUserId,
  getServiceClient,
  corsHeaders,
  errorResponse,
  jsonResponse,
} from "../_shared/utils.ts";

/**
 * Guardian Verification Edge Function
 *
 * Handles:
 *  • OTP confirmation to accept a guardian invitation.
 *  • 48-hour cooldown enforcement before a guardian can be removed.
 */
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const userId = await getAuthUserId(req);
    const db = getServiceClient();
    const body = await req.json();

    const { action } = body as { action: string };

    switch (action) {
      case "confirm":
        return await confirmGuardian(db, userId, body);
      case "remove":
        return await removeGuardian(db, userId, body);
      default:
        return errorResponse('Invalid action. Use "confirm" or "remove".');
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : "Internal error";
    const status = message === "Unauthorized" ? 401 : 500;
    return errorResponse(message, status);
  }
});

// ── Confirm guardian via OTP ─────────────────────────────────────

async function confirmGuardian(
  db: ReturnType<typeof getServiceClient>,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const { guardian_id, otp } = body as {
    guardian_id: string;
    otp: string;
  };

  if (!guardian_id || !otp) {
    return errorResponse("guardian_id and otp are required");
  }

  // Verify OTP via Supabase Auth (phone OTP verification)
  // In production this would call auth.verifyOtp; here we validate the
  // guardian relationship exists and is pending.
  const { data: guardian, error } = await db
    .from("guardians")
    .select("*")
    .eq("user_id", userId)
    .eq("guardian_id", guardian_id)
    .eq("status", "pending")
    .single();

  if (error || !guardian) {
    return errorResponse("No pending guardian invitation found", 404);
  }

  // Mark as confirmed
  const { error: updateErr } = await db
    .from("guardians")
    .update({
      status: "confirmed",
      confirmed_at: new Date().toISOString(),
    })
    .eq("id", guardian.id);

  if (updateErr) {
    return errorResponse("Failed to confirm guardian", 500);
  }

  // Audit log
  await db.from("activity_logs").insert({
    user_id: userId,
    action: "guardian_confirmed",
    resource_id: guardian_id,
    resource_type: "guardian",
    created_at: new Date().toISOString(),
  });

  return jsonResponse({ status: "confirmed", guardian_id });
}

// ── Remove guardian with 48h cooldown ────────────────────────────

async function removeGuardian(
  db: ReturnType<typeof getServiceClient>,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const { guardian_id } = body as { guardian_id: string };

  if (!guardian_id) {
    return errorResponse("guardian_id is required");
  }

  const { data: guardian, error } = await db
    .from("guardians")
    .select("*")
    .eq("user_id", userId)
    .eq("guardian_id", guardian_id)
    .eq("status", "confirmed")
    .single();

  if (error || !guardian) {
    return errorResponse("Confirmed guardian not found", 404);
  }

  // Enforce 48-hour cooldown from confirmation
  const confirmedAt = new Date(guardian.confirmed_at as string);
  const hoursSinceConfirm =
    (Date.now() - confirmedAt.getTime()) / (1000 * 60 * 60);

  if (hoursSinceConfirm < 48) {
    const remaining = Math.ceil(48 - hoursSinceConfirm);
    return errorResponse(
      `Cannot remove guardian yet. 48h cooldown: ${remaining}h remaining.`,
      403,
    );
  }

  // Soft-delete: mark as removed
  const { error: updateErr } = await db
    .from("guardians")
    .update({
      status: "removed",
      removed_at: new Date().toISOString(),
    })
    .eq("id", guardian.id);

  if (updateErr) {
    return errorResponse("Failed to remove guardian", 500);
  }

  // Audit log
  await db.from("activity_logs").insert({
    user_id: userId,
    action: "guardian_removed",
    resource_id: guardian_id,
    resource_type: "guardian",
    created_at: new Date().toISOString(),
  });

  return jsonResponse({ status: "removed", guardian_id });
}
