import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add url_launcher dependency if confirmed

class OrganizationDetailScreen extends ConsumerWidget {
  final String orgId;

  const OrganizationDetailScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Need to find the org from the tree or fetch individually.
    // Simplifying by fetching tree and finding likely cached or fast.
    final treeAsync = ref.watch(organizationTreeProvider);
    final officeBearersAsync = ref.watch(officeBearersProvider(orgId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // Custom Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    if (context.canPop()) ...[
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Organization Details',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: treeAsync.when(
                  data: (roots) {
                    final org = _findOrg(roots, orgId);
                    if (org == null) {
                      return Center(
                        child: Text(
                          'Organization not found',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Section
                          GlassCard(
                            isPremium: true,
                            padding: const EdgeInsets.all(32),
                            borderRadius: 24,
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accentGold,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentGold.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: org.logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: org.logoUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: isDark
                                                  ? AppColors.surfaceVariant
                                                  : AppColors
                                                        .surfaceVariantLight,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                  color: AppColors.accentGold,
                                                  child: const Icon(
                                                    Icons.business_rounded,
                                                    size: 40,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            color: AppColors.accentGold,
                                            child: const Icon(
                                              Icons.business_rounded,
                                              size: 40,
                                              color: AppColors.backgroundDark,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  org.name,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (org.type != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.accentGold.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      org.type!.toUpperCase(),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.accentGold,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                                if (org.currentTerm != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Current Term: ${org.currentTerm}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // About Section
                          if (org.description != null &&
                              org.description!.isNotEmpty) ...[
                            Text(
                              'About',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              isPremium: false,
                              padding: const EdgeInsets.all(20),
                              borderRadius: 20,
                              child: Text(
                                org.description!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Office Bearers
                          Text(
                            'Office Bearers',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          officeBearersAsync.when(
                            data: (bearers) {
                              if (bearers.isEmpty) {
                                return GlassCard(
                                  isPremium: false,
                                  child: Center(
                                    child: Text(
                                      'No office bearers listed yet.',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bearers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final bearer = bearers[index];
                                  return GlassCard(
                                    isPremium: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    borderRadius: 16,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.glassBorder,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: bearer.photoUrl != null
                                                ? CachedNetworkImage(
                                                    imageUrl: bearer.photoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) =>
                                                        const Icon(
                                                          Icons.person,
                                                          color: AppColors
                                                              .textTertiary,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    color:
                                                        AppColors.textTertiary,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                bearer.name,
                                                style: AppTextStyles.titleMedium
                                                    .copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                bearer.position,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppColors.accentGold,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (bearer.phone != null)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.phone_rounded,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                // launchUrl
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => const Center(
                              child: Text(
                                'Error loading members',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      const Center(child: Text('Error loading details')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Organization? _findOrg(List<Organization> nodes, String id) {
    for (var node in nodes) {
      if (node.id == id) return node;
      final found = _findOrg(node.children, id);
      if (found != null) return found;
    }
    return null;
  }
}
