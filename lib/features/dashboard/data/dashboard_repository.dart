import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';
import 'package:powersync/powersync.dart';

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
  final _client = SupabaseService.client;

  PowerSyncDatabase? get _dbOrNull {
    final service = PowerSyncService();
    if (!service.isInitialized) return null;
    return service.db;
  }

  Future<DashboardStats> getStats() async {
    final db = _dbOrNull;
    if (db != null) {
      try {
        final usersRow = await db.get('SELECT count(*) as count FROM profiles');
        final pendingUsersRow = await db.get(
          "SELECT count(*) as count FROM profiles WHERE role = 'guest'",
        );
        final announcementsRow = await db.get(
          'SELECT count(*) as count FROM announcements',
        );
        final newsRow = await db.get('SELECT count(*) as count FROM news');
        final organizationsRow = await db.get(
          'SELECT count(*) as count FROM organizations',
        );

        return DashboardStats(
          totalUsers: usersRow['count'] as int,
          totalAnnouncements: announcementsRow['count'] as int,
          totalNews: newsRow['count'] as int,
          totalOrganizations: organizationsRow['count'] as int,
          pendingUserCount: pendingUsersRow['count'] as int,
        );
      } catch (_) {
        // Fall through to Supabase fallback if local DB is not ready.
      }
    }

    return _getStatsFromSupabase();
  }

  Stream<List<AppUser>> watchAllProfiles() {
    final db = _dbOrNull;
    if (db != null) {
      try {
        return db.watch('SELECT * FROM profiles ORDER BY email ASC').map(
          _mapProfiles,
        );
      } catch (_) {
        // Fall through to Supabase fallback stream.
      }
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('email')
        .map(_mapProfiles);
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

  Future<DashboardStats> _getStatsFromSupabase() async {
    final results = await Future.wait<int>([
      _safeCount('profiles'),
      _safeCount('announcements'),
      _safeCount('news'),
      _safeCount('organizations'),
      _safePendingUserCount(),
    ]);

    return DashboardStats(
      totalUsers: results[0],
      totalAnnouncements: results[1],
      totalNews: results[2],
      totalOrganizations: results[3],
      pendingUserCount: results[4],
    );
  }

  Future<int> _safeCount(String table) async {
    try {
      return await _client.from(table).count();
    } catch (_) {
      return 0;
    }
  }

  Future<int> _safePendingUserCount() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'guest');
      return rows.length;
    } catch (_) {
      // ignored
    }
    return 0;
  }

  List<AppUser> _mapProfiles(List<dynamic> rows) {
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      return AppUser(
        id: data['id'] as String,
        email: data['email'] as String?,
        role: UserRole.fromString(data['role'] as String?),
        fullName: data['full_name'] as String?,
        phoneNumber: data['phone_number'] as String?,
        dob: data['dob'] != null
            ? DateTime.tryParse(data['dob'].toString())
            : null,
        address: data['address'] as String?,
      );
    }).toList();
  }
}
