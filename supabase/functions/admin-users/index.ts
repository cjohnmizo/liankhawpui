import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type AdminAction = "create_user" | "update_role" | "delete_user";

type AdminBody = {
  action?: AdminAction;
  email?: string;
  password?: string;
  full_name?: string;
  role?: string;
  user_id?: string;
  hard_delete?: boolean;
};

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function normalizedRole(input: unknown): string | null {
  if (typeof input !== "string") return null;
  const role = input.trim().toLowerCase();
  if (!["guest", "user", "editor", "admin"].includes(role)) {
    return null;
  }
  return role;
}

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
    const supabaseAnonKey =
      Deno.env.get("SUPABASE_ANON_KEY")?.trim() ??
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY")?.trim();
    if (!supabaseAnonKey) {
      throw new Error(
        "Missing SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY) environment variable",
      );
    }
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");

    // Client tied to caller JWT for authorization checks.
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const callerId = userData.user.id;
    const { data: callerProfile, error: callerProfileError } = await userClient
      .from("profiles")
      .select("role")
      .eq("id", callerId)
      .maybeSingle();

    if (callerProfileError) {
      return jsonResponse({ error: "Failed to validate caller role." }, 403);
    }

    const callerRole = normalizedRole(callerProfile?.role);
    if (callerRole !== "admin") {
      return jsonResponse({ error: "Forbidden. Admin role required." }, 403);
    }

    // Service role client executes privileged operations.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const body = (await req.json()) as AdminBody;
    const action = body.action;

    if (!action) {
      return jsonResponse({ error: "Field `action` is required." }, 400);
    }

    if (action === "create_user") {
      const email = body.email?.trim().toLowerCase();
      const password = body.password?.trim();
      const fullName = body.full_name?.trim();
      const role = normalizedRole(body.role);

      if (!email || !password || !fullName || !role) {
        return jsonResponse(
          {
            error:
              "Fields `email`, `password`, `full_name`, and valid `role` are required.",
          },
          400,
        );
      }

      if (password.length < 6) {
        return jsonResponse(
          { error: "Password must be at least 6 characters." },
          400,
        );
      }

      const { data: created, error: createError } = await adminClient.auth.admin
        .createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: {
            full_name: fullName,
            role,
          },
        });

      if (createError || !created.user) {
        return jsonResponse(
          { error: createError?.message ?? "Failed to create auth user." },
          400,
        );
      }

      const userId = created.user.id;
      const { error: profileError } = await adminClient.from("profiles").upsert({
        id: userId,
        email,
        full_name: fullName,
        role,
      });

      if (profileError) {
        await adminClient.auth.admin.deleteUser(userId, true);
        return jsonResponse(
          { error: `Failed to create profile: ${profileError.message}` },
          400,
        );
      }

      return jsonResponse({
        status: "created",
        user: {
          id: userId,
          email,
          full_name: fullName,
          role,
        },
      });
    }

    if (action === "update_role") {
      const userId = body.user_id?.trim();
      const role = normalizedRole(body.role);

      if (!userId || !role) {
        return jsonResponse(
          { error: "Fields `user_id` and valid `role` are required." },
          400,
        );
      }

      const { error: profileError } = await adminClient
        .from("profiles")
        .update({ role })
        .eq("id", userId);
      if (profileError) {
        return jsonResponse(
          { error: `Failed to update profile role: ${profileError.message}` },
          400,
        );
      }

      await adminClient.auth.admin.updateUserById(userId, {
        user_metadata: { role },
      });

      return jsonResponse({
        status: "updated",
        user_id: userId,
        role,
      });
    }

    if (action === "delete_user") {
      const userId = body.user_id?.trim();
      const hardDelete = body.hard_delete ?? true;
      if (!userId) {
        return jsonResponse({ error: "Field `user_id` is required." }, 400);
      }

      if (userId === callerId) {
        return jsonResponse(
          { error: "Admin cannot delete their own account from this endpoint." },
          400,
        );
      }

      const { error: deleteError } = await adminClient.auth.admin.deleteUser(
        userId,
        hardDelete,
      );

      if (deleteError) {
        return jsonResponse(
          { error: `Failed to delete user: ${deleteError.message}` },
          400,
        );
      }

      return jsonResponse({
        status: "deleted",
        user_id: userId,
      });
    }

    return jsonResponse({ error: "Unknown action." }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return jsonResponse({ error: message }, 500);
  }
});
