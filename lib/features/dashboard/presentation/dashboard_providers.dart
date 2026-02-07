import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/dashboard/data/dashboard_repository.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getStats();
});

final allProfilesProvider = StreamProvider<List<AppUser>>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.watchAllProfiles();
});
