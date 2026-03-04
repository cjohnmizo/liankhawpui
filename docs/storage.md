# Storage Media Paths

## Buckets used by app code
- `post-attachments`
- `avatars`

## Folder structure (inside `post-attachments`)
- `{userId}/post-images/{timestamp}_{uuid8}.{ext}`: full post images
- `{userId}/post-thumbs/{timestamp}_{uuid8}_thumb.{ext}`: list/feed thumbnails
- `{userId}/{feature-folder}/{timestamp}_{uuid8}.{ext}`: document attachments
  - current feature folders used by UI: `news`, `announcements`

## Access expectations
- Post images/thumbs are uploaded with public cache metadata and can be read with public URLs when bucket policy allows public reads.
- Documents are treated as private-by-default in app flows:
  - upload result stores `objectPath`
  - markdown stores `lpdoc://attachment?...` pointer
  - app resolves/open via signed URL at runtime
- Avatars are uploaded with timestamped file names under `avatars/{userId}/...` to avoid stale cache.

## Cache-Control policy in code
- Thumbnails: `public, max-age=31536000, immutable`
- Full images: `public, max-age=604800`
- Documents: `private, max-age=3600`
- Avatars: `public, max-age=604800`

## Quick verification checklist
1. Upload image in news/announcement editor and confirm both `post-images` and `post-thumbs` objects exist.
2. Confirm feed/list card loads fast (thumb URL) and detail view can render full image.
3. Upload a document up to 5 MB and confirm markdown stores `lpdoc://attachment` link.
4. Open document link in detail page and confirm it launches via a signed URL.
