import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';

class DashboardStats {
  final int totalUsers;
  final int totalAnnouncements;
  final int totalNews;
  final int totalOrganizations;
  final int pendingUserCount;

  DashboardStats({
    required this.totalUsers,
    required this.totalAnnouncements,
    required this.totalNews,
    required this.totalOrganizations,
    required this.pendingUserCount,
  });
}

class DashboardRepository {
  final _db = PowerSyncService().db;

  Future<DashboardStats> getStats() async {
    final usersRow = await _db.get('SELECT count(*) as count FROM profiles');
    final pendingUsersRow = await _db.get(
      "SELECT count(*) as count FROM profiles WHERE role = 'guest'",
    );
    final announcementsRow = await _db.get(
      'SELECT count(*) as count FROM announcements',
    );
    final newsRow = await _db.get('SELECT count(*) as count FROM news');
    final organizationsRow = await _db.get(
      'SELECT count(*) as count FROM organizations',
    );

    return DashboardStats(
      totalUsers: usersRow['count'] as int,
      totalAnnouncements: announcementsRow['count'] as int,
      totalNews: newsRow['count'] as int,
      totalOrganizations: organizationsRow['count'] as int,
      pendingUserCount: pendingUsersRow['count'] as int,
    );
  }

  Stream<List<AppUser>> watchAllProfiles() {
    return _db.watch('SELECT * FROM profiles').map((rows) {
      // Debug logging
      // for (var row in rows) {
      //   print('Profile: ${row['email']}, Role: ${row['role']}');
      // }
      return rows.map((row) {
        return AppUser(
          id: row['id'] as String,
          email: row['email'] as String?,
          role: UserRole.fromString(row['role'] as String?),
          fullName: row['full_name'] as String?,
          phoneNumber: row['phone_number'] as String?,
          dob: row['dob'] != null
              ? DateTime.tryParse(row['dob'] as String)
              : null,
          address: row['address'] as String?,
        );
      }).toList();
    });
  }

  Future<void> createUser({
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    final uuid = await _db.get('SELECT uuid() as id');
    final id = uuid['id'] as String;

    await _db.execute(
      'INSERT INTO profiles (id, email, full_name, role) VALUES (?, ?, ?, ?)',
      [id, email, fullName, role.name],
    );
  }

  Future<void> deleteUser(String userId) async {
    await _db.execute('DELETE FROM profiles WHERE id = ?', [userId]);
  }

  Future<void> approveUser(String userId) async {
    await updateUserRole(userId, UserRole.user);
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    await _db.execute('UPDATE profiles SET role = ? WHERE id = ?', [
      role.name,
      userId,
    ]);
  }
}
