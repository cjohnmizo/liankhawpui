import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/auth/data/auth_repository.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AppUser>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final currentUserProvider = Provider<AppUser>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value ?? AppUser.guest;
});
