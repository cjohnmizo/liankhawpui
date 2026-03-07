# Storage Media Paths

## Buckets used by app code
- `post-attachments`
- `post-documents`
- `avatars`

## Folder structure (inside `post-attachments`)
- `{userId}/post-images/{timestamp}_{uuid8}.{ext}`: full post images
- `{userId}/post-thumbs/{timestamp}_{uuid8}_thumb.{ext}`: list/feed thumbnails

## Folder structure (inside `post-documents`)
- `{userId}/{feature-folder}/{timestamp}_{uuid8}.{ext}`: document attachments
  - current feature folders used by UI: `news`, `announcements`

## Free-Plan Protection Rules
- Uploads are picker-only (gallery/camera/file picker). URL uploads are blocked.
- Input image guard: reject files over `15 MB` before processing.
- Input document guard: reject files over `5 MB`.
- Allowed document types: `PDF` (preferred), `DOCX`, `XLSX`.
- Upload preview is shown before image upload:
  - Original file size
  - Optimized full size
  - Optimized thumb size
  - Estimated stored total

## Optimized Target Sizes
- Post full image: `150-300 KB` (max width `1200`)
- Post thumbnail: `50-100 KB` (max width `600`)
- Story image: `200-400 KB` (`9:16`)
- Avatar: `30-80 KB` (`256x256`)
- NGO logo: `50-120 KB` (`512x512`)

Low data mode:
- Post full image: `80-150 KB` (max width `900`)
- Post thumbnail: `30-60 KB` (max width `450`)

## Access expectations
- Post images/thumbs are uploaded with public cache metadata and can be read with public URLs when bucket policy allows public reads.
- Documents are treated as private-by-default in app flows:
  - upload result stores `objectPath`
  - markdown stores `lpdoc://attachment?bucket=post-documents&path=...` pointer
  - app resolves/open via signed URL at runtime
  - legacy document links stored in `post-attachments` still resolve for backward compatibility
- Avatars are uploaded with timestamped file names under `avatars/{userId}/...` to avoid stale cache.

## Cache-Control policy in code
- Thumbnails: `public, max-age=31536000, immutable`
- Full images: `public, max-age=604800`
- Documents: `private, max-age=3600`
- Avatars: `public, max-age=604800`

## Budget Warnings in Editor UI
- `>= 80%` of 1GB: show warning banner (`Storage nearing limit`).
- `>= 95%` of 1GB: block new uploads and ask user to clean old attachments.

## Quick verification checklist
1. Upload image in news/announcement editor and confirm both `post-images` and `post-thumbs` objects exist.
2. Confirm feed/list cards load thumbnail-first and detail screens load full image.
3. Upload a document up to 5 MB and confirm markdown stores an `lpdoc://attachment` link with `bucket=post-documents`.
4. Open document link in detail page and confirm it launches via a signed URL.
