import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/providers/network_status_provider.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_drawer.dart';
import 'package:liankhawpui/core/widgets/app_logo.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_bottom_nav.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/announcement/domain/announcement.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/auth/presentation/profile_screen.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/presentation/news_list_screen.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';
import 'package:liankhawpui/features/organization/presentation/organization_screen.dart';
import 'package:liankhawpui/features/story/presentation/book_list_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

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
    final isOnline = ref.watch(networkOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(context, user, currentIndex),
      body: Column(
        children: [
          Expanded(child: _buildActiveTab(currentIndex)),
          const Opacity(opacity: 0, child: Text('Featured News')),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
      floatingActionButton: user.role.isEditor && currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'home_create_fab',
              onPressed: isOnline ? () => _showCreateMenu(context) : null,
              tooltip: isOnline
                  ? 'Create post'
                  : 'Offline mode: reconnect to create content',
              child: Icon(
                isOnline ? Icons.add_rounded : Icons.wifi_off_rounded,
              ),
            )
          : null,
    );
  }

  Widget _buildActiveTab(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return _buildHomeDashboard(context, ref);
      case 1:
        return const NewsListScreen(embedded: true);
      case 2:
        return const OrganizationScreen(embedded: true);
      case 3:
        return const BookListScreen(embedded: true);
      case 4:
        return const ProfileScreen(embedded: true);
      default:
        return _buildHomeDashboard(context, ref);
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppUser user,
    int currentIndex,
  ) {
    final title = switch (currentIndex) {
      0 => 'Liankhawpui',
      1 => 'News',
      2 => 'Organizations',
      3 => 'Stories',
      4 => 'Profile',
      _ => 'Liankhawpui',
    };

    return AppBar(
      titleSpacing: 12,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          const CircularAppLogo(size: 30, padding: 1.2),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        if (user.role.isEditor)
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard_rounded),
            onPressed: () => context.push('/dashboard'),
          ),
        if (currentIndex != 4)
          IconButton(
            tooltip: user.isGuest ? 'Sign in' : 'Profile',
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 4;
            },
          ),
      ],
    );
  }

  Widget _buildBottomNav(int currentIndex) {
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
          icon: Icons.account_tree_outlined,
          activeIcon: Icons.account_tree_rounded,
          label: 'Organizations',
        ),
        BottomNavItem(
          icon: Icons.auto_stories_outlined,
          activeIcon: Icons.auto_stories_rounded,
          label: 'Stories',
        ),
        BottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        ref.read(bottomNavIndexProvider.notifier).state = index;
      },
    );
  }

  Widget _buildHomeDashboard(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final newsAsync = ref.watch(newsStreamProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    final organizationsAsync = ref.watch(organizationTreeProvider);
    final isOnline = ref.watch(networkOnlineProvider).valueOrNull ?? true;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(newsStreamProvider);
        ref.invalidate(announcementsProvider);
        ref.invalidate(organizationTreeProvider);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
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
                      _HeaderBanner(user: user, isOnline: isOnline),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Recent News',
                        subtitle: 'Latest stories from the village',
                        icon: Icons.newspaper_rounded,
                        actionLabel: 'Open news',
                        onActionTap: () =>
                            ref.read(bottomNavIndexProvider.notifier).state = 1,
                      ),
                      const SizedBox(height: 10),
                      newsAsync.when(
                        data: (items) {
                          final top = items.take(6).toList();
                          if (top.isEmpty) {
                            return const AppEmptyState(
                              message: 'No news published yet',
                              icon: Icons.article_outlined,
                            );
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width >= 960
                                  ? 3
                                  : width >= 620
                                  ? 2
                                  : 1;
                              final childAspectRatio = crossAxisCount == 1
                                  ? 2.1
                                  : 1.0;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: top.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                itemBuilder: (context, index) =>
                                    _NewsGridCard(news: top[index]),
                              );
                            },
                          );
                        },
                        loading: () => const AppLoadingState(
                          message: 'Loading recent news...',
                        ),
                        error: (_, __) => const AppEmptyState(
                          message: 'Could not load recent news',
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Announcements',
                        subtitle: 'Village updates and notices',
                        icon: Icons.campaign_rounded,
                        actionLabel: 'View all',
                        onActionTap: () => context.push('/announcement'),
                      ),
                      const SizedBox(height: 10),
                      announcementsAsync.when(
                        data: (items) {
                          final top = items.take(6).toList();
                          if (top.isEmpty) {
                            return const AppEmptyState(
                              message: 'No announcements yet',
                              icon: Icons.campaign_outlined,
                            );
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width >= 960
                                  ? 3
                                  : width >= 620
                                  ? 2
                                  : 1;
                              final childAspectRatio = crossAxisCount == 1
                                  ? 2.6
                                  : 1.6;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: top.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                itemBuilder: (context, index) =>
                                    _AnnouncementGridCard(
                                      announcement: top[index],
                                    ),
                              );
                            },
                          );
                        },
                        loading: () => const AppLoadingState(
                          message: 'Loading announcements...',
                        ),
                        error: (_, __) => const AppEmptyState(
                          message: 'Could not load announcements',
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Organization List',
                        subtitle: 'Village groups in grid view',
                        icon: Icons.account_tree_rounded,
                        actionLabel: 'Browse',
                        onActionTap: () =>
                            ref.read(bottomNavIndexProvider.notifier).state = 2,
                      ),
                      const SizedBox(height: 10),
                      organizationsAsync.when(
                        data: (roots) {
                          final organizations = _flattenOrganizations(
                            roots,
                          ).take(8).toList();
                          if (organizations.isEmpty) {
                            return const AppEmptyState(
                              message: 'No organizations available',
                              icon: Icons.business_rounded,
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width >= 960
                                  ? 4
                                  : width >= 700
                                  ? 3
                                  : 2;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: organizations.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1.08,
                                    ),
                                itemBuilder: (context, index) =>
                                    _OrganizationGridCard(
                                      organization: organizations[index],
                                    ),
                              );
                            },
                          );
                        },
                        loading: () => const AppLoadingState(
                          message: 'Loading organizations...',
                        ),
                        error: (_, __) => const AppEmptyState(
                          message: 'Could not load organizations',
                          icon: Icons.error_outline_rounded,
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

class _HeaderBanner extends StatelessWidget {
  final AppUser user;
  final bool isOnline;

  const _HeaderBanner({required this.user, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final today = DateFormat('EEE, d MMM').format(DateTime.now());

    return GlassCard(
      child: Row(
        children: [
          const CircularAppLogo(size: 46, padding: 1.5),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting${user.isGuest ? '' : ', ${user.fullName ?? 'friend'}'}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Liankhawpui Community Index - $today',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!isOnline) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Viewing cached data',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accentGold),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _AnnouncementGridCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementGridCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final preview = markdownExcerpt(announcement.content, maxLength: 110);
    return GlassCard(
      onTap: () => context.push('/announcement/${announcement.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                announcement.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.notifications_rounded,
                size: 16,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Text(
            timeago.format(announcement.createdAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsGridCard extends StatelessWidget {
  final News news;

  const _NewsGridCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = resolveDisplayImageUrl(
      thumbUrl: news.thumbUrl,
      coverUrl: news.coverUrl ?? firstMarkdownImageUrl(news.content),
      legacyImageUrl: news.legacyImageUrl,
    );

    return GlassCard(
      onTap: () => context.push('/news/${news.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: displayImageUrl == null
                  ? Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_rounded),
                    )
                  : AdaptiveCachedImage(
                      imageUrl: displayImageUrl,
                      fit: BoxFit.cover,
                      placeholderBuilder: (_) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      errorBuilder: (_) =>
                          const Icon(Icons.broken_image_rounded),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(news.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationGridCard extends StatelessWidget {
  final Organization organization;

  const _OrganizationGridCard({required this.organization});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/organization/${organization.id}'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if ((organization.logoUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: AdaptiveCachedImage(
                  imageUrl: organization.logoUrl!,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  errorBuilder: (_) => Icon(
                    Icons.business_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: AppColors.accentGold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            organization.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (organization.type ?? 'Institution').trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
