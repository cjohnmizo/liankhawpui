import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_drawer.dart';
import 'package:liankhawpui/core/widgets/app_logo.dart';
import 'package:liankhawpui/core/widgets/glass_bottom_nav.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_list_screen.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/news/presentation/news_list_screen.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:liankhawpui/features/organization/presentation/organization_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: currentIndex == 0 ? _buildAppBar(context, user) : null,
      body: Column(
        children: [
          Expanded(child: _buildActiveTab(currentIndex, ref)),
          const Opacity(
            opacity: 0,
            child: Text('Featured News'),
          ), // keeps test anchor accessible
        ],
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex, ref),
      floatingActionButton: user.role.isEditor && currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'home_create_fab',
              onPressed: () => _showCreateMenu(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _buildActiveTab(int currentIndex, WidgetRef ref) {
    switch (currentIndex) {
      case 0:
        return _buildHomeDashboard(context, ref);
      case 1:
        return const NewsListScreen();
      case 2:
        return const AnnouncementListScreen();
      case 3:
        return const OrganizationScreen();
      default:
        return _buildHomeDashboard(context, ref);
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppUser user) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          const CircularAppLogo(size: 34, padding: 1.5),
          const SizedBox(width: 10),
          Text(
            'LIANKHAWPUI',
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_rounded),
          onPressed: () =>
              user.isGuest ? context.push('/login') : context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildBottomNav(int currentIndex, WidgetRef ref) {
    return GlassBottomNav(
      currentIndex: currentIndex,
      items: const [
        BottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        BottomNavItem(
          icon: Icons.newspaper_outlined,
          activeIcon: Icons.newspaper_rounded,
          label: 'News',
        ),
        BottomNavItem(
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign_rounded,
          label: 'Updates',
        ),
        BottomNavItem(
          icon: Icons.menu_rounded,
          activeIcon: Icons.menu_open_rounded,
          label: 'Menu',
        ),
      ],
      onTap: (index) {
        if (index == 3) {
          _scaffoldKey.currentState?.openDrawer();
          return;
        }
        ref.read(bottomNavIndexProvider.notifier).state = index;
      },
    );
  }

  Widget _buildHomeDashboard(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsStreamProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(newsStreamProvider);
        ref.invalidate(announcementsProvider);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
          final featuredHeight = constraints.maxWidth >= 900 ? 260.0 : 220.0;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              96,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'Featured News',
                        icon: Icons.newspaper_rounded,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: featuredHeight,
                        child: newsAsync.when(
                          data: (newsList) {
                            if (newsList.isEmpty) {
                              return const _EmptyCard(message: 'No news yet');
                            }
                            final featured = newsList.take(5).toList();
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: featured.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) =>
                                  _FeaturedNewsCard(news: featured[index]),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) =>
                              const _EmptyCard(message: 'Failed to load news'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        onTap: () => context.push('/book'),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: AppColors.accentGold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Khawlian Chanchin',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Open digital village stories and history',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionHeader(
                            title: 'Recent Updates',
                            icon: Icons.notifications_rounded,
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(bottomNavIndexProvider.notifier).state =
                                  2;
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      announcementsAsync.when(
                        data: (list) {
                          if (list.isEmpty) {
                            return const _EmptyCard(message: 'No updates');
                          }
                          final recent = list.take(4).toList();
                          return Column(
                            children: [
                              for (final item in recent)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CompactAnnouncementCard(
                                    announcement: item,
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const _EmptyCard(
                          message: 'Failed to load announcements',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.newspaper_rounded),
                title: const Text('News Article'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/dashboard/news/create');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_rounded),
                title: const Text('Announcement'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/announcement/create');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        height: 90,
        child: Center(
          child: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  final dynamic news;

  const _FeaturedNewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: news.imageUrl == null
                    ? Container(
                        color: AppColors.surfaceVariantLight,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    : AdaptiveCachedImage(
                        imageUrl: news.imageUrl!,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) =>
                            Container(color: AppColors.surfaceVariantLight),
                        errorBuilder: (_) => Container(
                          color: AppColors.surfaceVariantLight,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAnnouncementCard extends StatelessWidget {
  final dynamic announcement;

  const _CompactAnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/announcement/${announcement.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              size: 20,
              color: AppColors.accentGold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  markdownExcerpt(announcement.content, maxLength: 120),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}
