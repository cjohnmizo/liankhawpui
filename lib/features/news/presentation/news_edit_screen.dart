import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/core/widgets/rich_markdown_editor.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';

class NewsEditScreen extends ConsumerStatefulWidget {
  final News? news;

  const NewsEditScreen({super.key, this.news});

  @override
  ConsumerState<NewsEditScreen> createState() => _NewsEditScreenState();
}

class _NewsEditScreenState extends ConsumerState<NewsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late String _selectedCategory;
  late bool _isPublished;
  bool _isLoading = false;
  bool _isUploadingAttachment = false;
  final _attachmentService = PostAttachmentService();
  final List<PostAttachmentUploadResult> _attachments =
      <PostAttachmentUploadResult>[];

  final List<String> _categories = [
    'General',
    'Sports',
    'Events',
    'Announcements',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.news?.title ?? '');
    _contentController = TextEditingController(
      text: widget.news?.content ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.news?.imageUrl ?? '',
    );
    _selectedCategory = widget.news?.category ?? 'General';
    _isPublished = widget.news?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Content is required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(newsRepositoryProvider);
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();

      if (widget.news != null) {
        await repo.updateNews(
          id: widget.news!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageUrl: imageUrl,
          isPublished: _isPublished,
        );
      } else {
        await repo.createNews(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageUrl: imageUrl,
          isPublished: _isPublished,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('News saved successfully')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving news: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _attachImage() async {
    if (_isUploadingAttachment || _isLoading) return;
    setState(() => _isUploadingAttachment = true);
    final lowDataMode = ref.read(lowDataModeEnabledProvider);

    try {
      final result = await _attachmentService.pickCompressAndUploadImage(
        folder: 'news',
        lowDataMode: lowDataMode,
      );
      if (result == null || !mounted) return;

      setState(() {
        _attachments.add(result);
        if (_imageUrlController.text.trim().isEmpty) {
          _imageUrlController.text = result.publicUrl;
        }
      });

      MarkdownEditing.insertText(
        _contentController,
        result.toMarkdown(),
        addLeadingBreak: true,
        addTrailingBreak: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image attached (${(result.sizeBytes / 1024).toStringAsFixed(1)} KB)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _attachDocument() async {
    if (_isUploadingAttachment || _isLoading) return;
    setState(() => _isUploadingAttachment = true);

    try {
      final result = await _attachmentService.pickAndUploadDocument(
        folder: 'news',
      );
      if (result == null || !mounted) return;

      setState(() => _attachments.add(result));
      MarkdownEditing.insertText(
        _contentController,
        result.toMarkdown(),
        addLeadingBreak: true,
        addTrailingBreak: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Document attached (${(result.sizeBytes / 1024).toStringAsFixed(1)} KB)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.news != null ? 'Edit News' : 'New Article';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _isLoading || _isUploadingAttachment ? null : _saveNews,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(context, 'Title'),
                  _fieldCard(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter article title',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 720;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _categoryField(context),
                            const SizedBox(height: 12),
                            _statusField(context),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _categoryField(context)),
                          const SizedBox(width: 12),
                          Expanded(child: _statusField(context)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel(context, 'Image URL (Optional)'),
                  _fieldCard(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'https://example.com/image.jpg',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel(context, 'Attachments'),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image up to 40 KB, document up to 70 KB.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isUploadingAttachment
                                  ? null
                                  : _attachImage,
                              icon: const Icon(Icons.image_rounded),
                              label: const Text('Add Image'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isUploadingAttachment
                                  ? null
                                  : _attachDocument,
                              icon: const Icon(Icons.attach_file_rounded),
                              label: const Text('Add Document'),
                            ),
                          ],
                        ),
                        if (_isUploadingAttachment) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(),
                        ],
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final item in _attachments)
                                Chip(
                                  avatar: Icon(
                                    item.type == PostAttachmentType.image
                                        ? Icons.image_rounded
                                        : Icons.description_rounded,
                                    size: 16,
                                  ),
                                  label: Text(item.fileName),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel(context, 'Content'),
                  RichMarkdownEditor(
                    controller: _contentController,
                    hintText: 'Write your article with formatting and links...',
                    minLines: 10,
                    maxLines: 22,
                  ),
                  if (_isLoading || _isUploadingAttachment) ...[
                    const SizedBox(height: 18),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Category'),
        _fieldCard(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: _categories
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCategory = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Status'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_isPublished ? 'Published' : 'Draft'),
            value: _isPublished,
            onChanged: (value) => setState(() => _isPublished = value),
          ),
        ),
      ],
    );
  }

  Widget _fieldCard({required Widget child}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: child,
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
