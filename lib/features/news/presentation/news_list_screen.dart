import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/localization/app_strings.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class NewsListScreen extends ConsumerWidget {
  final bool embedded;

  const NewsListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final newsAsync = ref.watch(newsStreamProvider);

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, embedded ? 8 : 12, 16, 16),
          child: newsAsync.when(
            data: (newsList) {
              if (newsList.isEmpty) {
                return AppEmptyState(
                  message: t.noNewsPublishedYet,
                  icon: Icons.article_outlined,
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1050
                      ? 3
                      : width >= 680
                      ? 2
                      : 1;
                  final childAspectRatio = width >= 1050 ? 0.95 : 0.9;

                  return GridView.builder(
                    itemCount: newsList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final news = newsList[index];
                      final displayImageUrl = resolveListImageUrl(
                        thumbUrl: news.thumbUrl,
                        coverUrl:
                            news.coverUrl ??
                            firstMarkdownImageUrl(news.content),
                        legacyImageUrl: news.legacyImageUrl,
                      );
                      final relativeTime = timeago.format(news.createdAt);
                      final preview = markdownExcerpt(
                        news.content,
                        maxLength: 100,
                      );

                      return GlassCard(
                        onTap: () => context.push('/news/${news.id}'),
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: displayImageUrl == null
                                    ? Container(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported_rounded,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      )
                                    : AdaptiveCachedImage(
                                        imageUrl: displayImageUrl,
                                        fit: BoxFit.cover,
                                        placeholderBuilder: (_) => Container(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                        ),
                                        errorBuilder: (_) => const Center(
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    news.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.accentGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    news.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    preview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '$relativeTime • ${DateFormat.yMMMd().format(news.createdAt)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            loading: () => AppLoadingState(message: t.loadingRecentNews),
            error: (_, __) => AppEmptyState(
              message: t.couldNotLoadRecentNews,
              icon: Icons.error_outline_rounded,
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
        title: Text(t.newsFeed),
      ),
      body: content,
    );
  }
}
