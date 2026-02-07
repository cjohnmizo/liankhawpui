class Chapter {
  final String id;
  final String bookId;
  final String title;
  final String content;
  final int chapterNumber;
  final DateTime updatedAt;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    required this.chapterNumber,
    required this.updatedAt,
  });

  factory Chapter.fromRow(Map<String, dynamic> row) {
    return Chapter(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      chapterNumber: row['chapter_number'] as int,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
