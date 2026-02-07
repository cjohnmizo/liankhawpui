import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/story/data/story_repository.dart';
import 'package:liankhawpui/features/story/domain/book.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

final allBooksProvider = FutureProvider<List<Book>>((ref) {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getAllBooks();
});

final bookChaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  bookId,
) {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getChapters(bookId);
});

final chapterDetailsProvider = FutureProvider.family<Chapter?, String>((
  ref,
  chapterId,
) {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getChapter(chapterId);
});
