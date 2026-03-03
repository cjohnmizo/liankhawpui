# Supabase Edge Functions

## Functions
- `powersync-token`: issues short-lived PowerSync JWT for the signed-in user.
- `send-notification`: sends push notifications through OneSignal (editor/admin only).

## Deploy
```bash
supabase functions deploy powersync-token
supabase functions deploy send-notification
```

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
    "title": "Village Update",
    "message": "Community meeting at 7 PM.",
    "external_user_ids": ["<supabase-user-id>"]
  }'
```
