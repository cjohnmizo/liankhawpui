import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/story/domain/book.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';
import 'package:uuid/uuid.dart';

class StoryRepository {
  final _db = PowerSyncService().db;
  final _uuid = const Uuid();

  Future<List<Book>> getAllBooks() async {
    final results = await _db.getAll('SELECT * FROM books ORDER BY title ASC');
    return results.map((row) => Book.fromRow(row)).toList();
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    final results = await _db.getAll(
      'SELECT * FROM chapters WHERE book_id = ? ORDER BY chapter_number ASC',
      [bookId],
    );
    return results.map((row) => Chapter.fromRow(row)).toList();
  }

  Future<Chapter?> getChapter(String chapterId) async {
    final result = await _db.getOptional(
      'SELECT * FROM chapters WHERE id = ?',
      [chapterId],
    );
    if (result == null) return null;
    return Chapter.fromRow(result);
  }

  Future<void> createBook({
    required String title,
    String? author,
    String? coverUrl,
    String? description,
  }) async {
    final id = _uuid.v4();
    await _db.execute(
      'INSERT INTO books (id, title, author, cover_url, description) VALUES (?, ?, ?, ?, ?)',
      [id, title, author, coverUrl, description],
    );
  }

  Future<void> createChapter({
    required String bookId,
    required String title,
    required String content,
    required int chapterNumber,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await _db.execute(
      '''
      INSERT INTO chapters (id, book_id, title, content, chapter_number, updated_at) 
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [id, bookId, title, content, chapterNumber, now],
    );
  }
}
