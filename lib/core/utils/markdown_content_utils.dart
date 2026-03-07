String markdownToPlainText(String value) {
  var output = value;

  output = output.replaceAll(
    RegExp(r'^\s*:::justify\s*$', multiLine: true),
    ' ',
  );
  output = output.replaceAll(RegExp(r'^\s*:::\s*$', multiLine: true), ' ');

  // Images: ![alt](url) -> alt
  output = output.replaceAllMapped(
    RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'),
    (match) => match.group(1)?.trim() ?? '',
  );

  // Links: [text](url) -> text
  output = output.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (match) => match.group(1)?.trim() ?? '',
  );

  // Remove markdown control symbols.
  output = output.replaceAll(RegExp(r'(^|\s)[#>*`~-]+'), ' ');
  output = output.replaceAll('**', '');
  output = output.replaceAll('*', '');
  output = output.replaceAll('_', '');

  // Normalize whitespace.
  output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
  return output;
}

String markdownExcerpt(String value, {int maxLength = 140}) {
  final plain = markdownToPlainText(value);
  if (plain.length <= maxLength) return plain;
  return '${plain.substring(0, maxLength - 3)}...';
}

String? firstMarkdownImageUrl(String value) {
  final match = RegExp(r'!\[[^\]]*\]\(([^)\s]+)').firstMatch(value);
  final raw = match?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

bool isRenderableImageUrl(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.startsWith('http://') || normalized.startsWith('https://');
}

String? resolveDisplayImageUrl({
  String? thumbUrl,
  String? coverUrl,
  String? legacyImageUrl,
}) {
  for (final candidate in [thumbUrl, coverUrl, legacyImageUrl]) {
    final normalized = candidate?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String? resolveListImageUrl({
  String? thumbUrl,
  String? coverUrl,
  String? legacyImageUrl,
}) {
  final directThumb = _normalizeUrl(thumbUrl);
  if (directThumb != null) return directThumb;

  final cover = _normalizeUrl(coverUrl);
  if (cover != null) {
    final derivedThumb = deriveThumbnailUrlFromFull(cover);
    return derivedThumb ?? cover;
  }

  final legacy = _normalizeUrl(legacyImageUrl);
  if (legacy != null) {
    final derivedThumb = deriveThumbnailUrlFromFull(legacy);
    return derivedThumb ?? legacy;
  }

  return null;
}

String? resolveDetailImageUrl({
  String? thumbUrl,
  String? coverUrl,
  String? legacyImageUrl,
}) {
  final cover = _normalizeUrl(coverUrl);
  if (cover != null) {
    final full = deriveFullImageUrlFromThumb(cover);
    return full ?? cover;
  }

  final thumb = _normalizeUrl(thumbUrl);
  if (thumb != null) {
    final full = deriveFullImageUrlFromThumb(thumb);
    return full ?? thumb;
  }

  final legacy = _normalizeUrl(legacyImageUrl);
  if (legacy != null) {
    final full = deriveFullImageUrlFromThumb(legacy);
    return full ?? legacy;
  }

  return null;
}

String? deriveThumbnailUrlFromFull(String? imageUrl) {
  final normalized = _normalizeUrl(imageUrl);
  if (normalized == null) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.pathSegments.isEmpty) return null;

  final segments = List<String>.from(uri.pathSegments);
  final index = segments.indexOf('post-images');
  if (index == -1) return null;

  final currentName = segments.last;
  if (currentName.contains('_thumb.')) {
    return uri.toString();
  }
  final dot = currentName.lastIndexOf('.');
  final thumbName = dot > 0
      ? '${currentName.substring(0, dot)}_thumb${currentName.substring(dot)}'
      : '${currentName}_thumb';
  segments[index] = 'post-thumbs';
  segments[segments.length - 1] = thumbName;
  return uri.replace(pathSegments: segments).toString();
}

String? deriveFullImageUrlFromThumb(String? imageUrl) {
  final normalized = _normalizeUrl(imageUrl);
  if (normalized == null) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.pathSegments.isEmpty) return null;

  final segments = List<String>.from(uri.pathSegments);
  final index = segments.indexOf('post-thumbs');
  if (index == -1) return null;

  final currentName = segments.last;
  final fullName = currentName.replaceFirst('_thumb.', '.');
  segments[index] = 'post-images';
  segments[segments.length - 1] = fullName;
  return uri.replace(pathSegments: segments).toString();
}

String? _normalizeUrl(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

class MarkdownAttachmentLink {
  final String label;
  final String href;

  const MarkdownAttachmentLink({required this.label, required this.href});
}

List<MarkdownAttachmentLink> extractMarkdownAttachmentLinks(String value) {
  final matches = RegExp(
    r'(?<!!)\[([^\]]+)\]\(([^)\s]+)\)',
    multiLine: true,
  ).allMatches(value);

  return matches
      .map(
        (match) => MarkdownAttachmentLink(
          label: (match.group(1) ?? '').trim(),
          href: (match.group(2) ?? '').trim(),
        ),
      )
      .where((item) => item.label.isNotEmpty && item.href.isNotEmpty)
      .toList(growable: false);
}
