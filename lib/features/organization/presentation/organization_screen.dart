import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/localization/app_strings.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';

class OrganizationScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const OrganizationScreen({super.key, this.embedded = false});

  @override
  ConsumerState<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends ConsumerState<OrganizationScreen> {
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
    final t = context.t;
    final treeAsync = ref.watch(organizationTreeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 8 : 12, 16, 16),
          child: Column(
            children: [
              _buildSearchAndFilters(context),
              const SizedBox(height: 12),
              Expanded(
                child: treeAsync.when(
                  data: (roots) {
                    final allOrganizations = _flattenOrganizations(roots);
                    final filtered = _filterOrganizations(allOrganizations);
                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        message: allOrganizations.isEmpty
                            ? t.noOrganizationsAvailable
                            : t.noOrganizationsFoundForThisSearch,
                        icon: Icons.search_off_rounded,
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final organization = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OrganizationCard(organization: organization),
                        );
                      },
                    );
                  },
                  loading: () =>
                      AppLoadingState(message: t.loadingOrganizations),
                  error: (_, __) => AppEmptyState(
                    message: t.couldNotLoadOrganizations,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(t.organizations),
        actions: [
          if (currentUser.role.isEditor)
            IconButton(
              tooltip: 'Manage organizations',
              onPressed: () => context.push('/dashboard/organizations'),
              icon: const Icon(Icons.edit_note_rounded),
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final t = context.t;
    return GlassCard(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: t.searchOrganizations,
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

  List<Organization> _flattenOrganizations(List<Organization> roots) {
    final flat = <Organization>[];
    void visit(Organization org) {
      flat.add(org);
      for (final child in org.children) {
        visit(child);
      }
    }

    for (final org in roots) {
      visit(org);
    }
    return flat;
  }

  List<Organization> _filterOrganizations(List<Organization> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((org) {
      final category = (org.type ?? '').trim();
      final matchCategory = _selectedCategory == 'All'
          ? true
          : category.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchQuery = query.isEmpty
          ? true
          : org.name.toLowerCase().contains(query) ||
                category.toLowerCase().contains(query);
      return matchCategory && matchQuery;
    }).toList();
  }
}

class _OrganizationCard extends StatelessWidget {
  final Organization organization;

  const _OrganizationCard({required this.organization});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/organization/${organization.id}'),
        child: Row(
          children: [
            _OrganizationLogo(url: organization.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _categoryLabel(organization.type),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Institution';
    return raw.trim();
  }
}

class _OrganizationLogo extends StatelessWidget {
  final String? url;

  const _OrganizationLogo({this.url});

  @override
  Widget build(BuildContext context) {
    if ((url ?? '').isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.business_rounded, color: AppColors.accentGold),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 42,
        height: 42,
        child: CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: AppColors.surfaceVariantLight,
            child: const Icon(Icons.business_rounded),
          ),
        ),
      ),
    );
  }
}
