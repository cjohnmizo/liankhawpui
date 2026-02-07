import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.backgroundGradient
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryNavy,
                        AppColors.primaryNavyLight,
                      ],
                    ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.glassBorder.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGold, width: 2),
                  ),
                  child: const CircularAppLogo(size: 56),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isGuest
                            ? 'Guest'
                            : (user.fullName ?? 'Community Member'),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isGuest
                            ? 'Sign in to access more'
                            : (user.email ?? ''),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
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

          // Drawer Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                  Divider(color: AppColors.glassBorder, height: 32),
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
                  Divider(color: AppColors.glassBorder, height: 32),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        secondary: Icon(
                          Icons.dark_mode_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(24.0),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isHighlight
              ? AppColors.accentGold
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight ? AppColors.accentGold : colorScheme.onSurface,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        hoverColor: AppColors.accentGold.withValues(alpha: 0.1),
      ),
    );
  }
}
