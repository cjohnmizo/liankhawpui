import 'dart:async';
import 'dart:typed_data';

import 'package:liankhawpui/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:liankhawpui/core/services/onesignal_service.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  Stream<AppUser> get authStateChanges async* {
    yield await getCurrentUser();

    yield* _client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) {
        await OneSignalService.syncExternalUserId(null);
        return AppUser.guest;
      }

      await _ensureProfileExists(
        session.user,
        fallbackEmail: session.user.email ?? '${session.user.id}@oauth.local',
      );
      await OneSignalService.syncExternalUserId(session.user.id);
      return _mapUserWithProfile(session.user);
    });
  }

  // Synchronous snapshot for immediate UI usage while streams are loading.
  AppUser get currentUserSnapshot {
    final user = _client.auth.currentUser;
    if (user == null) return AppUser.guest;
    return _mapUser(user);
  }

  Future<AppUser> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      await OneSignalService.syncExternalUserId(null);
      return AppUser.guest;
    }

    await _ensureProfileExists(
      user,
      fallbackEmail: user.email ?? '${user.id}@oauth.local',
    );
    await OneSignalService.syncExternalUserId(user.id);
    return _mapUserWithProfile(user);
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await _client.auth
        .signInWithPassword(email: email, password: password)
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () =>
              throw TimeoutException('Authentication request timed out'),
        );

    // Self-healing: Ensure profile exists
    final user = response.user;
    if (user != null) {
      await _ensureProfileExists(user, fallbackEmail: email);
      await OneSignalService.syncExternalUserId(user.id);
    }
  }

  Future<void> signInWithGoogle() async {
    final redirectTo = EnvConfig.googleOAuthRedirectUrl;
    final launched = await _client.auth
        .signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo.isEmpty ? null : redirectTo,
          authScreenLaunchMode: LaunchMode.externalApplication,
        )
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () =>
              throw TimeoutException('Google authentication timed out'),
        );

    if (!launched) {
      throw StateError('Could not start Google sign-in flow.');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );

    final user = response.user;
    if (user != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'full_name': data?['full_name'],
        'phone_number': data?['phone_number'],
        'dob': data?['dob']?.split('T')[0], // Extract YYYY-MM-DD
        'address': data?['address'],
        'role': 'guest',
      });

      if (response.session != null) {
        await OneSignalService.syncExternalUserId(user.id);
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await OneSignalService.syncExternalUserId(null);
  }

  AppUser _mapUser(User user, {Map<String, dynamic>? profile}) {
    final meta = user.userMetadata ?? {};
    final roleStr =
        _asString(profile?['role']) ??
        _asString(user.appMetadata['role']) ??
        _asString(meta['role']);
    final dobRaw = _asString(profile?['dob']) ?? _asString(meta['dob']);

    return AppUser(
      id: user.id,
      email: user.email ?? _asString(profile?['email']),
      role: UserRole.fromString(roleStr),
      fullName:
          _asString(profile?['full_name']) ??
          _asString(meta['full_name']) ??
          _asString(meta['name']),
      phoneNumber:
          _asString(profile?['phone_number']) ??
          _asString(meta['phone_number']),
      dob: dobRaw != null ? DateTime.tryParse(dobRaw) : null,
      address: _asString(profile?['address']) ?? _asString(meta['address']),
      photoUrl:
          _asString(profile?['photo_url']) ??
          _asString(profile?['avatar_url']) ??
          _asString(meta['photo_url']) ??
          _asString(meta['avatar_url']) ??
          _asString(meta['picture']),
    );
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? dob,
    String? address,
  }) async {
    final attributes = UserAttributes(
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (dob != null) 'dob': dob.toIso8601String().split('T')[0],
        if (address != null) 'address': address,
      },
    );

    await _client.auth.updateUser(attributes);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('profiles')
        .update({
          if (fullName != null) 'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (dob != null) 'dob': dob.toIso8601String().split('T')[0],
          if (address != null) 'address': address,
        })
        .eq('id', userId);
  }

  /// Upload profile photo to Supabase storage
  /// Returns the public URL of the uploaded photo
  Future<String> uploadProfilePhoto(Uint8List imageData) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be authenticated to upload profile photos.');
    }

    final avatarFolder = userId;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$avatarFolder/avatar_$timestamp.jpg';

    // Delete old photos for this user to avoid stale cache pointers.
    try {
      final existing = await _client.storage
          .from('avatars')
          .list(path: avatarFolder);
      final existingPaths = existing
          .map((item) => item.name)
          .where((name) => name.isNotEmpty)
          .map((name) => '$avatarFolder/$name')
          .toList();
      if (existingPaths.isNotEmpty) {
        await _client.storage.from('avatars').remove(existingPaths);
      }
    } catch (e) {
      // Ignore cleanup failures and continue with upload.
    }

    // Upload new photo
    await _client.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          imageData,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
            cacheControl: 'public, max-age=604800',
          ),
        );

    // Get public URL
    final photoUrl = _client.storage.from('avatars').getPublicUrl(fileName);

    // Update user metadata
    await _client.auth.updateUser(
      UserAttributes(data: {'photo_url': photoUrl}),
    );

    // Also update profiles table
    await _client
        .from('profiles')
        .update({'photo_url': photoUrl, 'avatar_url': photoUrl})
        .eq('id', userId);

    return photoUrl;
  }

  Future<AppUser> _mapUserWithProfile(User user) async {
    final profile = await _fetchProfile(user.id);
    return _mapUser(user, profile: profile);
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final result = await _client
          .from('profiles')
          .select(
            'id, email, full_name, phone_number, dob, address, role, photo_url, avatar_url',
          )
          .eq('id', userId)
          .maybeSingle();

      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureProfileExists(
    User user, {
    required String fallbackEmail,
  }) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) return;

      final meta = user.userMetadata ?? {};
      await _client.from('profiles').insert({
        'id': user.id,
        'email': user.email ?? fallbackEmail,
        'full_name': _asString(meta['full_name']) ?? _asString(meta['name']),
        'phone_number': _asString(meta['phone_number']),
        'dob': _asString(meta['dob'])?.split('T').first,
        'address': _asString(meta['address']),
        'photo_url':
            _asString(meta['photo_url']) ??
            _asString(meta['avatar_url']) ??
            _asString(meta['picture']),
        'avatar_url':
            _asString(meta['avatar_url']) ?? _asString(meta['picture']),
        'role': 'guest',
      });
    } catch (_) {
      // Keep auth flow resilient if profile bootstrap fails.
    }
  }

  String? _asString(dynamic value) {
    if (value is String) return value;
    return null;
  }
}
