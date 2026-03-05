import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends ConsumerWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(newsDetailsProvider(newsId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('News Article'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: detailAsync.when(
              data: (news) {
                if (news == null) {
                  return const Center(child: Text('News article not found'));
                }
                final heroImageUrl = _resolveHeroImageUrl(news);
                final attachmentLinks = extractMarkdownAttachmentLinks(
                  news.content,
                );

                return ListView(
                  children: [
                    if (heroImageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: AdaptiveCachedImage(
                            imageUrl: heroImageUrl,
                            fit: BoxFit.cover,
                            placeholderBuilder: (_) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            errorBuilder: (_) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              news.category,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            news.title,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: AppColors.accentGold,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (news.createdBy ?? '').trim().isEmpty
                                      ? 'Community Desk'
                                      : news.createdBy!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.accentGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat.yMMMMd().add_jm().format(
                                  news.createdAt,
                                ),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (attachmentLinks.isNotEmpty) ...[
                            Text(
                              'Attachments',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final item in attachmentLinks)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  leading: const Icon(
                                    Icons.attach_file_rounded,
                                  ),
                                  title: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () async {
                                    final uri = await PostAttachmentService()
                                        .resolveLaunchUri(item.href);
                                    if (uri == null) return;
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                          MarkdownBody(
                            data: news.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 17,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.62,
                              ),
                            ),
                            onTapLink: (_, href, __) async {
                              if (href == null || href.isEmpty) return;
                              final uri = await PostAttachmentService()
                                  .resolveLaunchUri(href);
                              if (uri == null) return;
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveHeroImageUrl(News news) {
    final markdownImage = firstMarkdownImageUrl(news.content);
    return resolveDetailImageUrl(
      thumbUrl: news.thumbUrl,
      coverUrl: markdownImage ?? news.coverUrl,
      legacyImageUrl: news.legacyImageUrl,
    );
  }
}
