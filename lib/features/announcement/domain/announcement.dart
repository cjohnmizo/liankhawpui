import 'package:liankhawpui/core/utils/markdown_content_utils.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String? legacyImageUrl;
  final String? coverUrl;
  final String? thumbUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.legacyImageUrl,
    this.coverUrl,
    this.thumbUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  String? get displayImageUrl => resolveListImageUrl(
    thumbUrl: thumbUrl,
    coverUrl: coverUrl,
    legacyImageUrl: legacyImageUrl,
  );

  factory Announcement.fromRow(Map<String, dynamic> row) {
    final createdAtRaw = row['created_at'];
    final updatedAtRaw = row['updated_at'];

    return Announcement(
      id: row['id'].toString(),
      title: row['title']?.toString() ?? '',
      content: row['content']?.toString() ?? '',
      legacyImageUrl: row['image_url']?.toString(),
      coverUrl: row['cover_url']?.toString(),
      thumbUrl: row['thumb_url']?.toString(),
      createdBy: row['created_by']?.toString(),
      createdAt: _parseDateTime(createdAtRaw),
      updatedAt: _parseDateTime(updatedAtRaw),
      isPinned: _parseBool(row['is_pinned']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    return DateTime.now();
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == '1' || normalized == 'true' || normalized == 't') {
      return true;
    }
    return false;
  }
}
