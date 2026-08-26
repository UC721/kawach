import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Authenticated Supabase client ────────────────────────────────

/** Creates a Supabase client authenticated with the requesting user's JWT. */
export function getSupabaseClient(req: Request): SupabaseClient {
  const authHeader = req.headers.get("Authorization") ?? "";
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
}

/** Creates a Supabase client with the service-role key (bypasses RLS). */
export function getServiceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

// ── JWT helpers ──────────────────────────────────────────────────

/** Extracts the authenticated user ID from the request JWT via Supabase. */
export async function getAuthUserId(req: Request): Promise<string> {
  const client = getSupabaseClient(req);
  const {
    data: { user },
    error,
  } = await client.auth.getUser();
  if (error || !user) {
    throw new AuthError("Unauthorized");
  }
  return user.id;
}

// ── CORS headers ─────────────────────────────────────────────────

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Error helpers ────────────────────────────────────────────────

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AuthError";
  }
}

export function errorResponse(message: string, status = 400): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
