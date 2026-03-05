import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function sanitizeStringArray(input: unknown): string[] {
  if (!Array.isArray(input)) return [];
  return input
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function hasOneSignalErrors(payload: unknown): boolean {
  if (!payload || typeof payload !== "object") return false;
  const record = payload as Record<string, unknown>;
  const errors = record.errors;

  if (Array.isArray(errors)) return errors.length > 0;
  if (typeof errors === "string") return errors.trim().length > 0;
  if (errors && typeof errors === "object") {
    return Object.keys(errors as Record<string, unknown>).length > 0;
  }
  return false;
}

type NotifyBody = {
  title?: string;
  message?: string;
  external_user_ids?: string[];
  include_subscription_ids?: string[];
  included_segments?: string[];
  data?: Record<string, unknown>;
  url?: string;
  idempotency_key?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
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

    const oneSignalAppId = requiredEnv("ONESIGNAL_APP_ID");
    const oneSignalRestApiKey = requiredEnv("ONESIGNAL_REST_API_KEY");

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();

    const role = typeof profile?.role === "string" ? profile.role : "guest";
    if (role !== "editor" && role !== "admin") {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const body = (await req.json()) as NotifyBody;
    const title = body.title?.trim() || "Liankhawpui";
    const message = body.message?.trim();
    const idempotencyKey = body.idempotency_key?.trim();

    if (!message) {
      return jsonResponse({ error: "Field `message` is required." }, 400);
    }

    const externalUserIds = sanitizeStringArray(body.external_user_ids);
    const includeSubscriptionIds = sanitizeStringArray(
      body.include_subscription_ids,
    );
    const includedSegments = sanitizeStringArray(body.included_segments);

    if (
      externalUserIds.length == 0 &&
      includeSubscriptionIds.length == 0 &&
      includedSegments.length == 0
    ) {
      return jsonResponse(
        {
          error:
            "Provide `external_user_ids`, `include_subscription_ids`, or `included_segments` for recipient targeting.",
        },
        400,
      );
    }

    const payload: Record<string, unknown> = {
      app_id: oneSignalAppId,
      target_channel: "push",
      headings: { en: title },
      contents: { en: message },
      data: body.data ?? {},
      // Use app-branded Android icons instead of OneSignal default bell.
      small_icon: "ic_stat_onesignal_default",
      large_icon: "ic_onesignal_large_icon_default",
    };

    if (body.url && body.url.trim().length > 0) {
      payload.url = body.url.trim();
    }
    if (idempotencyKey && idempotencyKey.length > 0) {
      payload.idempotency_key = idempotencyKey;
    }

    if (includeSubscriptionIds.length > 0) {
      payload.include_subscription_ids = includeSubscriptionIds;
    } else if (externalUserIds.length > 0) {
      payload.include_aliases = {
        external_id: externalUserIds,
      };
    } else {
      payload.included_segments = includedSegments;
    }

    const oneSignalResponse = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${oneSignalRestApiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const responseBody = await oneSignalResponse.text();
    let parsedResponse: unknown = null;
    try {
      parsedResponse = JSON.parse(responseBody);
    } catch (_) {
      parsedResponse = null;
    }

    if (!oneSignalResponse.ok) {
      return jsonResponse(
        {
          error: "OneSignal request failed.",
          status: oneSignalResponse.status,
          response: parsedResponse ?? responseBody,
        },
        502,
      );
    }

    if (hasOneSignalErrors(parsedResponse)) {
      return jsonResponse(
        {
          error: "OneSignal accepted request with delivery errors.",
          status: oneSignalResponse.status,
          response: parsedResponse,
        },
        502,
      );
    }

    return jsonResponse({
      status: "sent",
      response: parsedResponse ?? responseBody,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return jsonResponse({ error: message }, 500);
  }
});
