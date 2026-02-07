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

      if (widget.news != null) {
        // Update existing
        await repo.updateNews(
          id: widget.news!.id,
          title: _titleController.text,
          content: _contentController.text,
          category: _selectedCategory,
          imageUrl: _imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : null,
          isPublished: _isPublished,
        );
      } else {
        // Create new
        await repo.createNews(
          title: _titleController.text,
          content: _contentController.text,
          category: _selectedCategory,
          imageUrl: _imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : null,
          isPublished: _isPublished,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving news: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.news != null ? 'Edit News' : 'New Article';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradient
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundLight,
                    AppColors.surfaceVariantLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Theme.of(context).colorScheme.onSurface,
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      TextButton(
                        onPressed: _saveNews,
                        child: Text(
                          'Save',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        _buildLabel(context, 'Title'),
                        GlassCard(
                          isPremium: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          borderRadius: 12,
                          child: TextFormField(
                            controller: _titleController,
                            style: AppTextStyles.bodyLarge,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter article title',
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Title is required' : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Category & Status Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(context, 'Category'),
                                  GlassCard(
                                    isPremium: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    borderRadius: 12,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCategory,
                                        isExpanded: true,
                                        dropdownColor: isDark
                                            ? AppColors.surfaceVariant
                                            : AppColors.surfaceLight,
                                        items: _categories.map((c) {
                                          return DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              c,
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) => setState(
                                          () => _selectedCategory = v!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(context, 'Status'),
                                  GlassCard(
                                    isPremium: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    borderRadius: 12,
                                    child: SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        _isPublished ? 'Published' : 'Draft',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _isPublished
                                                  ? const Color(0xFF10B981)
                                                  : Colors.orange,
                                            ),
                                      ),
                                      value: _isPublished,
                                      activeThumbColor: const Color(0xFF10B981),
                                      onChanged: (v) =>
                                          setState(() => _isPublished = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Image URL
                        _buildLabel(context, 'Image URL (Optional)'),
                        GlassCard(
                          isPremium: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          borderRadius: 12,
                          child: TextFormField(
                            controller: _imageUrlController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'https://example.com/image.jpg',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Content
                        _buildLabel(context, 'Content'),
                        GlassCard(
                          isPremium: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          borderRadius: 12,
                          child: TextFormField(
                            controller: _contentController,
                            style: AppTextStyles.bodyLarge,
                            maxLines: 15,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Write your article here...',
                            ),
                            validator: (v) => v?.isEmpty ?? true
                                ? 'Content is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
