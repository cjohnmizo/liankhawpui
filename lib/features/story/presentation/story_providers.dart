import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/story/data/story_repository.dart';
import 'package:liankhawpui/features/story/domain/book.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

final singleBookProvider = FutureProvider<Book>((ref) {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getOrCreateSingleBook();
});

final bookChaptersProvider = FutureProvider<List<Chapter>>((ref) async {
  final repo = ref.watch(storyRepositoryProvider);
  final book = await ref.watch(singleBookProvider.future);
  return repo.getChapters(book.id);
});

final chapterDetailsProvider = FutureProvider.family<Chapter?, String>((
  ref,
  chapterId,
) {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getChapter(chapterId);
});
