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
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/domain/news_comment.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(newsDetailsProvider(widget.newsId));
    final commentsAsync = ref.watch(newsCommentsProvider(widget.newsId));
    final user = ref.watch(currentUserProvider);

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
                    const SizedBox(height: 12),
                    _CommentsSection(
                      user: user,
                      commentsAsync: commentsAsync,
                      controller: _commentController,
                      isSubmitting: _isSubmittingComment,
                      onSubmit: () => _submitComment(user),
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

  Future<void> _submitComment(AppUser user) async {
    if (!user.role.isUser || _isSubmittingComment) return;
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      await ref
          .read(newsRepositoryProvider)
          .addComment(
            newsId: widget.newsId,
            userId: user.id,
            content: message,
            authorName: _resolveAuthorName(user),
          );
      _commentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment posted')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not post comment: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  String? _resolveAuthorName(AppUser user) {
    final fullName = user.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email.split('@').first;
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

class _CommentsSection extends StatelessWidget {
  final AppUser user;
  final AsyncValue<List<NewsComment>> commentsAsync;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _CommentsSection({
    required this.user,
    required this.commentsAsync,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (user.role.isUser) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isSubmitting,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Sign in to comment on this news post.'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return Text(
                  'No comments yet. Be the first to comment.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _CommentTile(comment: comments[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(
              'Could not load comments: $error',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final NewsComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comment.displayAuthor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                DateFormat.yMMMd().add_jm().format(comment.createdAt),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
