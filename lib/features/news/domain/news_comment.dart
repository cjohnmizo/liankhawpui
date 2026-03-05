class NewsComment {
  final String id;
  final String newsId;
  final String userId;
  final String? authorName;
  final String content;
  final DateTime createdAt;

  const NewsComment({
    required this.id,
    required this.newsId,
    required this.userId,
    this.authorName,
    required this.content,
    required this.createdAt,
  });

  String get displayAuthor {
    final name = authorName?.trim();
    if (name == null || name.isEmpty) {
      return 'Community member';
    }
    return name;
  }

  factory NewsComment.fromRow(Map<String, dynamic> row) {
    final createdAtRaw = row['created_at'];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    return NewsComment(
      id: row['id'] as String,
      newsId: row['news_id'] as String,
      userId: row['user_id'] as String,
      authorName: row['author_name'] as String?,
      content: row['content'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
