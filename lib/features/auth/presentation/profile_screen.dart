import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            GlassCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.accentGold.withValues(
                      alpha: 0.14,
                    ),
                    backgroundImage: user.photoUrl == null
                        ? null
                        : CachedNetworkImageProvider(user.photoUrl!),
                    child: user.photoUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppColors.accentGold,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.fullName ?? 'Community Member',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RoleBadge(role: user.role),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              title: 'My Profile',
              icon: Icons.person_outline_rounded,
              onTap: () => context.push('/profile/edit'),
            ),
            const _ActionCard(
              title: 'Saved Posts',
              subtitle: 'Coming soon',
              icon: Icons.bookmark_outline_rounded,
              enabled: false,
              onTap: null,
            ),
            _ActionCard(
              title: 'Settings',
              icon: Icons.settings_outlined,
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 8),
            _DetailItem(label: 'Phone', value: user.phoneNumber ?? 'Not set'),
            _DetailItem(
              label: 'Date of Birth',
              value: user.dob == null
                  ? 'Not set'
                  : DateFormat.yMMMd().format(user.dob!),
            ),
            _DetailItem(label: 'Address', value: user.address ?? 'Not set'),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: user.isGuest
                  ? () => context.push('/login')
                  : () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
              icon: Icon(
                user.isGuest ? Icons.login_rounded : Icons.logout_rounded,
              ),
              label: Text(user.isGuest ? 'Sign In' : 'Logout'),
            ),
          ],
        ),
      ),
    );

    if (embedded) return profileContent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: profileContent,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final roleName = role.name.toUpperCase();
    final isStaff = role.isEditor;
    final color = isStaff ? AppColors.accentGold : AppColors.primaryNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        roleName,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          enabled: enabled,
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
