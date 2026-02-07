import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  Stream<AppUser> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session == null) return AppUser.guest;

      return _mapUser(session.user);
    });
  }

  AppUser get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return AppUser.guest;
    return _mapUser(user);
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Self-healing: Ensure profile exists
    final user = response.user;
    if (user != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profile == null) {
          // Profile missing, create it from metadata
          final meta = user.userMetadata ?? {};
          await _client.from('profiles').insert({
            'id': user.id,
            'email': email,
            'full_name': meta['full_name'],
            'phone_number': meta['phone_number'],
            'dob': meta['dob'] != null
                ? (meta['dob'] as String).split('T')[0]
                : null,
            'address': meta['address'],
            'role': meta['role'] ?? 'guest',
          });
        }
      } catch (e) {
        // Ignore error during self-healing, main flow should succeed
        // debugPrint('Error checking/creating profile: $e');
      }
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
      // Manually create profile if trigger doesn't exist/work
      // Use upsert to handle cases where a trigger might have already created the profile
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'full_name': data?['full_name'],
        'phone_number': data?['phone_number'],
        'dob': data?['dob']?.split('T')[0], // Extract YYYY-MM-DD
        'address': data?['address'],
        'role': data?['role'] ?? 'guest',
      });

      // Explicitly try to enforce guest role in case upsert didn't overwrite it
      try {
        await _client
            .from('profiles')
            .update({'role': 'guest'})
            .eq('id', user.id);
      } catch (e) {
        // This might fail if RLS prevents users from updating their own role
        // We log it but don't fail the registration
        // debugPrint('Warning: Failed to enforcement guest role: $e');
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  AppUser _mapUser(User user) {
    final roleStr = user.appMetadata['role'] ?? user.userMetadata?['role'];
    final role = UserRole.fromString(roleStr as String?);

    final meta = user.userMetadata ?? {};

    return AppUser(
      id: user.id,
      email: user.email,
      role: role,
      fullName: meta['full_name'] as String?,
      phoneNumber: meta['phone_number'] as String?,
      dob: meta['dob'] != null
          ? DateTime.tryParse(meta['dob'] as String)
          : null,
      address: meta['address'] as String?,
      photoUrl: meta['photo_url'] as String?,
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

    // Also update the public.profiles table
    await _client
        .from('profiles')
        .update({
          if (fullName != null) 'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (dob != null) 'dob': dob.toIso8601String().split('T')[0],
          if (address != null) 'address': address,
        })
        .eq('id', _client.auth.currentUser!.id);
  }

  /// Upload profile photo to Supabase storage
  /// Returns the public URL of the uploaded photo
  Future<String> uploadProfilePhoto(Uint8List imageData) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = 'avatar_$userId.jpg';

    // Delete old photo if exists
    try {
      await _client.storage.from('avatars').remove([fileName]);
    } catch (e) {
      // Ignore error if file doesn't exist
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
        .update({'photo_url': photoUrl})
        .eq('id', userId);

    return photoUrl;
  }
}
