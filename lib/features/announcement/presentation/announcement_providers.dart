import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/announcement/data/announcement_repository.dart';
import 'package:liankhawpui/features/announcement/domain/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.watchAnnouncements();
});
