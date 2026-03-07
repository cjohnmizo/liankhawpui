import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';

class OrganizationManageScreen extends ConsumerStatefulWidget {
  const OrganizationManageScreen({super.key});

  @override
  ConsumerState<OrganizationManageScreen> createState() =>
      _OrganizationManageScreenState();
}

class _OrganizationManageScreenState
    extends ConsumerState<OrganizationManageScreen> {
  static const _categories = <String>[
    'All',
    'Council',
    'NGO',
    'Church',
    'Institution',
    'Health',
  ];

  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizationsAsync = ref.watch(organizationTreeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Manage Organizations'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _buildSearchAndFilters(),
                const SizedBox(height: 12),
                Expanded(
                  child: organizationsAsync.when(
                    data: (roots) {
                      final items = _filterItems(_flatten(roots));
                      if (items.isEmpty) {
                        return const AppEmptyState(
                          message:
                              'No organizations match the current filters.',
                          icon: Icons.search_off_rounded,
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return GlassCard(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                    left: item.depth * 12.0,
                                    top: 2,
                                  ),
                                  child: _OrganizationLeadingLogo(
                                    url: item.organization.logoUrl,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.organization.name,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _MetaChip(
                                            icon: Icons.label_outline_rounded,
                                            label: _typeLabel(
                                              item.organization.type,
                                            ),
                                          ),
                                          if (item.parentName != null)
                                            _MetaChip(
                                              icon: Icons.account_tree_rounded,
                                              label:
                                                  'Parent: ${item.parentName}',
                                            ),
                                          if ((item.organization.currentTerm ??
                                                  '')
                                              .trim()
                                              .isNotEmpty)
                                            _MetaChip(
                                              icon: Icons.event_note_rounded,
                                              label:
                                                  'Term: ${item.organization.currentTerm!.trim()}',
                                            ),
                                        ],
                                      ),
                                      if ((item.organization.description ?? '')
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          item.organization.description!.trim(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Manage organization',
                                  onSelected: (value) => _handleAction(
                                    context,
                                    item.organization,
                                    value,
                                  ),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<String>(
                                      value: 'open',
                                      child: ListTile(
                                        leading: Icon(Icons.visibility_rounded),
                                        title: Text('Open details'),
                                        contentPadding: EdgeInsets.zero,
                                        minLeadingWidth: 20,
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_rounded),
                                        title: Text('Edit'),
                                        contentPadding: EdgeInsets.zero,
                                        minLeadingWidth: 20,
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                        title: Text('Delete'),
                                        contentPadding: EdgeInsets.zero,
                                        minLeadingWidth: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const AppLoadingState(
                      message: 'Loading organizations...',
                    ),
                    error: (_, __) => const AppEmptyState(
                      message: 'Could not load organizations.',
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/organizations/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Organization'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return GlassCard(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search organizations',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map(
                    (category) => ChoiceChip(
                      selected: category == _selectedCategory,
                      label: Text(category),
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Organization organization,
    String action,
  ) async {
    if (action == 'open') {
      context.push('/organization/${organization.id}');
      return;
    }
    if (action == 'edit') {
      context.push('/dashboard/organizations/edit/${organization.id}');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization?'),
        content: const Text(
          'Child organizations must be removed first. Office bearers will be removed with this organization.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(organizationRepositoryProvider)
          .deleteOrganization(organization.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${organization.name} deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  List<_OrganizationListItem> _flatten(
    List<Organization> roots, {
    int depth = 0,
    String? parentName,
  }) {
    final items = <_OrganizationListItem>[];
    for (final organization in roots) {
      items.add(
        _OrganizationListItem(
          organization: organization,
          depth: depth,
          parentName: parentName,
        ),
      );
      items.addAll(
        _flatten(
          organization.children,
          depth: depth + 1,
          parentName: organization.name,
        ),
      );
    }
    return items;
  }

  List<_OrganizationListItem> _filterItems(List<_OrganizationListItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      final type = (item.organization.type ?? '').trim().toLowerCase();
      final parent = (item.parentName ?? '').trim().toLowerCase();
      final matchesCategory = _selectedCategory == 'All'
          ? true
          : type.contains(_selectedCategory.toLowerCase());
      final matchesQuery = query.isEmpty
          ? true
          : item.organization.name.toLowerCase().contains(query) ||
                type.contains(query) ||
                parent.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  String _typeLabel(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'Institution';
    }
    return normalized;
  }
}

class _OrganizationListItem {
  final Organization organization;
  final int depth;
  final String? parentName;

  const _OrganizationListItem({
    required this.organization,
    required this.depth,
    this.parentName,
  });
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationLeadingLogo extends StatelessWidget {
  final String? url;

  const _OrganizationLeadingLogo({this.url});

  @override
  Widget build(BuildContext context) {
    final normalized = url?.trim();
    if (normalized == null || normalized.isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.business_rounded, color: AppColors.accentGold),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 42,
        height: 42,
        child: CachedNetworkImage(
          imageUrl: normalized,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: AppColors.accentGold.withValues(alpha: 0.14),
            child: const Icon(
              Icons.business_rounded,
              color: AppColors.accentGold,
            ),
          ),
        ),
      ),
    );
  }
}
