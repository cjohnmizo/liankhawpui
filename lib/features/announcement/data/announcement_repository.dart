import 'package:flutter/foundation.dart';
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

  Stream<Announcement?> watchAnnouncementById(String id) {
    return _db
        .watch(
          'SELECT * FROM announcements WHERE id = ? LIMIT 1',
          parameters: [id],
        )
        .map((results) {
          if (results.isEmpty) return null;
          return Announcement.fromRow(results.first);
        });
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    bool isPinned = false,
    String? legacyImageUrl,
    String? userId,
  }) async {
    _logIgnoredLegacyImageUrl(legacyImageUrl);
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''
      INSERT INTO announcements (id, title, content, created_by, created_at, updated_at, is_pinned)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, title, content, userId, now, now, isPinned ? 1 : 0],
    );
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    bool isPinned = false,
    String? legacyImageUrl,
  }) async {
    _logIgnoredLegacyImageUrl(legacyImageUrl);
    final now = DateTime.now().toIso8601String();
    await _db.execute(
      '''
      UPDATE announcements
      SET title = ?, content = ?, is_pinned = ?, updated_at = ?
      WHERE id = ?
      ''',
      [title, content, isPinned ? 1 : 0, now, id],
    );
  }

  Future<Announcement?> getAnnouncementById(String id) async {
    final row = await _db.getOptional(
      'SELECT * FROM announcements WHERE id = ? LIMIT 1',
      [id],
    );
    if (row == null) return null;
    return Announcement.fromRow(row);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.execute('DELETE FROM announcements WHERE id = ?', [id]);
  }

  void _logIgnoredLegacyImageUrl(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      debugPrint('Ignoring legacy imageUrl: URL uploads disabled');
    }
  }
}
