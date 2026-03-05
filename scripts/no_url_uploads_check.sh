#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FAILURES=0

UI_PATTERNS=(
  "Image URL"
  "Paste link"
  "Upload via URL"
  "Import from link"
  "Add via URL"
)

FUNCTION_PATTERNS=(
  "uploadFromUrl"
  "uploadImageFromUrl"
  "importFromUrl"
  "downloadAndUpload"
  "remoteImageUpload"
)

WRITE_FIELD_REGEX='\b(imageUrl|coverUrl|remoteUrl)\b'
WRITE_FIELD_ALLOWLIST=(
  "lib/features/news/domain/news.dart"
  "lib/features/announcement/domain/announcement.dart"
  "lib/features/news/presentation/news_list_screen.dart"
  "lib/features/news/presentation/news_detail_screen.dart"
  "lib/features/news/presentation/news_edit_screen.dart"
  "lib/features/announcement/presentation/widgets/announcement_card.dart"
  "lib/features/announcement/presentation/announcement_detail_screen.dart"
  "lib/features/news/data/news_repository.dart"
  "lib/features/announcement/data/announcement_repository.dart"
)

is_allowlisted_file() {
  local file="$1"
  for allowed in "${WRITE_FIELD_ALLOWLIST[@]}"; do
    if [[ "$file" == "$allowed" ]]; then
      return 0
    fi
  done
  return 1
}

report_match() {
  local category="$1"
  local pattern="$2"
  local match_line="$3"
  echo "[$category] pattern=\"$pattern\" -> $match_line"
}

scan_literal_patterns() {
  local category="$1"
  shift
  local pattern
  for pattern in "$@"; do
    local matches
    matches="$(grep -RIn --binary-files=without-match -F -- "$pattern" lib || true)"
    if [[ -n "$matches" ]]; then
      while IFS= read -r line; do
        report_match "$category" "$pattern" "$line"
      done <<<"$matches"
      FAILURES=1
    fi
  done
}

scan_literal_patterns "UI" "${UI_PATTERNS[@]}"
scan_literal_patterns "FUNCTION" "${FUNCTION_PATTERNS[@]}"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  file="${line%%:*}"
  rest="${line#*:}"
  line_no="${rest%%:*}"
  line_text="${rest#*:}"

  if is_allowlisted_file "$file"; then
    continue
  fi

  if echo "$line_text" | grep -qiE '(^|[^a-z])(read|response|legacy)([^a-z]|$)'; then
    continue
  fi

  matched_field="$(echo "$line_text" | grep -oE "$WRITE_FIELD_REGEX" | head -n1 || true)"
  if [[ -z "$matched_field" ]]; then
    continue
  fi

  report_match "WRITE-FIELD" "$matched_field" "$file:$line_no:$line_text"
  FAILURES=1
done < <(
  grep -RIn --binary-files=without-match -E "$WRITE_FIELD_REGEX" \
    lib/features/news lib/features/announcement || true
)

if [[ "$FAILURES" -ne 0 ]]; then
  echo "no_url_uploads_check: FAILED"
  exit 1
fi

echo "no_url_uploads_check: PASSED"
