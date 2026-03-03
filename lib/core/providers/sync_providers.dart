import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:powersync/powersync.dart';

final powerSyncServiceProvider = Provider<PowerSyncService>((ref) {
  return PowerSyncService();
});

final powerSyncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(powerSyncServiceProvider);
  return service.statusStream;
});

final uploadQueueStatsProvider = StreamProvider<UploadQueueStats>((ref) {
  final service = ref.watch(powerSyncServiceProvider);
  return service.watchUploadQueueStats();
});
