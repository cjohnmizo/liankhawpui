import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(organizationTreeProvider);
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
              // Modern Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: AppColors.accentGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organizations',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Community structure & groups',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Organization Tree
              Expanded(
                child: treeAsync.when(
                  data: (roots) {
                    if (roots.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No organizations found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: roots.length,
                      itemBuilder: (context, index) {
                        return OrganizationNode(organization: roots[index]);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Failed to load organizations',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
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
}

class OrganizationNode extends StatelessWidget {
  final Organization organization;

  const OrganizationNode({super.key, required this.organization});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use GlassCard as the base container
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isPremium: false,
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: _buildTile(context, isDark),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, bool isDark) {
    if (organization.children.isEmpty) {
      return InkWell(
        onTap: () => context.push('/organization/${organization.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildLogo(organization.logoUrl, isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (organization.type != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accentGold.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          organization.type!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      );
    }

    return ExpansionTile(
      leading: _buildLogo(organization.logoUrl, isDark),
      title: Text(
        organization.name,
        style: AppTextStyles.titleMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconColor: AppColors.accentGold,
      collapsedIconColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.5),
      childrenPadding: const EdgeInsets.only(left: 16.0, bottom: 12),
      children: [
        // View Details Option
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.accentGold,
          ),
          title: Text(
            "View Details",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => context.push('/organization/${organization.id}'),
        ),
        // Recursive Children
        ...organization.children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OrganizationNode(organization: child),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(String? url, bool isDark) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.accentGold,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.accentGold, AppColors.accentGoldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.business_rounded,
          color: AppColors.backgroundDark,
          size: 24,
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder, width: 2),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: isDark
                ? AppColors.surfaceVariant
                : AppColors.surfaceVariantLight,
            child: const Icon(
              Icons.business_rounded,
              size: 24,
              color: AppColors.textTertiary,
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.accentGold,
            child: const Icon(Icons.business_rounded, size: 24),
          ),
        ),
      ),
    );
  }
}
