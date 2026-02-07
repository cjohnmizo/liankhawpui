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

  Future<void> createNews({
    required String title,
    required String content,
    required String category,
    String? imageUrl,
    String? userId,
    bool isPublished = true,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''
      INSERT INTO news (id, title, content, image_url, category, created_by, created_at, is_published)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        title,
        content,
        imageUrl,
        category,
        userId,
        now,
        isPublished ? 1 : 0,
      ],
    );
  }

  Future<void> updateNews({
    required String id,
    String? title,
    String? content,
    String? category,
    String? imageUrl,
    bool? isPublished,
  }) async {
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
    if (imageUrl != null) {
      updates.add('image_url = ?');
      args.add(imageUrl);
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
}
