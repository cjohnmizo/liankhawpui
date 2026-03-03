import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accentGold.withValues(alpha: 0.14),
                  backgroundImage: user.photoUrl == null
                      ? null
                      : CachedNetworkImageProvider(user.photoUrl!),
                  child: user.photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: AppColors.accentGold,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _ProfileItem(
                label: 'Full Name',
                value: user.fullName ?? 'Not set',
              ),
              _ProfileItem(label: 'Email', value: user.email ?? 'Not set'),
              _ProfileItem(
                label: 'Phone Number',
                value: user.phoneNumber ?? 'Not set',
              ),
              _ProfileItem(
                label: 'Date of Birth',
                value: user.dob == null
                    ? 'Not set'
                    : DateFormat.yMMMd().format(user.dob!),
              ),
              _ProfileItem(label: 'Address', value: user.address ?? 'Not set'),
              _ProfileItem(label: 'Role', value: user.role.name.toUpperCase()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            const SizedBox(width: 8),
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
