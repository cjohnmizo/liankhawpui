import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/announcement/domain/announcement.dart';
import 'package:uuid/uuid.dart';

class AnnouncementRepository {
  final _db = PowerSyncService().db;
  final _uuid = const Uuid();

  Stream<List<Announcement>> watchAnnouncements() {
    return _db
        .watch(
          'SELECT * FROM announcements ORDER BY is_pinned DESC, created_at DESC',
        )
        .map((results) {
          return results.map((row) => Announcement.fromRow(row)).toList();
        });
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    String? imageUrl,
    String? userId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''
      INSERT INTO announcements (id, title, content, image_url, created_by, created_at, updated_at, is_pinned)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, title, content, imageUrl, userId, now, now, 0],
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.execute('DELETE FROM announcements WHERE id = ?', [id]);
  }
}
