import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/story/presentation/story_providers.dart';

class ChapterReaderScreen extends ConsumerWidget {
  final String chapterId;
  const ChapterReaderScreen({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(chapterDetailsProvider(chapterId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Read Story'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: chapterAsync.when(
              data: (chapter) {
                if (chapter == null) {
                  return const Center(child: Text('Chapter not found'));
                }
                return ListView(
                  children: [
                    Text(
                      chapter.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: MarkdownBody(
                        data: chapter.content,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(height: 1.7),
                            ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ),
    );
  }
}
