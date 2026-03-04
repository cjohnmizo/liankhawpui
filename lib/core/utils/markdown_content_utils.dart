String markdownToPlainText(String value) {
  var output = value;

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
