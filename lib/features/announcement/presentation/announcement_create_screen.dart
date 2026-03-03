import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class AnnouncementCreateScreen extends ConsumerStatefulWidget {
  const AnnouncementCreateScreen({super.key});

  @override
  ConsumerState<AnnouncementCreateScreen> createState() =>
      _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState
    extends ConsumerState<AnnouncementCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
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
      await ref
          .read(announcementRepositoryProvider)
          .createAnnouncement(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            imageUrl: _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
            userId: user.id,
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
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
                GlassCard(
                  child: TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (Optional)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
