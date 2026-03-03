import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
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
  final _client = SupabaseService.client;

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
    return _db.watch('SELECT * FROM profiles ORDER BY email ASC').map((rows) {
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
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty ||
        normalizedName.isEmpty ||
        normalizedPassword.length < 6) {
      throw Exception('Invalid user data. Check email/name/password values.');
    }

    final response = await _client.functions.invoke(
      'admin-users',
      body: {
        'action': 'create_user',
        'email': normalizedEmail,
        'password': normalizedPassword,
        'full_name': normalizedName,
        'role': role.name,
      },
    );

    _ensureFunctionSuccess(response.data, fallback: 'Failed to create user.');
  }

  Future<void> deleteUser(String userId) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {'action': 'delete_user', 'user_id': userId, 'hard_delete': true},
    );
    _ensureFunctionSuccess(response.data, fallback: 'Failed to delete user.');
  }

  Future<void> approveUser(String userId) async {
    await updateUserRole(userId, UserRole.user);
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {'action': 'update_role', 'user_id': userId, 'role': role.name},
    );
    _ensureFunctionSuccess(
      response.data,
      fallback: 'Failed to update user role.',
    );
  }

  void _ensureFunctionSuccess(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        throw Exception(error);
      }
      return;
    }

    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      final error = mapped['error'];
      if (error is String && error.trim().isNotEmpty) {
        throw Exception(error);
      }
      return;
    }

    throw Exception(fallback);
  }
}
