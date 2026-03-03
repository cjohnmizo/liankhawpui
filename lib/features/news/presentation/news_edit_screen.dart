import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
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
            onPressed: _isLoading ? null : _saveNews,
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
                  _fieldLabel(context, 'Content'),
                  _fieldCard(
                    child: TextFormField(
                      controller: _contentController,
                      maxLines: 14,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Write your article here...',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Content is required'
                          : null,
                    ),
                  ),
                  if (_isLoading) ...[
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
