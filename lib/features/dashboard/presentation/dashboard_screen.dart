import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/dashboard/presentation/dashboard_providers.dart';
import 'package:liankhawpui/features/dashboard/presentation/widgets/dashboard_charts.dart';

const bool kTestMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Admin Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: 'Overview'),
                  const SizedBox(height: 12),
                  statsAsync.when(
                    data: (stats) => _buildStatGrid(
                      context: context,
                      currentUser: currentUser,
                      stats: stats,
                      placeholder: false,
                    ),
                    loading: () => _buildStatGrid(
                      context: context,
                      currentUser: currentUser,
                      stats: null,
                      placeholder: true,
                    ),
                    error: (_, __) => _buildStatGrid(
                      context: context,
                      currentUser: currentUser,
                      stats: null,
                      placeholder: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionPill(
                        icon: Icons.campaign_outlined,
                        label: 'New Announcement',
                        onTap: () => context.push('/announcement/create'),
                      ),
                      _ActionPill(
                        icon: Icons.auto_stories_rounded,
                        label: 'Manage Khawlian Chanchin',
                        onTap: () => context.push('/book/manage'),
                      ),
                      if (currentUser.role.isAdmin || kTestMode)
                        _ActionPill(
                          icon: Icons.person_add_alt_rounded,
                          label: 'Add User',
                          onTap: () => context.push('/dashboard/users'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Analytics'),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: UserGrowthChart()),
                            SizedBox(width: 12),
                            Expanded(child: ContentDistributionChart()),
                          ],
                        );
                      }
                      return const Column(
                        children: [
                          UserGrowthChart(),
                          SizedBox(height: 12),
                          ContentDistributionChart(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

Widget _buildStatGrid({
  required BuildContext context,
  required dynamic currentUser,
  required dynamic stats,
  required bool placeholder,
}) {
  final cards = [
    if (currentUser.role.isAdmin || kTestMode)
      _StatConfig(
        title: 'Users',
        value: placeholder ? '--' : stats.totalUsers.toString(),
        icon: Icons.people_rounded,
        color: AppColors.primaryNavy,
        onTap: (placeholder && !kTestMode)
            ? null
            : () => context.push('/dashboard/users'),
        badgeCount: placeholder ? null : stats.pendingUserCount,
      ),
    _StatConfig(
      title: 'Announcements',
      value: placeholder ? '--' : stats.totalAnnouncements.toString(),
      icon: Icons.campaign_rounded,
      color: AppColors.accentGold,
      onTap: (placeholder && !kTestMode)
          ? null
          : () => context.push('/announcement'),
    ),
    _StatConfig(
      title: 'News Articles',
      value: placeholder ? '--' : stats.totalNews.toString(),
      icon: Icons.newspaper_rounded,
      color: const Color(0xFF16A34A),
      onTap: (placeholder && !kTestMode)
          ? null
          : () => context.push('/dashboard/news'),
    ),
    _StatConfig(
      title: 'Organizations',
      value: placeholder ? '--' : stats.totalOrganizations.toString(),
      icon: Icons.business_rounded,
      color: const Color(0xFF0891B2),
      onTap: (placeholder && !kTestMode)
          ? null
          : () => context.push('/organization'),
    ),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final count = width >= 1000
          ? 4
          : width >= 680
          ? 2
          : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: count == 1 ? 2.4 : 1.45,
        ),
        itemBuilder: (context, index) => _StatCard(config: cards[index]),
      );
    },
  );
}

class _StatConfig {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int? badgeCount;

  _StatConfig({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });
}

class _StatCard extends StatelessWidget {
  final _StatConfig config;

  const _StatCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: config.onTap,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(config.icon, color: config.color),
              ),
              if ((config.badgeCount ?? 0) > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${config.badgeCount}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.value,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  config.title,
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
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accentGold),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
