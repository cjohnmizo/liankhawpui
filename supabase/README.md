# Supabase Backend Notes

## Security
- Keep `service_role` and OneSignal REST API keys on the server only.
- Do not embed server keys in Flutter app code or `.env` client files.
- Apply the baseline RLS script in [`supabase/sql/rls_policies.sql`](sql/rls_policies.sql).
- Apply migrations with `supabase db push` so storage policies and buckets stay in sync.

## Required Edge Function for PowerSync
The Flutter client calls an Edge Function named `powersync-token` (configurable by `POWERSYNC_TOKEN_FUNCTION`) and expects JSON:

```json
{ "token": "..." }
```

Use the function to mint a short-lived PowerSync JWT per authenticated user.
If the function is not yet deployed (or returns an invalid token), remote PowerSync sync will remain disconnected.

## Suggested Server Functions
1. `powersync-token`: returns signed PowerSync token.
2. `send-notification`: sends OneSignal push using server-side REST key.
3. `admin-users`: admin-only create/delete users and role updates using service role key.

Function source and deploy commands are in [`supabase/functions/README.md`](functions/README.md).

## Post Attachments Storage
- Image bucket: `post-attachments` (public read, staff write).
- Document bucket: `post-documents` (private bucket, signed URL access).
- App-side limits:
  - Image input guard: reject files over `15 MB` before optimization.
  - Document upload: max `5 MB` (`pdf`, `docx`, `xlsx`).
- Current app policy:
  - feed/list images should use thumbnails
  - full images are for detail screens
  - documents are opened with signed URLs, not public URLs
