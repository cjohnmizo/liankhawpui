import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/dashboard/presentation/dashboard_providers.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/features/dashboard/presentation/widgets/dashboard_charts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
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
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.glassBorder
                          : AppColors.glassBorderLightMode,
                      width: 1,
                    ),
                  ),
                  color:
                      (isDark
                              ? AppColors.surfaceVariant
                              : AppColors.surfaceLight)
                          .withValues(alpha: 0.8),
                ),
                child: Row(
                  children: [
                    if (context.canPop()) ...[
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Overview & Management',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(dashboardStatsProvider.future),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Overview
                        _SectionHeader(context: context, title: 'Overview'),
                        const SizedBox(height: 16),
                        statsAsync.when(
                          data: (stats) => LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth > 900;
                              final crossAxisCount = isDesktop ? 4 : 2;

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isDesktop ? 1.5 : 1.0,
                                children: [
                                  _StatCard(
                                    title: 'Users',
                                    value: stats.totalUsers.toString(),
                                    icon: Icons.people_rounded,
                                    color: isDark
                                        ? const Color(0xFF5c6bc0)
                                        : AppColors.primaryNavy,
                                    onTap: () {
                                      if (stats.pendingUserCount > 0) {
                                        context.push(
                                          '/dashboard/users?filter=guest',
                                        );
                                      } else {
                                        context.push('/dashboard/users');
                                      }
                                    },
                                    badgeCount: stats.pendingUserCount,
                                  ),
                                  _StatCard(
                                    title: 'Announcements',
                                    value: stats.totalAnnouncements.toString(),
                                    icon: Icons.campaign_rounded,
                                    color: AppColors.accentGold,
                                    onTap: () => context.push('/announcement'),
                                  ),
                                  _StatCard(
                                    title: 'News Articles',
                                    value: stats.totalNews.toString(),
                                    icon: Icons.newspaper_rounded,
                                    color: const Color(0xFF10B981),
                                    onTap: () =>
                                        context.push('/dashboard/news'),
                                  ),
                                  _StatCard(
                                    title: 'Organizations',
                                    value: stats.totalOrganizations.toString(),
                                    icon: Icons.business_rounded,
                                    color: isDark
                                        ? AppColors.accentBeige
                                        : AppColors.accentGoldDark,
                                    onTap: () => context.push('/organization'),
                                  ),
                                ],
                              );
                            },
                          ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGold,
                              ),
                            ),
                          ),
                          error: (e, st) => Center(
                            child: Text(
                              'Error loading stats',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Analytics
                        _SectionHeader(context: context, title: 'Analytics'),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 900) {
                              return const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: UserGrowthChart()),
                                  SizedBox(width: 24),
                                  Expanded(child: ContentDistributionChart()),
                                ],
                              );
                            }
                            return const Column(
                              children: [
                                UserGrowthChart(),
                                SizedBox(height: 16),
                                ContentDistributionChart(),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions
                        _SectionHeader(
                          context: context,
                          title: 'Quick Actions',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _QuickActionButton(
                              icon: Icons.campaign_outlined,
                              label: 'New Announcement',
                              onTap: () => context.push('/announcement/create'),
                            ),
                            _QuickActionButton(
                              icon: Icons.person_add_outlined,
                              label: 'Add User',
                              onTap: () => context.push('/register'),
                            ),
                            // Add more actions as needed
                          ],
                        ),
                        const SizedBox(height: 48), // Bottom padding
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  final int? badgeCount;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      isPremium: true,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Icon(
                Icons.arrow_outward_rounded,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.displaySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final BuildContext context;
  final String title;

  const _SectionHeader({required this.context, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(2),
          ),
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
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        isPremium: false,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: 16,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDark ? AppColors.accentGold : AppColors.primaryNavy,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
