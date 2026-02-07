class Book {
  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? description;

  const Book({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.description,
  });

  factory Book.fromRow(Map<String, dynamic> row) {
    return Book(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String?,
      coverUrl: row['cover_url'] as String?,
      description: row['description'] as String?,
    );
  }
}
