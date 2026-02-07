import 'package:liankhawpui/features/auth/domain/user_role.dart';

class AppUser {
  final String id;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final DateTime? dob;
  final String? address;
  final String? photoUrl;
  final UserRole role;

  const AppUser({
    required this.id,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.dob,
    this.address,
    this.photoUrl,
    this.role = UserRole.guest,
  });

  bool get isGuest => role == UserRole.guest;

  static const AppUser guest = AppUser(id: 'guest', role: UserRole.guest);
}
