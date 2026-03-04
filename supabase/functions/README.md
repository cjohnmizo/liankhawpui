# Supabase Edge Functions

## Functions
- `powersync-token`: issues short-lived PowerSync JWT for the signed-in user.
- `send-notification`: sends push notifications through OneSignal (editor/admin only, supports optional `idempotency_key`).
- `admin-users`: admin-only user lifecycle operations (create user, update role, delete user).

## Announcement Push Flow
- Announcements are written locally first and uploaded by PowerSync.
- After an `announcements` create operation reaches Supabase, the app calls `send-notification` server-side.
- The call uses `included_segments: ["Active Subscriptions"]` and `idempotency_key: "<announcement-id-uuid>"` to avoid duplicates during retry.

## Deploy
```bash
supabase functions deploy powersync-token --no-verify-jwt
supabase functions deploy send-notification --no-verify-jwt
supabase functions deploy admin-users
```

`powersync-token` performs user validation inside the function (`auth.getUser()`),
so it should be deployed with `--no-verify-jwt` to avoid gateway JWT
verification conflicts with modern Supabase access token formats.
`send-notification` follows the same pattern (`auth.getUser()` + role checks),
and should also be deployed with `--no-verify-jwt` for the same reason.

## Required Secrets
Set once per project:

```bash
supabase secrets set SUPABASE_URL=...
supabase secrets set SUPABASE_ANON_KEY=...
supabase secrets set POWERSYNC_URL=...
supabase secrets set POWERSYNC_JWT_SECRET_BASE64URL=...
supabase secrets set POWERSYNC_JWT_KID=...
supabase secrets set POWERSYNC_JWT_ISSUER=...
supabase secrets set POWERSYNC_JWT_TTL_SECONDS=300
supabase secrets set ONESIGNAL_APP_ID=...
supabase secrets set ONESIGNAL_REST_API_KEY=...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
```

## Invocation examples
`powersync-token` (authenticated request):

```bash
curl -X POST \
  "$SUPABASE_URL/functions/v1/powersync-token" \
  -H "Authorization: Bearer <user_access_token>"
```

`send-notification` (editor/admin only):

```bash
curl -X POST \
  "$SUPABASE_URL/functions/v1/send-notification" \
  -H "Authorization: Bearer <user_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Announcement",
    "message": "Community meeting at 7 PM.",
    "included_segments": ["Active Subscriptions"],
    "idempotency_key": "<announcement-id-uuid>",
    "data": {
      "type": "announcement",
      "announcement_id": "<announcement-id>"
    }
  }'
```

`send-notification` direct subscription targeting:

```bash
curl -X POST \
  "$SUPABASE_URL/functions/v1/send-notification" \
  -H "Authorization: Bearer <user_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Device Test",
    "message": "Push directly to one device subscription.",
    "include_subscription_ids": ["<onesignal-subscription-id>"]
  }'
```

`admin-users` (admin only):

```bash
curl -X POST \
  "$SUPABASE_URL/functions/v1/admin-users" \
  -H "Authorization: Bearer <admin_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create_user",
    "email": "new.user@example.com",
    "password": "TempPass123",
    "full_name": "New User",
    "role": "user"
  }'
```
