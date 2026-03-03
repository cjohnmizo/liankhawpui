import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/story/presentation/story_providers.dart';

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(allBooksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Khawlian Chanchin'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Text(
                      'No books found',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final count = width >= 1050
                        ? 4
                        : width >= 800
                        ? 3
                        : width >= 520
                        ? 2
                        : 1;

                    return GridView.builder(
                      itemCount: books.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return GlassCard(
                          padding: EdgeInsets.zero,
                          onTap: () => context.push('/book/${book.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: book.coverUrl == null
                                        ? const Icon(
                                            Icons.menu_book_rounded,
                                            size: 48,
                                            color: AppColors.textTertiary,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: book.coverUrl!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                                  Icons.broken_image_rounded,
                                                  color: AppColors.textTertiary,
                                                ),
                                          ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((book.author ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        book.author!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading books: $e')),
            ),
          ),
        ),
      ),
    );
  }
}
