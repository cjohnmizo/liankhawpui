import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/news/data/news_repository.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/domain/news_comment.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository();
});

// Stream of published news for general users
final newsStreamProvider = StreamProvider<List<News>>((ref) {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.watchNews();
});

// Stream of all news (drafts + published) for admin
final allNewsStreamProvider = StreamProvider<List<News>>((ref) {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.watchAllNews();
});

final newsDetailsProvider = StreamProvider.family<News?, String>((ref, newsId) {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.watchNewsById(newsId);
});

final newsCommentsProvider = StreamProvider.family<List<NewsComment>, String>((
  ref,
  newsId,
) {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.watchCommentsByNewsId(newsId);
});
