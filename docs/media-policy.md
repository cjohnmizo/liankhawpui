# Media Upload Policy

Uploads are picker-only.

- Allowed: local file selection (gallery, camera, file picker), then upload to storage.
- Not allowed: pasting/importing image or file URLs for upload.
- Do not add URL upload fields such as `imageUrl`, `coverUrl`, `remoteUrl`, or similar in create/update request models.

## Legacy Data Compatibility

- Some existing rows may still contain legacy URL fields from older versions.
- These values are read-only fallback for display and must not be written by create/update flows.
- Display precedence for posts: `thumbUrl ?? coverUrl ?? legacyImageUrl`.

## Contributor Note

If you touch post create/update code:

1. Keep storage uploads picker-only.
2. Ignore any legacy image URL input on writes and keep debug logs for accidental callers.
3. Do not reintroduce URL import UI or URL-based upload service methods.
