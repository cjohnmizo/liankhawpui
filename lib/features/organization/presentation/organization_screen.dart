import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';

class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(organizationTreeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Organizations'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: treeAsync.when(
              data: (roots) {
                if (roots.isEmpty) {
                  return Center(
                    child: Text(
                      'No organizations found',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: roots.length,
                  itemBuilder: (context, index) =>
                      OrganizationNode(organization: roots[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Failed to load organizations',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrganizationNode extends StatelessWidget {
  final Organization organization;

  const OrganizationNode({super.key, required this.organization});

  @override
  Widget build(BuildContext context) {
    if (organization.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push('/organization/${organization.id}'),
            child: Row(
              children: [
                _OrganizationLogo(url: organization.logoUrl),
                const SizedBox(width: 10),
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
                      if ((organization.type ?? '').isNotEmpty)
                        Text(
                          organization.type!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: _OrganizationLogo(url: organization.logoUrl),
            title: Text(
              organization.name,
              style: AppTextStyles.titleSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accentGold,
                ),
                title: const Text('View Details'),
                onTap: () => context.push('/organization/${organization.id}'),
              ),
              for (final child in organization.children)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: OrganizationNode(organization: child),
                ),
            ],
          ),
        ),
      ),
    );
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
