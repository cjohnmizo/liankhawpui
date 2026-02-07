class Announcement {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  factory Announcement.fromRow(Map<String, dynamic> row) {
    return Announcement(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      imageUrl: row['image_url'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      isPinned: (row['is_pinned'] as int? ?? 0) == 1,
    );
  }
}
