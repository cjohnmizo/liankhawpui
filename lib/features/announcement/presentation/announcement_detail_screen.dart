import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(announcementDetailsProvider(announcementId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Announcement'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: detailAsync.when(
              data: (announcement) {
                if (announcement == null) {
                  return const Center(child: Text('Announcement not found'));
                }

                return ListView(
                  children: [
                    if ((announcement.imageUrl ?? '').isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: AdaptiveCachedImage(
                            imageUrl: announcement.imageUrl!,
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
                          if (announcement.isPinned)
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: AppColors.accentGold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pinned update',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.accentGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            announcement.title,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.accentGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat.yMMMMd().add_jm().format(
                                  announcement.createdAt,
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
                          MarkdownBody(
                            data: announcement.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: AppTextStyles.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.7,
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
}
