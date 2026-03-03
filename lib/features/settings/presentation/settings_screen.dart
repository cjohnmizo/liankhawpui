import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/providers/sync_providers.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/theme/theme_provider.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:powersync/powersync.dart' show SyncStatus, UploadQueueStats;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lowDataMode = ref.watch(lowDataModeEnabledProvider);
    final lowDataModeAsync = ref.watch(lowDataModeProvider);
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
                child: SwitchListTile(
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
    final statusAsync = ref.watch(powerSyncStatusProvider);
    final queueStatsAsync = ref.watch(uploadQueueStatsProvider);
    final status = statusAsync.valueOrNull;
    final queueStats = queueStatsAsync.valueOrNull;
    final hasSyncError = status?.anyError != null || statusAsync.hasError;

    final connectionLabel = _buildConnectionLabel(
      status: status,
      remoteSyncEnabled: service.isRemoteSyncEnabled,
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
    required bool hasError,
  }) {
    if (!remoteSyncEnabled) {
      return 'Remote sync disabled';
    }
    if (status == null) {
      return 'Checking...';
    }
    if (hasError) {
      return 'Error';
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
    return 'Offline';
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
