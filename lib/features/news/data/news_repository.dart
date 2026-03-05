import 'package:flutter/foundation.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:uuid/uuid.dart';

class NewsRepository {
  final _db = PowerSyncService().db;
  final _uuid = const Uuid();

  Stream<List<News>> watchNews() {
    return _db
        .watch(
          'SELECT * FROM news WHERE is_published = 1 ORDER BY created_at DESC',
        )
        .map((results) {
          return results.map((row) => News.fromRow(row)).toList();
        });
  }

  // Admin/Editor view (sees all)
  Stream<List<News>> watchAllNews() {
    return _db.watch('SELECT * FROM news ORDER BY created_at DESC').map((
      results,
    ) {
      return results.map((row) => News.fromRow(row)).toList();
    });
  }

  Stream<News?> watchNewsById(String id) {
    return _db
        .watch('SELECT * FROM news WHERE id = ? LIMIT 1', parameters: [id])
        .map((results) {
          if (results.isEmpty) return null;
          return News.fromRow(results.first);
        });
  }

  Future<News?> getNewsById(String id) async {
    final row = await _db.getOptional(
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
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
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

    await _db.execute(
      'UPDATE news SET ${updates.join(', ')} WHERE id = ?',
      args,
    );
  }

  Future<void> deleteNews(String id) async {
    await _db.execute('DELETE FROM news WHERE id = ?', [id]);
  }

  void _logIgnoredLegacyImageUrl(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      debugPrint('Ignoring legacy imageUrl: URL uploads disabled');
    }
  }
}
