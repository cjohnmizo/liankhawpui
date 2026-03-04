import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/dashboard/presentation/dashboard_providers.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';

const bool kTestMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

class ManageUsersScreen extends ConsumerStatefulWidget {
  final UserRole? initialRole;
  const ManageUsersScreen({super.key, this.initialRole});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _selectedRole; // Null means "All"
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser.role.isAdmin || kTestMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'manage_users_add_fab',
              onPressed: _isBusy ? null : () => _showAddUserDialog(context),
              backgroundColor: AppColors.accentGold,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Theme.of(context).colorScheme.onSurface,
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isAdmin ? 'Manage Users' : 'User Directory',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.invalidate(allProfilesProvider);
                          _showMessage('Refreshing users...');
                        },
                        icon: const Icon(Icons.sync_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: GlassCard(
                    isPremium: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    borderRadius: 12,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by email or name...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      ...UserRole.values.map(
                        (role) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            role.name.toUpperCase(),
                            role,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: profilesAsync.when(
                    data: (profiles) {
                      final filteredProfiles = profiles.where((user) {
                        if (_selectedRole != null &&
                            user.role != _selectedRole) {
                          return false;
                        }
                        final query = _searchQuery.toLowerCase();
                        final email = user.email?.toLowerCase() ?? '';
                        final name = user.fullName?.toLowerCase() ?? '';
                        return email.contains(query) || name.contains(query);
                      }).toList();

                      if (filteredProfiles.isEmpty) {
                        return Center(
                          child: Text(
                            _searchQuery.isEmpty && _selectedRole == null
                                ? 'No users found'
                                : 'No matches found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(allProfilesProvider);
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                          itemCount: filteredProfiles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final profile = filteredProfiles[index];
                            return _buildUserCard(profile, isDark, isAdmin);
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, UserRole? role) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRole = selected ? role : null;
        });
      },
      selectedColor: AppColors.accentGold,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.backgroundDark : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserCard(profile, bool isDark, bool isAdmin) {
    return GlassCard(
      isPremium: false,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.person_rounded,
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
                      profile.fullName ?? profile.email ?? 'No Name',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.fullName != null)
                      Text(
                        profile.email ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Role Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.glassBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: profile.role,
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    disabledHint: Text(profile.role.name.toUpperCase()),
                    dropdownColor: isDark
                        ? AppColors.surfaceVariant
                        : AppColors.surfaceLight,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    items: UserRole.values
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: isAdmin && !_isBusy
                        ? (newRole) async {
                            if (newRole != null && newRole != profile.role) {
                              await _runAdminAction(
                                () => ref
                                    .read(dashboardRepositoryProvider)
                                    .updateUserRole(profile.id, newRole),
                                successMessage:
                                    'Role updated to ${newRole.name.toUpperCase()}',
                              );
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Actions based on role
              if (profile.role == UserRole.guest) ...[
                TextButton.icon(
                  onPressed: isAdmin && !_isBusy
                      ? () => _confirmDecline(profile)
                      : null,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Decline',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: isAdmin && !_isBusy
                      ? () async {
                          await _runAdminAction(
                            () => ref
                                .read(dashboardRepositoryProvider)
                                .approveUser(profile.id),
                            successMessage: 'User approved.',
                          );
                        }
                      : null,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: Colors.green,
                  ),
                  label: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: isAdmin && !_isBusy
                      ? () => _confirmDelete(profile)
                      : null,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    UserRole selectedRole = UserRole.user;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    helperText: 'At least 6 characters',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: UserRole.values
                      .where((role) => role != UserRole.guest)
                      .map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.name.toUpperCase()),
                        );
                      })
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRole = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty ||
                            nameController.text.isEmpty) {
                          _showMessage(
                            'Please fill all fields.',
                            isError: true,
                          );
                          return;
                        }
                        if (passwordController.text.trim().length < 6) {
                          _showMessage(
                            'Password must be at least 6 characters.',
                            isError: true,
                          );
                          return;
                        }

                        setState(() => isSubmitting = true);
                        try {
                          await _runAdminAction(
                            () => ref
                                .read(dashboardRepositoryProvider)
                                .createUser(
                                  email: emailController.text,
                                  password: passwordController.text,
                                  fullName: nameController.text,
                                  role: selectedRole,
                                ),
                            successMessage: 'User account created.',
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.backgroundDark,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${profile.email ?? 'this user'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _runAdminAction(
                () => ref
                    .read(dashboardRepositoryProvider)
                    .deleteUser(profile.id),
                successMessage: 'User deleted.',
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDecline(profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request'),
        content: Text(
          'Are you sure you want to decline the request for ${profile.email ?? 'this user'}? This will remove the account request permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _runAdminAction(
                () => ref
                    .read(dashboardRepositoryProvider)
                    .deleteUser(profile.id),
                successMessage: 'Request declined.',
              );
            },
            child: const Text(
              'Decline',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAdminAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
      ref.invalidate(allProfilesProvider);
      _showMessage(successMessage);
    } catch (e) {
      _showMessage(_friendlyError(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.contains('User already registered')) {
      return 'Email already exists.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Invalid credentials.';
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.accentGold,
      ),
    );
  }
}
