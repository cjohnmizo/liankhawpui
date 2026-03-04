import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/story/domain/chapter.dart';
import 'package:liankhawpui/features/story/presentation/story_providers.dart';

class StoryManageScreen extends ConsumerStatefulWidget {
  const StoryManageScreen({super.key});

  @override
  ConsumerState<StoryManageScreen> createState() => _StoryManageScreenState();
}

class _StoryManageScreenState extends ConsumerState<StoryManageScreen> {
  final _bookFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _attachmentService = PostAttachmentService();

  String? _bookId;
  bool _bookInitialized = false;
  bool _savingBook = false;
  bool _uploadingBookCover = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _coverUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_bookFormKey.currentState!.validate() || _bookId == null) {
      return;
    }

    setState(() => _savingBook = true);
    try {
      final repo = ref.read(storyRepositoryProvider);
      await repo.updateBook(
        id: _bookId!,
        title: _titleController.text.trim(),
        author: _normalize(_authorController.text),
        coverUrl: _normalize(_coverUrlController.text),
        description: _normalize(_descriptionController.text),
      );

      ref.invalidate(singleBookProvider);
      ref.invalidate(bookChaptersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book details updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update book: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingBook = false);
      }
    }
  }

  Future<void> _openChapterEditor({
    Chapter? chapter,
    required int suggestedChapterNumber,
  }) async {
    final lowDataMode = ref.read(lowDataModeEnabledProvider);
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController(
      text: '${chapter?.chapterNumber ?? suggestedChapterNumber}',
    );
    final titleController = TextEditingController(text: chapter?.title ?? '');
    final contentController = TextEditingController(
      text: chapter?.content ?? '',
    );
    var chapterImageUrl = chapter?.imageUrl;
    var isUploadingImage = false;
    var isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(chapter == null ? 'Add Chapter' : 'Edit Chapter'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: numberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Chapter Number',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse((value ?? '').trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isUploadingImage
                                    ? null
                                    : () async {
                                        setDialogState(
                                          () => isUploadingImage = true,
                                        );
                                        try {
                                          final result =
                                              await _attachmentService
                                                  .pickCompressAndUploadImage(
                                                    folder: 'book-chapters',
                                                    lowDataMode: lowDataMode,
                                                  );
                                          if (result != null) {
                                            setDialogState(() {
                                              chapterImageUrl =
                                                  result.publicUrl;
                                            });
                                          }
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Image upload failed: $e',
                                              ),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        } finally {
                                          if (context.mounted) {
                                            setDialogState(
                                              () => isUploadingImage = false,
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.image_rounded),
                                label: const Text('Pick Chapter Image'),
                              ),
                            ),
                            if ((chapterImageUrl ?? '').isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: isUploadingImage
                                    ? null
                                    : () {
                                        setDialogState(
                                          () => chapterImageUrl = null,
                                        );
                                      },
                                child: const Text('Remove'),
                              ),
                            ],
                          ],
                        ),
                        if (isUploadingImage) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                        ] else if ((chapterImageUrl ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Text('Chapter image selected from device'),
                        ],
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: contentController,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            labelText: 'Content (Markdown supported)',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Content is required';
                            }
                            return null;
                          },
                        ),
                        if (isSaving) ...[
                          const SizedBox(height: 14),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => context.pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (_bookId == null) return;

                          setDialogState(() => isSaving = true);
                          try {
                            final repo = ref.read(storyRepositoryProvider);
                            final chapterNumber = int.parse(
                              numberController.text.trim(),
                            );
                            if (chapter == null) {
                              await repo.createChapter(
                                bookId: _bookId!,
                                title: titleController.text.trim(),
                                content: contentController.text.trim(),
                                imageUrl: chapterImageUrl,
                                chapterNumber: chapterNumber,
                              );
                            } else {
                              await repo.updateChapter(
                                id: chapter.id,
                                title: titleController.text.trim(),
                                content: contentController.text.trim(),
                                imageUrl: chapterImageUrl,
                                chapterNumber: chapterNumber,
                              );
                            }
                            if (!context.mounted) return;
                            context.pop(true);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save chapter: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: Text(chapter == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    numberController.dispose();
    titleController.dispose();
    contentController.dispose();

    if (result == true) {
      ref.invalidate(bookChaptersProvider);
    }
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chapter?'),
        content: Text('This will permanently remove "${chapter.title}".'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(storyRepositoryProvider).deleteChapter(chapter.id);
      ref.invalidate(bookChaptersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chapter deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chapter: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _normalize(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickBookCover() async {
    if (_savingBook || _uploadingBookCover) return;
    setState(() => _uploadingBookCover = true);
    final lowDataMode = ref.read(lowDataModeEnabledProvider);

    try {
      final result = await _attachmentService.pickCompressAndUploadImage(
        folder: 'book-covers',
        lowDataMode: lowDataMode,
      );
      if (result == null || !mounted) return;
      setState(() => _coverUrlController.text = result.publicUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book cover selected from device')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload cover image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingBookCover = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(singleBookProvider);
    final chaptersAsync = ref.watch(bookChaptersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/book'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Manage Khawlian Chanchin'),
        actions: [
          TextButton(
            onPressed: _savingBook ? null : _saveBook,
            child: const Text('Save Book'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: bookAsync.when(
              data: (book) {
                if (!_bookInitialized) {
                  _bookInitialized = true;
                  _bookId = book.id;
                  _titleController.text = book.title;
                  _authorController.text = book.author ?? '';
                  _coverUrlController.text = book.coverUrl ?? '';
                  _descriptionController.text = book.description ?? '';
                }

                return ListView(
                  children: [
                    Form(
                      key: _bookFormKey,
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book Details',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Book Title',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Book title is required'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _authorController,
                              decoration: const InputDecoration(
                                labelText: 'Author (Optional)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _uploadingBookCover || _savingBook
                                        ? null
                                        : _pickBookCover,
                                    icon: const Icon(
                                      Icons.photo_library_rounded,
                                    ),
                                    label: const Text('Pick Cover Image'),
                                  ),
                                ),
                                if (_coverUrlController.text
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed:
                                        _uploadingBookCover || _savingBook
                                        ? null
                                        : () {
                                            setState(() {
                                              _coverUrlController.clear();
                                            });
                                          },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ],
                            ),
                            if (_uploadingBookCover) ...[
                              const SizedBox(height: 8),
                              const LinearProgressIndicator(),
                            ] else if (_coverUrlController.text
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text('Cover image selected from device'),
                            ],
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Description (Optional)',
                                alignLabelWithHint: true,
                              ),
                            ),
                            if (_savingBook) ...[
                              const SizedBox(height: 12),
                              const Center(child: CircularProgressIndicator()),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chapters',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              final chapters = chaptersAsync.value ?? const [];
                              final nextNumber = chapters.isEmpty
                                  ? 1
                                  : chapters.last.chapterNumber + 1;
                              await _openChapterEditor(
                                suggestedChapterNumber: nextNumber,
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Chapter'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    chaptersAsync.when(
                      data: (chapters) {
                        if (chapters.isEmpty) {
                          return const GlassCard(
                            child: Text(
                              'No chapters yet. Create the first chapter.',
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final chapter in chapters)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.accentGold
                                            .withValues(alpha: 0.14),
                                        child: Text(
                                          '${chapter.chapterNumber}',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.accentGold,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chapter.title,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if ((chapter.imageUrl ?? '')
                                                .isNotEmpty)
                                              Text(
                                                'Has chapter image',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit chapter',
                                        onPressed: () => _openChapterEditor(
                                          chapter: chapter,
                                          suggestedChapterNumber:
                                              chapter.chapterNumber,
                                        ),
                                        icon: const Icon(Icons.edit_rounded),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete chapter',
                                        onPressed: () =>
                                            _deleteChapter(chapter),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) =>
                          GlassCard(child: Text('Failed to load chapters: $e')),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load book: $e')),
            ),
          ),
        ),
      ),
    );
  }
}
