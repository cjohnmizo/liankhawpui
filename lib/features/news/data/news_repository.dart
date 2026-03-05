import 'package:flutter/foundation.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/domain/news_comment.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class NewsRepository {
  final _powerSync = PowerSyncService();
  final _uuid = const Uuid();

  Future<PowerSyncDatabase> _ensureDb() async {
    await _powerSync.ensureLocalDatabaseReady();
    return _powerSync.db;
  }

  Stream<List<News>> watchNews() async* {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (error) {
      debugPrint('watchNews failed to initialize local DB: $error');
      yield const <News>[];
      return;
    }
    yield* db
        .watch(
          'SELECT * FROM news WHERE is_published = 1 ORDER BY created_at DESC',
        )
        .map((results) => results.map((row) => News.fromRow(row)).toList())
        .handleError((error) {
          debugPrint('watchNews stream error: $error');
        });
  }

  // Admin/Editor view (sees all)
  Stream<List<News>> watchAllNews() async* {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (error) {
      debugPrint('watchAllNews failed to initialize local DB: $error');
      yield const <News>[];
      return;
    }
    yield* db
        .watch('SELECT * FROM news ORDER BY created_at DESC')
        .map((results) => results.map((row) => News.fromRow(row)).toList())
        .handleError((error) {
          debugPrint('watchAllNews stream error: $error');
        });
  }

  Stream<News?> watchNewsById(String id) async* {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (error) {
      debugPrint('watchNewsById failed to initialize local DB: $error');
      yield null;
      return;
    }
    yield* db
        .watch('SELECT * FROM news WHERE id = ? LIMIT 1', parameters: [id])
        .map((results) {
          if (results.isEmpty) return null;
          return News.fromRow(results.first);
        })
        .handleError((error) {
          debugPrint('watchNewsById stream error: $error');
        });
  }

  Stream<List<NewsComment>> watchCommentsByNewsId(String newsId) async* {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (error) {
      debugPrint('watchCommentsByNewsId failed to initialize local DB: $error');
      yield const <NewsComment>[];
      return;
    }
    yield* db
        .watch(
          'SELECT * FROM news_comments WHERE news_id = ? ORDER BY created_at DESC',
          parameters: [newsId],
        )
        .map(
          (results) => results.map((row) => NewsComment.fromRow(row)).toList(),
        )
        .handleError((error) {
          debugPrint('watchCommentsByNewsId stream error: $error');
        });
  }

  Future<News?> getNewsById(String id) async {
    final db = await _ensureDb();
    final row = await db.getOptional(
      'SELECT * FROM news WHERE id = ? LIMIT 1',
      [id],
    );
    if (row == null) return null;
    return News.fromRow(row);
  }

  Future<void> createNews({
    required String title,
    required String content,
    required String category,
    String? legacyImageUrl,
    String? userId,
    bool isPublished = true,
  }) async {
    _logIgnoredLegacyImageUrl(legacyImageUrl);
    final db = await _ensureDb();
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      '''
      INSERT INTO news (id, title, content, category, created_by, created_at, is_published)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, title, content, category, userId, now, isPublished ? 1 : 0],
    );
  }

  Future<void> updateNews({
    required String id,
    String? title,
    String? content,
    String? category,
    String? legacyImageUrl,
    bool? isPublished,
  }) async {
    _logIgnoredLegacyImageUrl(legacyImageUrl);
    final updates = <String>[];
    final args = <dynamic>[];

    if (title != null) {
      updates.add('title = ?');
      args.add(title);
    }
    if (content != null) {
      updates.add('content = ?');
      args.add(content);
    }
    if (category != null) {
      updates.add('category = ?');
      args.add(category);
    }
    if (isPublished != null) {
      updates.add('is_published = ?');
      args.add(isPublished ? 1 : 0);
    }

    if (updates.isEmpty) return;

    args.add(id); // ID for WHERE clause

    final db = await _ensureDb();
    await db.execute(
      'UPDATE news SET ${updates.join(', ')} WHERE id = ?',
      args,
    );
  }

  Future<void> deleteNews(String id) async {
    final db = await _ensureDb();
    await db.execute('DELETE FROM news WHERE id = ?', [id]);
  }

  Future<void> addComment({
    required String newsId,
    required String userId,
    required String content,
    String? authorName,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Comment cannot be empty.');
    }
    if (normalized.length > 800) {
      throw ArgumentError('Comment is too long. Keep it under 800 characters.');
    }

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final normalizedAuthor = authorName?.trim();

    final db = await _ensureDb();
    await db.execute(
      '''
      INSERT INTO news_comments (id, news_id, user_id, author_name, content, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        newsId,
        userId,
        (normalizedAuthor == null || normalizedAuthor.isEmpty)
            ? null
            : normalizedAuthor,
        normalized,
        now,
      ],
    );
  }

  void _logIgnoredLegacyImageUrl(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      debugPrint('Ignoring legacy imageUrl: URL uploads disabled');
    }
  }
}
