import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';
import 'package:liankhawpui/features/story/presentation/story_providers.dart';

class BookListScreen extends ConsumerWidget {
  final bool embedded;

  const BookListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final bookAsync = ref.watch(singleBookProvider);
    final chaptersAsync = ref.watch(bookChaptersProvider);

    final content = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(singleBookProvider);
        ref.invalidate(bookChaptersProvider);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: bookAsync.when(
              data: (book) => chaptersAsync.when(
                data: (chapters) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _BookHeroCard(
                        title: book.title,
                        author: book.author,
                        coverUrl: book.coverUrl,
                        description: book.description,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Chapters',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${chapters.length}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (chapters.isEmpty)
                        const AppEmptyState(
                          message: 'No chapters available yet',
                          icon: Icons.menu_book_rounded,
                        )
                      else
                        for (final chapter in chapters)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChapterTile(
                              chapter: chapter,
                              onTap: () =>
                                  context.push('/book/chapter/${chapter.id}'),
                            ),
                          ),
                      if (user.role.isEditor) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Admins and editors can manage chapters from the Manage button.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () =>
                    const AppLoadingState(message: 'Loading chapters...'),
                error: (e, _) =>
                    Center(child: Text('Error loading chapters: $e')),
              ),
              loading: () => const AppLoadingState(message: 'Loading book...'),
              error: (e, _) => Center(child: Text('Error loading book: $e')),
            ),
          ),
        ),
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Khawlian Chanchin'),
        actions: [
          if (user.role.isEditor)
            TextButton.icon(
              onPressed: () => context.push('/book/manage'),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Manage'),
            ),
        ],
      ),
      body: content,
    );
  }
}

class _BookHeroCard extends StatelessWidget {
  final String title;
  final String? author;
  final String? coverUrl;
  final String? description;

  const _BookHeroCard({
    required this.title,
    this.author,
    this.coverUrl,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((author ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'By $author',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if ((description ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          );

          final cover = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: isNarrow ? double.infinity : 180,
              height: isNarrow ? 180 : 250,
              child: coverUrl == null
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 56,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : AdaptiveCachedImage(
                      imageUrl: coverUrl!,
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
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
            ),
          );

          if (isNarrow) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [cover, const SizedBox(height: 12), content],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cover,
                const SizedBox(width: 14),
                Expanded(child: content),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            child: Text(
              '${chapter.chapterNumber}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((chapter.imageUrl ?? '').isNotEmpty)
                    Text(
                      'Includes image',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
