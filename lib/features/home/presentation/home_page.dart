import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/config/app_assets.dart';
import 'package:liankhawpui/core/localization/app_strings.dart';
import 'package:liankhawpui/core/providers/network_status_provider.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_drawer.dart';
import 'package:liankhawpui/core/widgets/app_logo.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/announcement/domain/announcement.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:liankhawpui/features/auth/domain/app_user.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/news/domain/news.dart';
import 'package:liankhawpui/features/news/presentation/news_providers.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(networkOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(context, user),
      body: _buildHomeDashboard(context, ref),
      floatingActionButton: user.role.isEditor
          ? FloatingActionButton(
              heroTag: 'home_create_fab',
              onPressed: isOnline ? () => _showCreateMenu(context) : null,
              tooltip: isOnline
                  ? t.createPost
                  : t.offlineReconnectToCreateContent,
              child: Icon(
                isOnline ? Icons.add_rounded : Icons.wifi_off_rounded,
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppUser user) {
    final t = context.t;
    const title = 'Liankhawpui';

    return AppBar(
      titleSpacing: 12,
      leading: IconButton(
        key: const ValueKey('home_menu_button'),
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          const CircularAppLogo(size: 30, padding: 1.2),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        if (user.role.isEditor)
          IconButton(
            tooltip: t.dashboard,
            icon: const Icon(Icons.dashboard_rounded),
            onPressed: () => context.push('/dashboard'),
          ),
        IconButton(
          key: const ValueKey('home_profile_button'),
          tooltip: user.isGuest ? t.signIn : t.profile,
          icon: _buildProfileActionIcon(user),
          onPressed: () =>
              user.isGuest ? context.push('/login') : context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildProfileActionIcon(AppUser user) {
    final photoUrl = user.photoUrl?.trim();
    if (user.isGuest || photoUrl == null || photoUrl.isEmpty) {
      return const Icon(Icons.person_rounded);
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.surfaceVariant,
      backgroundImage: CachedNetworkImageProvider(photoUrl),
    );
  }

  Widget _buildHomeDashboard(BuildContext context, WidgetRef ref) {
    final t = context.t;
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
                      _HeaderBanner(isOnline: isOnline),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        titleKey: const ValueKey('home_section_recent_news'),
                        title: t.recentNews,
                        subtitle: t.latestStoriesFromVillage,
                        icon: Icons.newspaper_rounded,
                        actionLabel: t.openNews,
                        onActionTap: () => context.push('/news'),
                      ),
                      const SizedBox(height: 10),
                      newsAsync.when(
                        data: (items) {
                          final top = items.take(5).toList();
                          if (top.isEmpty) {
                            return AppEmptyState(
                              message: t.noNewsPublishedYet,
                              icon: Icons.article_outlined,
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: top.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _NewsListCard(news: top[index]),
                          );
                        },
                        loading: () =>
                            AppLoadingState(message: t.loadingRecentNews),
                        error: (_, __) => AppEmptyState(
                          message: t.couldNotLoadRecentNews,
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        titleKey: const ValueKey('home_section_announcements'),
                        title: t.announcements,
                        subtitle: t.villageUpdatesAndNotices,
                        icon: Icons.campaign_rounded,
                        actionLabel: t.viewAll,
                        onActionTap: () => context.push('/announcement'),
                      ),
                      const SizedBox(height: 10),
                      announcementsAsync.when(
                        data: (items) {
                          final top = items.take(3).toList();
                          if (top.isEmpty) {
                            return AppEmptyState(
                              message: t.noAnnouncementsYet,
                              icon: Icons.campaign_outlined,
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: top.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _AnnouncementListCard(announcement: top[index]),
                          );
                        },
                        loading: () =>
                            AppLoadingState(message: t.loadingAnnouncements),
                        error: (_, __) => AppEmptyState(
                          message: t.couldNotLoadAnnouncements,
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        titleKey: const ValueKey('home_section_organizations'),
                        title: t.organizationList,
                        subtitle: t.villageGroupsInGridView,
                        icon: Icons.account_tree_rounded,
                        actionLabel: t.browse,
                        onActionTap: () => context.push('/organization'),
                      ),
                      const SizedBox(height: 10),
                      organizationsAsync.when(
                        data: (roots) {
                          final organizations = _flattenOrganizations(
                            roots,
                          ).take(8).toList();
                          if (organizations.isEmpty) {
                            return AppEmptyState(
                              message: t.noOrganizationsAvailable,
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
                                      childAspectRatio: 1.0,
                                    ),
                                itemBuilder: (context, index) =>
                                    _OrganizationGridCard(
                                      organization: organizations[index],
                                    ),
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
    final t = context.t;
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
                title: Text(t.newsArticle),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/dashboard/news/create');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_rounded),
                title: Text(t.announcement),
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
  final bool isOnline;

  const _HeaderBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AppAssets.landscape, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.56),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                right: 14,
                child: Row(
                  children: [
                    const CircularAppLogo(size: 34, padding: 1.8),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t.khawlianVillage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liankhawpui',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.newsAnnouncementsOrganizations,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BannerTag(
                          icon: Icons.campaign_rounded,
                          label: t.announcements,
                        ),
                        _BannerTag(
                          icon: Icons.newspaper_rounded,
                          label: t.recentNews,
                        ),
                        _BannerTag(
                          icon: Icons.account_tree_rounded,
                          label: t.organizations,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isOnline)
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.offlineCache,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

class _SectionHeader extends StatelessWidget {
  final Key? titleKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    this.titleKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.accentGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: titleKey,
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
          TextButton(
            onPressed: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _BannerTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BannerTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementListCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementListCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final preview = markdownExcerpt(announcement.content, maxLength: 120);
    return GlassCard(
      onTap: () => context.push('/announcement/${announcement.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 88,
            decoration: BoxDecoration(
              color: announcement.isPinned
                  ? AppColors.accentGold
                  : AppColors.primaryNavyLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (announcement.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.pinned,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeago.format(announcement.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsListCard extends StatelessWidget {
  final News news;

  const _NewsListCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = resolveListImageUrl(
      thumbUrl: news.thumbUrl,
      coverUrl: news.coverUrl ?? firstMarkdownImageUrl(news.content),
      legacyImageUrl: news.legacyImageUrl,
    );
    final preview = markdownExcerpt(news.content, maxLength: 80);

    return GlassCard(
      onTap: () => context.push('/news/${news.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 104,
              height: 92,
              child: displayImageUrl == null
                  ? Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if ((organization.logoUrl ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.accentGold,
                  ),
                ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            organization.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              (organization.type ?? 'Institution').trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
