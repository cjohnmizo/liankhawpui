import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/providers/sync_providers.dart';
import 'package:liankhawpui/core/services/onesignal_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/theme/theme_provider.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:powersync/powersync.dart' show SyncStatus, UploadQueueStats;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lowDataMode = ref.watch(lowDataModeEnabledProvider);
    final lowDataModeAsync = ref.watch(lowDataModeProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);
    final textScaleAsync = ref.watch(textScaleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, 'Appearance'),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
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
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Enable dark theme for the app',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: const Icon(Icons.dark_mode_rounded),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.format_size_rounded),
                      title: Text(
                        'Font Size',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Adjust text size across the app',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${(textScaleFactor * 100).round()}%',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            'A',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: textScaleFactor,
                              min: 0.85,
                              max: 1.35,
                              divisions: 10,
                              label: '${(textScaleFactor * 100).round()}%',
                              onChanged: textScaleAsync.isLoading
                                  ? null
                                  : (value) {
                                      ref
                                          .read(textScaleProvider.notifier)
                                          .setScale(value);
                                    },
                            ),
                          ),
                          Text(
                            'A',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: textScaleAsync.isLoading
                                ? null
                                : () {
                                    ref
                                        .read(textScaleProvider.notifier)
                                        .reset();
                                  },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader(context, 'Network & Sync'),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: lowDataMode,
                      onChanged: lowDataModeAsync.isLoading
                          ? null
                          : (value) {
                              ref
                                  .read(lowDataModeProvider.notifier)
                                  .setEnabled(value);
                            },
                      title: Text(
                        'Low Data Mode',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Reduce image quality and bandwidth usage',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: const Icon(Icons.data_saver_off_rounded),
                    ),
                    const Divider(height: 1),
                    _SyncStatusSection(isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader(context, 'Notifications'),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    'Enable Push Notifications',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Allow announcement and news alerts on this device',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await OneSignalService.requestNotificationPermission();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification permission request sent.'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader(context, 'About'),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(
                        'Version',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: Text(
                        '1.0.0',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(
                        'Privacy Policy',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/legal/privacy'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(
                        'Terms of Service',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/legal/terms'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.groups_rounded),
                      title: Text(
                        'About App / Us',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/about'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SyncStatusSection extends ConsumerWidget {
  final bool isDark;

  const _SyncStatusSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(powerSyncServiceProvider);
    final user = ref.watch(currentUserProvider);
    final statusAsync = ref.watch(powerSyncStatusProvider);
    final queueStatsAsync = ref.watch(uploadQueueStatsProvider);
    final status = statusAsync.valueOrNull;
    final queueStats = queueStatsAsync.valueOrNull;
    final signedIn = !user.isGuest;
    final hasSyncError = _hasBlockingSyncError(
      status: status,
      statusAsync: statusAsync,
      signedIn: signedIn,
      remoteSyncEnabled: service.isRemoteSyncEnabled,
    );
    final errorMessage = _buildErrorMessage(
      status: status,
      statusAsync: statusAsync,
      hasError: hasSyncError,
    );

    final connectionLabel = _buildConnectionLabel(
      status: status,
      remoteSyncEnabled: service.isRemoteSyncEnabled,
      signedIn: signedIn,
      hasError: hasSyncError,
    );
    final lastSynced = _formatLastSynced(status?.lastSyncedAt);
    final pendingUploads = _formatQueueStats(queueStats);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSyncError
                    ? Icons.sync_problem_rounded
                    : Icons.cloud_sync_rounded,
                color: hasSyncError
                    ? AppColors.error
                    : (isDark ? AppColors.accentGold : AppColors.primaryNavy),
              ),
              const SizedBox(width: 10),
              Text(
                'Sync Status',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatusRow(label: 'Connection', value: connectionLabel),
          const SizedBox(height: 8),
          _StatusRow(label: 'Last Synced', value: lastSynced),
          const SizedBox(height: 8),
          _StatusRow(label: 'Upload Queue', value: pendingUploads),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            _StatusRow(label: 'Last Error', value: errorMessage),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: service.isRemoteSyncEnabled
                  ? () async {
                      await service.syncNow();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sync refresh requested.'),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync Now'),
            ),
          ),
        ],
      ),
    );
  }

  String _buildConnectionLabel({
    required SyncStatus? status,
    required bool remoteSyncEnabled,
    required bool signedIn,
    required bool hasError,
  }) {
    if (!remoteSyncEnabled) {
      return 'Remote sync disabled';
    }
    if (!signedIn) {
      return 'Sign in to sync';
    }
    if (status == null) {
      return 'Checking...';
    }
    if (status.connecting) {
      return 'Connecting';
    }
    if (status.downloading || status.uploading) {
      return 'Syncing';
    }
    if (status.connected) {
      return 'Connected';
    }
    if (hasError) {
      return 'Reconnecting';
    }
    return 'Offline';
  }

  bool _hasBlockingSyncError({
    required SyncStatus? status,
    required AsyncValue<SyncStatus> statusAsync,
    required bool signedIn,
    required bool remoteSyncEnabled,
  }) {
    if (!remoteSyncEnabled || !signedIn) return false;
    if (statusAsync.hasError) return true;
    if (status == null) return false;
    if (status.connected || status.connecting) return false;
    if (status.downloading || status.uploading) return false;
    return status.anyError != null;
  }

  String? _buildErrorMessage({
    required SyncStatus? status,
    required AsyncValue<SyncStatus> statusAsync,
    required bool hasError,
  }) {
    if (!hasError) return null;
    final raw = statusAsync.hasError
        ? statusAsync.error.toString()
        : status?.anyError?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return _compactError(raw);
  }

  String _compactError(String error) {
    final singleLine = error.replaceAll(RegExp(r'\s+'), ' ').trim();
    final redacted = singleLine.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
      'Bearer ***',
    );
    if (redacted.length <= 80) return redacted;
    return '${redacted.substring(0, 77)}...';
  }

  String _formatLastSynced(DateTime? value) {
    if (value == null) return 'Not yet';
    return DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
  }

  String _formatQueueStats(UploadQueueStats? stats) {
    if (stats == null) return 'Loading...';
    final sizeKb = ((stats.size ?? 0) / 1024).toStringAsFixed(1);
    return '${stats.count} items ($sizeKb KB)';
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
