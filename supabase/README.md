# Supabase Backend Notes

## Security
- Keep `service_role` and OneSignal REST API keys on the server only.
- Do not embed server keys in Flutter app code or `.env` client files.
- Apply the baseline RLS script in [`supabase/sql/rls_policies.sql`](sql/rls_policies.sql).

## Required Edge Function for PowerSync
The Flutter client calls an Edge Function named `powersync-token` (configurable by `POWERSYNC_TOKEN_FUNCTION`) and expects JSON:

```json
{ "token": "..." }
```

Use the function to mint a short-lived PowerSync JWT per authenticated user.

## Suggested Server Functions
1. `powersync-token`: returns signed PowerSync token.
2. `send-notification`: sends OneSignal push using server-side REST key.

## Example Function Skeleton (TypeScript)
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  // TODO: create token by signing with POWERSYNC_JWT_SECRET
  const token = "replace-with-real-signed-token";
  return new Response(JSON.stringify({ token }), { status: 200 });
});
```
