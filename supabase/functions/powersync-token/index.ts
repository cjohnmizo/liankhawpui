import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT } from "npm:jose@5";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function decodeBase64Url(input: string): Uint8Array {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (normalized.length % 4)) % 4);
  const decoded = atob(`${normalized}${padding}`);
  return Uint8Array.from(decoded, (char) => char.charCodeAt(0));
}

function parseTtlSeconds(raw: string | undefined): number {
  const parsed = Number.parseInt(raw ?? "300", 10);
  if (!Number.isFinite(parsed)) return 300;
  if (parsed < 60) return 60;
  if (parsed > 3600) return 3600;
  return parsed;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "GET" && req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const supabasePublishableKey =
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY")?.trim();
    const supabaseAnonKey =
      supabasePublishableKey ??
      Deno.env.get("SUPABASE_ANON_KEY")?.trim();
    if (!supabaseAnonKey) {
      throw new Error(
        "Missing SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) environment variable",
      );
    }

    const powersyncUrl =
      Deno.env.get("POWERSYNC_URL")?.trim() ??
      Deno.env.get("POWERSYNC_JWT_AUDIENCE")?.trim();
    if (!powersyncUrl) {
      throw new Error(
        "Missing POWERSYNC_URL (or POWERSYNC_JWT_AUDIENCE) environment variable",
      );
    }

    const secretB64Url = requiredEnv("POWERSYNC_JWT_SECRET_BASE64URL");
    const jwtKid = Deno.env.get("POWERSYNC_JWT_KID")?.trim() ?? "";
    const jwtIssuer = Deno.env.get("POWERSYNC_JWT_ISSUER")?.trim() ??
      `${supabaseUrl}/functions/v1/powersync-token`;
    const ttlSeconds = parseTtlSeconds(
      Deno.env.get("POWERSYNC_JWT_TTL_SECONDS")?.trim(),
    );

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const user = userData.user;
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    const role = typeof profile?.role === "string" && profile.role.length > 0
      ? profile.role
      : "guest";

    const nowSeconds = Math.floor(Date.now() / 1000);
    const expSeconds = nowSeconds + ttlSeconds;

    const jwtSecret = decodeBase64Url(secretB64Url);
    const signingKey = await crypto.subtle.importKey(
      "raw",
      jwtSecret,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );

    const protectedHeader: Record<string, string> = {
      alg: "HS256",
      typ: "JWT",
    };
    if (jwtKid.length > 0) {
      protectedHeader.kid = jwtKid;
    }

    const token = await new SignJWT({ role })
      .setProtectedHeader(protectedHeader)
      .setSubject(user.id)
      .setIssuer(jwtIssuer)
      .setAudience(powersyncUrl)
      .setIssuedAt(nowSeconds)
      .setExpirationTime(expSeconds)
      .sign(signingKey);

    return jsonResponse({
      token,
      user_id: user.id,
      role,
      expires_at: expSeconds,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return jsonResponse({ error: message }, 500);
  }
});
