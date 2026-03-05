import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/providers/network_status_provider.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/widgets/rich_markdown_editor.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class AnnouncementCreateScreen extends ConsumerStatefulWidget {
  final String? announcementId;

  const AnnouncementCreateScreen({super.key, this.announcementId});

  @override
  ConsumerState<AnnouncementCreateScreen> createState() =>
      _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState
    extends ConsumerState<AnnouncementCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCoverPublicUrl;
  String? _selectedCoverObjectPath;
  final _attachmentService = PostAttachmentService();
  final List<PostAttachmentUploadResult> _attachments =
      <PostAttachmentUploadResult>[];
  bool _isLoading = false;
  bool _isUploadingAttachment = false;
  bool _isPinned = false;
  bool _hasLoadedInitial = false;
  bool _isLoadingInitial = false;

  bool get _isEditMode => widget.announcementId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialAnnouncement();
      });
    } else {
      _hasLoadedInitial = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Content required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      assert(
        _selectedCoverObjectPath == null ||
            _selectedCoverObjectPath!.isNotEmpty,
      );
      if (!_isEditMode) {
        await ref
            .read(announcementRepositoryProvider)
            .createAnnouncement(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              isPinned: _isPinned,
              userId: user.id,
            );
      } else {
        await ref
            .read(announcementRepositoryProvider)
            .updateAnnouncement(
              id: widget.announcementId!,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              isPinned: _isPinned,
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialAnnouncement() async {
    if (!_isEditMode || _hasLoadedInitial || _isLoadingInitial) return;
    setState(() => _isLoadingInitial = true);

    try {
      final existing = await ref
          .read(announcementRepositoryProvider)
          .getAnnouncementById(widget.announcementId!);
      if (!mounted) return;
      if (existing == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Announcement not found')));
        context.pop();
        return;
      }
      setState(() {
        _titleController.text = existing.title;
        _contentController.text = existing.content;
        _isPinned = existing.isPinned;
        _hasLoadedInitial = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load announcement: $e')),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  Future<void> _attachImage() async {
    if (_isUploadingAttachment || _isLoading) return;
    setState(() => _isUploadingAttachment = true);
    final lowDataMode = ref.read(lowDataModeEnabledProvider);

    try {
      final result = await _attachmentService.pickCompressAndUploadImage(
        folder: 'announcements',
        lowDataMode: lowDataMode,
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _attachDocument() async {
    if (_isUploadingAttachment || _isLoading) return;
    setState(() => _isUploadingAttachment = true);

    try {
      final result = await _attachmentService.pickAndUploadDocument(
        folder: 'announcements',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Document upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkOnlineProvider).valueOrNull ?? true;
    final pageTitle = _isEditMode ? 'Edit Announcement' : 'New Announcement';
    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: !_hasLoadedInitial
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      GlassCard(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Content (Markdown formatter)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichMarkdownEditor(
                        controller: _contentController,
                        hintText:
                            'Write announcement content. Use toolbar for bold, list, links, and preview.',
                        minLines: 8,
                        maxLines: 18,
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('Pin this announcement'),
                          subtitle: const Text(
                            'Pinned posts appear first in list',
                          ),
                          value: _isPinned,
                          onChanged: (value) =>
                              setState(() => _isPinned = value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attachments',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Images are auto-optimized (Normal/Low Data). Documents up to 5 MB.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (!isOnline) ...[
                              const SizedBox(height: 8),
                              Text(
                                'You are offline. Uploading attachments is disabled.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _isUploadingAttachment || !isOnline
                                      ? null
                                      : _attachImage,
                                  icon: const Icon(Icons.image_rounded),
                                  label: const Text('Pick image'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _isUploadingAttachment || !isOnline
                                      ? null
                                      : _attachDocument,
                                  icon: const Icon(Icons.attach_file_rounded),
                                  label: const Text('Add Document'),
                                ),
                              ],
                            ),
                            if (_isUploadingAttachment) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                            ],
                            if (_attachments.isNotEmpty) ...[
                              const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading || _isUploadingAttachment
                              ? null
                              : _submit,
                          child: _isLoading || _isUploadingAttachment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isEditMode ? 'Update' : 'Publish'),
                        ),
                      ),
                    ],
                  ),
                ),
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
