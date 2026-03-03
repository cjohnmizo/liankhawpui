import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';

class OrganizationDetailScreen extends ConsumerWidget {
  final String orgId;

  const OrganizationDetailScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(organizationTreeProvider);
    final officeBearersAsync = ref.watch(officeBearersProvider(orgId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Organization Details'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: treeAsync.when(
            data: (roots) {
              final org = _findOrg(roots, orgId);
              if (org == null) {
                return Center(
                  child: Text(
                    'Organization not found',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        _OrgAvatar(url: org.logoUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                org.name,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if ((org.type ?? '').isNotEmpty)
                                Text(
                                  org.type!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if ((org.currentTerm ?? '').isNotEmpty)
                                Text(
                                  'Current Term: ${org.currentTerm}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((org.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'About',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassCard(
                      child: Text(
                        org.description!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Office Bearers',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  officeBearersAsync.when(
                    data: (bearers) {
                      if (bearers.isEmpty) {
                        return const GlassCard(
                          child: Text('No office bearers listed yet.'),
                        );
                      }
                      return Column(
                        children: [
                          for (final bearer in bearers)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: bearer.photoUrl == null
                                            ? Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                ),
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: bearer.photoUrl!,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    const Icon(
                                                      Icons.person_rounded,
                                                    ),
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
                                            bearer.name,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            bearer.position,
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
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error loading members: $e')),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading details: $e')),
          ),
        ),
      ),
    );
  }

  Organization? _findOrg(List<Organization> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = _findOrg(node.children, id);
      if (found != null) return found;
    }
    return null;
  }
}

class _OrgAvatar extends StatelessWidget {
  final String? url;

  const _OrgAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    if ((url ?? '').isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.accentGold.withValues(alpha: 0.14),
        ),
        child: const Icon(Icons.business_rounded, color: AppColors.accentGold),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        height: 58,
        child: CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const Icon(Icons.business_rounded),
        ),
      ),
    );
  }
}
