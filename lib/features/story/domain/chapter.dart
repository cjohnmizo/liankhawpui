class Chapter {
  final String id;
  final String bookId;
  final String title;
  final String content;
  final String? imageUrl;
  final int chapterNumber;
  final DateTime updatedAt;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.chapterNumber,
    required this.updatedAt,
  });

  factory Chapter.fromRow(Map<String, dynamic> row) {
    final chapterNumberRaw = row['chapter_number'];
    return Chapter(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      imageUrl: row['image_url'] as String?,
      chapterNumber: chapterNumberRaw is int
          ? chapterNumberRaw
          : (chapterNumberRaw as num).toInt(),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
