import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/story/domain/book.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class StoryRepository {
  static const String singletonBookId = '00000000-0000-0000-0000-000000000001';
  static const String defaultBookTitle = 'Khawlian Chanchin';

  final _powerSync = PowerSyncService();
  final _uuid = const Uuid();

  Future<PowerSyncDatabase> _ensureDb() async {
    await _powerSync.ensureLocalDatabaseReady();
    return _powerSync.db;
  }

  Future<Book?> getSingleBook() async {
    final db = await _ensureDb();
    final primary = await db.getOptional(
      'SELECT * FROM books WHERE id = ? LIMIT 1',
      [singletonBookId],
    );
    if (primary != null) {
      return Book.fromRow(primary);
    }

    final fallback = await db.getOptional(
      'SELECT * FROM books ORDER BY title ASC LIMIT 1',
    );
    if (fallback == null) {
      return null;
    }
    return Book.fromRow(fallback);
  }

  Future<Book> getOrCreateSingleBook() async {
    final existing = await getSingleBook();
    if (existing != null) {
      return existing;
    }

    final db = await _ensureDb();
    await db.execute(
      '''
      INSERT INTO books (id, title, author, cover_url, description)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        singletonBookId,
        defaultBookTitle,
        null,
        null,
        'History and souvenir of Khawlian Village',
      ],
    );

    final created = await getSingleBook();
    if (created == null) {
      throw StateError('Failed to create singleton book');
    }
    return created;
  }

  Future<void> updateBook({
    required String id,
    required String title,
    String? author,
    String? coverUrl,
    String? description,
  }) async {
    final db = await _ensureDb();
    await db.execute(
      '''
      UPDATE books
      SET title = ?, author = ?, cover_url = ?, description = ?
      WHERE id = ?
      ''',
      [title, author, coverUrl, description, id],
    );
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    final db = await _ensureDb();
    final results = await db.getAll(
      'SELECT * FROM chapters WHERE book_id = ? ORDER BY chapter_number ASC',
      [bookId],
    );
    return results.map((row) => Chapter.fromRow(row)).toList();
  }

  Future<Chapter?> getChapter(String chapterId) async {
    final db = await _ensureDb();
    final result = await db.getOptional('SELECT * FROM chapters WHERE id = ?', [
      chapterId,
    ]);
    if (result == null) return null;
    return Chapter.fromRow(result);
  }

  Future<void> createChapter({
    required String bookId,
    required String title,
    required String content,
    String? imageUrl,
    required int chapterNumber,
  }) async {
    final db = await _ensureDb();
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO chapters (id, book_id, title, content, image_url, chapter_number, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, bookId, title, content, imageUrl, chapterNumber, now],
    );
  }

  Future<void> updateChapter({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
    required int chapterNumber,
  }) async {
    final db = await _ensureDb();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE chapters
      SET title = ?, content = ?, image_url = ?, chapter_number = ?, updated_at = ?
      WHERE id = ?
      ''',
      [title, content, imageUrl, chapterNumber, now, id],
    );
  }

  Future<void> deleteChapter(String chapterId) async {
    final db = await _ensureDb();
    await db.execute('DELETE FROM chapters WHERE id = ?', [chapterId]);
  }
}
