import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';
import 'package:liankhawpui/features/story/presentation/story_providers.dart';

class ChapterReaderScreen extends ConsumerStatefulWidget {
  final String chapterId;

  const ChapterReaderScreen({super.key, required this.chapterId});

  @override
  ConsumerState<ChapterReaderScreen> createState() =>
      _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends ConsumerState<ChapterReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  double _progress = 0;
  String? _recordedChapterId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterDetailsProvider(widget.chapterId));
    final chaptersAsync = ref.watch(bookChaptersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/book'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Read Story'),
      ),
      body: chapterAsync.when(
        data: (chapter) {
          if (chapter == null) {
            return const AppEmptyState(
              message: 'Chapter not found',
              icon: Icons.menu_book_rounded,
            );
          }
          _recordLastRead(chapter);

          return Column(
            children: [
              LinearProgressIndicator(value: _progress.clamp(0, 1)),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: ListView(
                        controller: _scrollController,
                        children: [
                          Text(
                            chapter.title,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          chaptersAsync.when(
                            data: (chapters) {
                              final index = chapters.indexWhere(
                                (item) => item.id == chapter.id,
                              );
                              if (index < 0) return const SizedBox.shrink();
                              return Text(
                                'Chapter ${index + 1} of ${chapters.length}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          if ((chapter.imageUrl ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 220,
                                child: AdaptiveCachedImage(
                                  imageUrl: chapter.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (_) => Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                                  ),
                                  errorBuilder: (_) => Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          GlassCard(
                            child: MarkdownBody(
                              data: chapter.content,
                              styleSheet:
                                  MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(height: 1.7, fontSize: 17),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: chaptersAsync.when(
                  data: (chapters) =>
                      _ChapterPagination(chapters: chapters, chapter: chapter),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(message: 'Loading chapter...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (maxScroll <= 0) {
      if (_progress != 1) {
        setState(() => _progress = 1);
      }
      return;
    }
    final next = (current / maxScroll).clamp(0.0, 1.0);
    if ((next - _progress).abs() >= 0.01) {
      setState(() => _progress = next);
    }
  }

  void _recordLastRead(Chapter chapter) {
    if (_recordedChapterId == chapter.id) return;
    _recordedChapterId = chapter.id;
    ref
        .read(lastReadChapterProvider.notifier)
        .setLastReadChapter(chapterId: chapter.id, chapterTitle: chapter.title);
  }
}

class _ChapterPagination extends StatelessWidget {
  final List<Chapter> chapters;
  final Chapter chapter;

  const _ChapterPagination({required this.chapters, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final index = chapters.indexWhere((item) => item.id == chapter.id);
    if (index < 0) return const SizedBox.shrink();
    final previous = index > 0 ? chapters[index - 1] : null;
    final next = index < chapters.length - 1 ? chapters[index + 1] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: previous == null
                  ? null
                  : () => context.go('/book/chapter/${previous.id}'),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: next == null
                  ? null
                  : () => context.go('/book/chapter/${next.id}'),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
