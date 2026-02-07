import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/core/widgets/glass_bottom_nav.dart';

// Feature screens
import 'package:liankhawpui/features/news/presentation/news_list_screen.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_list_screen.dart';
import 'package:liankhawpui/features/organization/presentation/organization_screen.dart';
import 'package:liankhawpui/core/widgets/app_drawer.dart';
import 'package:liankhawpui/core/widgets/app_logo.dart'; // Restored Import // Added Import
// Providers
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

// State provider for bottom nav index
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(), // Added Drawer
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
          bottom: false,
          child: Column(
            children: [
              // Show Home AppBar only on Home Tab (index 0)
              // Other screens have their own headers
              if (currentIndex == 0) _buildModernAppBar(context, user),

              // Content
              Expanded(
                child: IndexedStack(
                  index: currentIndex,
                  children: [
                    _buildHomeDashboard(context, ref, user),
                    const NewsListScreen(),
                    const AnnouncementListScreen(),
                    const OrganizationScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassBottomNav(
        context,
        ref,
        currentIndex,
        user,
      ),
      floatingActionButton: user.role.isEditor && currentIndex == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 75),
              child: FloatingActionButton(
                onPressed: () => _showCreateMenu(context),
                backgroundColor: AppColors.accentGold,
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: AppColors.backgroundDark,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildModernAppBar(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Minimal transparent header
      ),
      child: Row(
        children: [
          CircularAppLogo(
            size: 46,
            padding: 2,
            borderColor: AppColors.accentGold.withValues(alpha: 0.3),
            borderWidth: 1,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'LIANKHAWPUI',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.accentGold,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Theme Toggle Removed - moved to App Drawer
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.5),
              ),
              image: !user.isGuest && user.photoUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(user.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: InkWell(
              onTap: () {
                if (user.isGuest) {
                  context.push('/login');
                } else {
                  context.push('/profile');
                }
              },
              customBorder: const CircleBorder(),
              child: !user.isGuest && user.photoUrl != null
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    user,
  ) {
    final items = [
      const BottomNavItem(
        icon: Icons.home_outlined, // Changed to standard home icon
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      const BottomNavItem(
        icon: Icons.newspaper_outlined,
        activeIcon: Icons.newspaper_rounded,
        label: 'News',
      ),
      const BottomNavItem(
        icon: Icons
            .campaign_outlined, // Changed from announcement for better visual
        activeIcon: Icons.campaign_rounded,
        label: 'Updates',
      ),
      // const BottomNavItem(
      //   icon: Icons.groups_outlined,
      //   activeIcon: Icons.groups_rounded,
      //   label: 'Groups',
      // ),
      const BottomNavItem(
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu_open_rounded,
        label: 'Menu',
      ),
    ];

    return GlassBottomNav(
      currentIndex: currentIndex,
      items: items,
      onTap: (index) {
        if (index == 3) {
          // Menu Item Index
          _scaffoldKey.currentState?.openDrawer();
        } else {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        }
      },
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
    );
  }

  // ============================================================================
  // Home Dashboard Content
  // ============================================================================

  Widget _buildHomeDashboard(BuildContext context, WidgetRef ref, user) {
    final newsAsync = ref.watch(newsStreamProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Featured Section (Latest News)
          _buildSectionHeader(context, 'Featured News', Icons.star_rounded),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: newsAsync.when(
              data: (newsList) {
                if (newsList.isEmpty) {
                  return _buildEmptyState(context, 'No news yet');
                }
                // Taking top 3 items
                final featured = newsList.take(3).toList();
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      _FeaturedNewsCard(news: featured[index]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
              error: (_, __) => _buildEmptyState(context, 'Failed to load'),
            ),
          ),

          const SizedBox(height: 32),

          // 1. Village Hero Section
          _buildVillageHero(context),
          const SizedBox(height: 32),

          // 2. Directory Section
          _buildSectionHeader(context, 'Directory', Icons.menu_book_rounded),
          const SizedBox(height: 16),
          GlassCard(
            isPremium: true,
            borderRadius: 20,
            padding: EdgeInsets.zero,
            onTap: () => context.push('/book'),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const NetworkImage(
                    'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?q=80&w=2730&auto=format&fit=crop', // Placeholder book image
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.backgroundDark,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Khawlian Chanchin',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explore stories & history',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 3. Recent Announcements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                context,
                'Recent Updates',
                Icons.notifications_active_rounded,
              ),
              TextButton(
                onPressed: () =>
                    ref.read(bottomNavIndexProvider.notifier).state =
                        2, // Switch to Updates tab
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          announcementsAsync.when(
            data: (list) {
              if (list.isEmpty) return _buildEmptyState(context, 'No updates');
              final recent = list.take(3).toList();
              return Column(
                children: recent
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CompactAnnouncementCard(announcement: item),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox(),
          ),

          // Extra padding for bottom nav
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVillageHero(BuildContext context) {
    return GlassCard(
      isPremium: true,
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.asset('assets/landscape.png', fit: BoxFit.cover),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Text Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      'WELCOME TO',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liankhawpui',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A Place of Unity & Heritage',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return GlassCard(
      isPremium: false,
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Helper Widgets
  // ============================================================================

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _CreateMenuItem(
              icon: Icons.newspaper_rounded,
              label: 'News Article',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                context.push('/news/create');
              },
            ),
            const SizedBox(height: 16),
            _CreateMenuItem(
              icon: Icons.campaign_rounded,
              label: 'Announcement',
              color: AppColors.accentGold,
              onTap: () {
                Navigator.pop(context);
                context.push('/announcement/create');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  final dynamic
  news; // Using dynamic to avoid import conflicting quirks, typically News
  const _FeaturedNewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 8), // small margin for separation
      child: GlassCard(
        isPremium: true,
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (news.imageUrl != null)
              CachedNetworkImage(
                imageUrl: news.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceVariant),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceVariant),
              )
            else
              Container(
                color: isDark
                    ? AppColors.surfaceVariant
                    : AppColors.surfaceVariantLight,
                child: const Icon(
                  Icons.article_rounded,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Text content
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news.category,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.backgroundDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
      isPremium: false,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  announcement.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _CreateMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CreateMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }
}
