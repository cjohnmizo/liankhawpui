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
    return Announcement(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      legacyImageUrl: row['image_url'] as String?,
      coverUrl: row['cover_url'] as String?,
      thumbUrl: row['thumb_url'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      isPinned: (row['is_pinned'] as int? ?? 0) == 1,
    );
  }
}
