import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Photo - Modern Design with Gradient Border
            Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(102),
                          blurRadius: 25,
                          spreadRadius: 3,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.5),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: CircleAvatar(
                          radius: 53,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          backgroundImage: user.photoUrl != null
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            _ProfileItem(
              label: 'Full Name',
              value: user.fullName ?? 'Not set',
              icon: Icons.badge,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
            _ProfileItem(
              label: 'Email',
              value: user.email ?? 'Not set',
              icon: Icons.email,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            _ProfileItem(
              label: 'Phone Number',
              value: user.phoneNumber ?? '+91',
              icon: Icons.phone,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
            _ProfileItem(
              label: 'Date of Birth',
              value: user.dob != null
                  ? DateFormat.yMMMd().format(user.dob!)
                  : 'Not set',
              icon: Icons.cake,
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
            _ProfileItem(
              label: 'Address',
              value: user.address ?? 'Not set',
              icon: Icons.location_on,
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
            _ProfileItem(
              label: 'Role',
              value: user.role.name.toUpperCase(),
              icon: Icons.security,
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}
