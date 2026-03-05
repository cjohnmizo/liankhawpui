import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/theme/theme_provider.dart';
import 'package:liankhawpui/core/widgets/app_logo.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = width > 700 ? 360.0 : width * 0.86;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Drawer(
      width: drawerWidth.clamp(280, 380).toDouble(),
      backgroundColor: surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariant
                  : AppColors.surfaceVariantLight,
              border: Border(
                bottom: BorderSide(color: AppColors.glassBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: _DrawerAvatar(photoUrl: user.photoUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isGuest
                            ? 'Guest'
                            : (user.fullName ?? 'Community Member'),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.isGuest
                            ? 'Sign in to access more'
                            : (user.email ?? ''),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () {
                      context.pop(); // Close drawer
                      context.go('/');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.newspaper_rounded,
                    label: 'News',
                    onTap: () {
                      context.pop();
                      context.push('/news');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.campaign_rounded,
                    label: 'Announcements',
                    onTap: () {
                      context.pop();
                      context.push('/announcement');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.business_rounded,
                    label: 'Organizations',
                    onTap: () {
                      context.pop();
                      context.push('/organization');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Directory',
                    onTap: () {
                      context.pop();
                      context.push('/book');
                    },
                  ),
                  Divider(color: AppColors.glassBorder, height: 26),
                  if (!user.isGuest) ...[
                    _DrawerItem(
                      icon: Icons.person_rounded,
                      label: 'My Profile',
                      onTap: () {
                        context.pop();
                        context.push('/profile');
                      },
                    ),
                  ],
                  if (user.role.isEditor) ...[
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Admin Dashboard',
                      isHighlight: true,
                      onTap: () {
                        context.pop();
                        context.push('/dashboard');
                      },
                    ),
                  ],
                  if (user.isGuest)
                    _DrawerItem(
                      icon: Icons.login_rounded,
                      label: 'Sign In',
                      isHighlight: true,
                      onTap: () {
                        context.pop();
                        context.push('/login');
                      },
                    )
                  else
                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      onTap: () async {
                        context.pop();
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  Divider(color: AppColors.glassBorder, height: 26),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      context.pop();
                      context.push('/settings');
                    },
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      return SwitchListTile(
                        value:
                            themeMode == ThemeMode.dark ||
                            (themeMode == ThemeMode.system && isDark),
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).state = value
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        },
                        title: Text(
                          'Dark Mode',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        secondary: Icon(
                          Icons.dark_mode_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'App Version 1.0.0',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isHighlight
              ? AppColors.accentGold
              : colorScheme.onSurfaceVariant,
          size: 22,
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight ? AppColors.accentGold : colorScheme.onSurface,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        hoverColor: AppColors.accentGold.withValues(alpha: 0.08),
      ),
    );
  }
}

class _DrawerAvatar extends StatelessWidget {
  final String? photoUrl;

  const _DrawerAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final normalized = photoUrl?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const CircularAppLogo(size: 56);
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundImage: CachedNetworkImageProvider(normalized),
      child: null,
    );
  }
}
