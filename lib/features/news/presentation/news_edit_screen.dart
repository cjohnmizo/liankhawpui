import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/providers/network_status_provider.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/services/storage_budget_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
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
  String? _selectedCoverPublicUrl;
  String? _selectedCoverObjectPath;
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
    _selectedCoverPublicUrl = _normalizeImageValue(
      resolveDisplayImageUrl(
        thumbUrl: widget.news?.thumbUrl,
        coverUrl:
            widget.news?.coverUrl ??
            firstMarkdownImageUrl(widget.news?.content ?? ''),
        legacyImageUrl: widget.news?.legacyImageUrl,
      ),
    );
    _selectedCategory = widget.news?.category ?? 'General';
    _isPublished = widget.news?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
      assert(
        _selectedCoverObjectPath == null ||
            _selectedCoverObjectPath!.isNotEmpty,
      );
      if (widget.news != null) {
        await repo.updateNews(
          id: widget.news!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          isPublished: _isPublished,
        );
      } else {
        await repo.createNews(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
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
    final budget = ref.read(storageBudgetProvider).valueOrNull;
    if ((budget?.percentOf1GB ?? 0) >= 95) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Storage is almost full. Delete old attachments or reduce uploads.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isUploadingAttachment = true);
    final lowDataMode = ref.read(lowDataModeEnabledProvider);

    try {
      final result = await _attachmentService.pickCompressAndUploadImage(
        folder: 'news',
        lowDataMode: lowDataMode,
        confirmUpload: _confirmImageUpload,
      );
      if (result == null || !mounted) return;

      setState(() {
        _attachments.add(result);
        if (_selectedCoverPublicUrl == null) {
          _selectedCoverPublicUrl = _normalizeImageValue(
            result.preferredListImageUrl ?? result.publicUrl,
          );
          _selectedCoverObjectPath = _normalizeImageValue(result.objectPath);
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
      ref.invalidate(storageBudgetProvider);
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

  Future<bool> _confirmImageUpload(ImageUploadPreviewData preview) async {
    if (!mounted) return false;
    final original = PostAttachmentService.humanReadableBytes(
      preview.originalSizeBytes,
    );
    final full = PostAttachmentService.humanReadableBytes(
      preview.fullImage.sizeBytes,
    );
    final thumb = PostAttachmentService.humanReadableBytes(
      preview.thumbImage.sizeBytes,
    );
    final total = PostAttachmentService.humanReadableBytes(
      preview.estimatedStoredBytes,
    );

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Preview'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original: $original'),
                const SizedBox(height: 6),
                Text('Optimized full: $full'),
                Text('Thumbnail: $thumb'),
                const SizedBox(height: 6),
                Text('Estimated stored total: $total'),
                const SizedBox(height: 8),
                const Text(
                  'This saves storage and mobile data.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Upload'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _attachDocument() async {
    if (_isUploadingAttachment || _isLoading) return;
    final budget = ref.read(storageBudgetProvider).valueOrNull;
    if ((budget?.percentOf1GB ?? 0) >= 95) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Storage is almost full. Delete old attachments or reduce uploads.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
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
      ref.invalidate(storageBudgetProvider);
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
    final isOnline = ref.watch(networkOnlineProvider).valueOrNull ?? true;
    final storageBudgetAsync = ref.watch(storageBudgetProvider);
    final storageBudget = storageBudgetAsync.valueOrNull;
    final storagePercent = storageBudget?.percentOf1GB ?? 0;
    final isStorageNearLimit = storagePercent >= 80;
    final isStorageBlocked = storagePercent >= 95;

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
                  _fieldLabel(context, 'Attachments'),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Images are auto-optimized (Normal/Low Data). PDF recommended. DOCX/XLSX supported. Max size 5 MB.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!isOnline) ...[
                          const SizedBox(height: 8),
                          Text(
                            'You are offline. Uploading attachments is disabled.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (isStorageNearLimit) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isStorageBlocked
                                  ? AppColors.error.withValues(alpha: 0.14)
                                  : AppColors.accentGold.withValues(
                                      alpha: 0.14,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isStorageBlocked
                                  ? 'Storage is almost full (${storagePercent.toStringAsFixed(1)}% of 1GB). Uploads are blocked.'
                                  : 'Storage nearing limit (${storagePercent.toStringAsFixed(1)}% of 1GB used).',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (_selectedCoverPublicUrl != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.image_rounded, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cover image selected from device',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCoverPublicUrl = null;
                                    _selectedCoverObjectPath = null;
                                  });
                                },
                                child: const Text('Remove image'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  _isUploadingAttachment ||
                                      !isOnline ||
                                      isStorageBlocked
                                  ? null
                                  : _attachImage,
                              icon: const Icon(Icons.image_rounded),
                              label: const Text('Pick image'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _isUploadingAttachment ||
                                      !isOnline ||
                                      isStorageBlocked
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
                    hintText:
                        'Write your article with formatting, justify, and links...',
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

  String? _normalizeImageValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
