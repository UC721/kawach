import {
  getAuthUserId,
  getServiceClient,
  corsHeaders,
  errorResponse,
  jsonResponse,
} from "../_shared/utils.ts";

/**
 * SOS Edge Function
 *
 * Rate-limited: max 3 SOS alerts per user within a 10-minute window.
 * Includes an AI fraud score + velocity check before dispatching.
 */
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Authenticate
    const userId = await getAuthUserId(req);
    const db = getServiceClient();

    // 2. Rate-limit: max 3 in 10 minutes
    const windowStart = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { data: recent, error: rlErr } = await db
      .from("sos_alerts")
      .select("id")
      .eq("user_id", userId)
      .gte("created_at", windowStart);

    if (rlErr) {
      return errorResponse("Rate-limit check failed", 500);
    }
    if ((recent?.length ?? 0) >= 3) {
      return errorResponse("Rate limit exceeded: max 3 SOS in 10 minutes", 429);
    }

    // 3. Parse request body
    const body = await req.json();
    const { lat, lng, trigger } = body as {
      lat?: number;
      lng?: number;
      trigger?: string;
    };

    // 4. Compute fraud score (velocity + heuristic)
    const fraudScore = await computeFraudScore(db, userId, lat, lng);

    // 5. Insert SOS alert
    const { data: alert, error: insertErr } = await db
      .from("sos_alerts")
      .insert({
        user_id: userId,
        lat,
        lng,
        trigger: trigger ?? "manual",
        fraud_score: fraudScore,
        status: fraudScore >= 0.7 ? "flagged" : "active",
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (insertErr) {
      return errorResponse("Failed to create SOS alert", 500);
    }

    return jsonResponse({ alert, fraud_score: fraudScore });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Internal error";
    const status = message === "Unauthorized" ? 401 : 500;
    return errorResponse(message, status);
  }
});

// ── Fraud score computation ──────────────────────────────────────

async function computeFraudScore(
  db: ReturnType<typeof getServiceClient>,
  userId: string,
  lat?: number,
  lng?: number,
): Promise<number> {
  let score = 0;

  // Velocity: check last alert location + time
  const { data: lastAlert } = await db
    .from("sos_alerts")
    .select("lat, lng, created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (lastAlert && lat != null && lng != null) {
    const lastLat = lastAlert.lat as number | null;
    const lastLng = lastAlert.lng as number | null;
    const lastTime = new Date(lastAlert.created_at as string);

    if (lastLat != null && lastLng != null) {
      const dLat = (lat - lastLat) * 111;
      const dLng = (lng - lastLng) * 111 * 0.7;
      const distKm = Math.sqrt(dLat * dLat + dLng * dLng);
      const elapsedH =
        (Date.now() - lastTime.getTime()) / (1000 * 60 * 60);

      if (elapsedH > 0 && distKm / elapsedH > 200) {
        score += 0.4; // Implausible travel speed
      }
    }
  }

  // Time-of-day: 2 AM – 5 AM bump
  const hour = new Date().getHours();
  if (hour >= 2 && hour < 5) {
    score += 0.1;
  }

  return Math.min(score, 1.0);
}
