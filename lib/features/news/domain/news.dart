import 'package:liankhawpui/core/utils/markdown_content_utils.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String? legacyImageUrl;
  final String? coverUrl;
  final String? thumbUrl;
  final String category; // 'sports', 'local', etc.
  final String? createdBy;
  final DateTime createdAt;
  final bool isPublished;

  const News({
    required this.id,
    required this.title,
    required this.content,
    this.legacyImageUrl,
    this.coverUrl,
    this.thumbUrl,
    required this.category,
    this.createdBy,
    required this.createdAt,
    this.isPublished = false,
  });

  String? get displayImageUrl => resolveListImageUrl(
    thumbUrl: thumbUrl,
    coverUrl: coverUrl,
    legacyImageUrl: legacyImageUrl,
  );

  factory News.fromRow(Map<String, dynamic> row) {
    return News(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      legacyImageUrl: row['image_url'] as String?,
      coverUrl: row['cover_url'] as String?,
      thumbUrl: row['thumb_url'] as String?,
      category: row['category'] as String,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      isPublished: (row['is_published'] as int? ?? 0) == 1,
    );
  }
}
