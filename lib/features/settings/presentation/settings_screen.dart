import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/localization/app_strings.dart';
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
    final t = context.t;
    final themeMode = ref.watch(themeModeProvider);
    final lowDataMode = ref.watch(lowDataModeEnabledProvider);
    final lowDataModeAsync = ref.watch(lowDataModeProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);
    final textScaleAsync = ref.watch(textScaleProvider);
    final appLanguage = ref.watch(currentAppLanguageProvider);
    final appLanguageAsync = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.settings,
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
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.settings,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.settingsIntro,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PreferencePill(
                          icon: Icons.language_rounded,
                          label: t.languageName(appLanguage),
                        ),
                        _PreferencePill(
                          icon: Icons.format_size_rounded,
                          label: '${(textScaleFactor * 100).round()}%',
                        ),
                        _PreferencePill(
                          icon: lowDataMode
                              ? Icons.data_saver_on_rounded
                              : Icons.data_saver_off_rounded,
                          label: t.lowDataMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader(context, t.appearance),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: Text(
                        t.languageLabel,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        t.languageSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        t.languageName(appLanguage),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: appLanguageAsync.isLoading
                          ? null
                          : () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (sheetContext) {
                                  final sheetStrings = sheetContext.t;
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: Text(
                                            sheetStrings.languageLabel,
                                            style: AppTextStyles.titleMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          subtitle: Text(
                                            sheetStrings.languageSubtitle,
                                          ),
                                        ),
                                        RadioGroup<AppLanguage>(
                                          groupValue: appLanguage,
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            await ref
                                                .read(
                                                  appLanguageProvider.notifier,
                                                )
                                                .setLanguage(value);
                                            if (sheetContext.mounted) {
                                              Navigator.of(sheetContext).pop();
                                            }
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              for (final language
                                                  in AppLanguage.values)
                                                RadioListTile<AppLanguage>(
                                                  value: language,
                                                  title: Text(
                                                    sheetStrings.languageName(
                                                      language,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                    ),
                    const Divider(height: 1),
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
                        t.darkMode,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        t.darkModeSubtitle,
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
                        t.fontSize,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        t.fontSizeSubtitle,
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
                            child: Text(t.reset),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader(context, t.networkAndSync),
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
                        t.lowDataMode,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        t.lowDataModeSubtitle,
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
              _buildSectionHeader(context, t.notifications),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    t.enablePushNotifications,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    t.enablePushNotificationsSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await OneSignalService.requestNotificationPermission();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.notificationPermissionRequested),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader(context, t.about),
              const SizedBox(height: 10),
              GlassCard(
                isPremium: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(
                        t.version,
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
                        t.privacyPolicy,
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
                        t.termsOfService,
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
                        t.aboutAppUs,
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
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PreferencePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreferencePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusSection extends ConsumerWidget {
  final bool isDark;

  const _SyncStatusSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
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
      context: context,
      status: status,
      remoteSyncEnabled: service.isRemoteSyncEnabled,
      signedIn: signedIn,
      hasError: hasSyncError,
    );
    final lastSynced = _formatLastSynced(context, status?.lastSyncedAt);
    final pendingUploads = _formatQueueStats(context, queueStats);

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
                t.syncStatus,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _ConnectionBadge(
                label: connectionLabel,
                hasError: hasSyncError,
                isConnected: status?.connected ?? false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatusRow(label: t.connection, value: connectionLabel),
          const SizedBox(height: 8),
          _StatusRow(label: t.lastSynced, value: lastSynced),
          const SizedBox(height: 8),
          _StatusRow(label: t.uploadQueue, value: pendingUploads),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.lastError,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          errorMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                          SnackBar(content: Text(t.syncRefreshRequested)),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.sync_rounded),
              label: Text(t.syncNow),
            ),
          ),
        ],
      ),
    );
  }

  String _buildConnectionLabel({
    required BuildContext context,
    required SyncStatus? status,
    required bool remoteSyncEnabled,
    required bool signedIn,
    required bool hasError,
  }) {
    final t = context.t;
    if (!remoteSyncEnabled) {
      return t.remoteSyncDisabled;
    }
    if (!signedIn) {
      return t.signInToSync;
    }
    if (status == null) {
      return t.checking;
    }
    if (status.connecting) {
      return t.connecting;
    }
    if (status.downloading || status.uploading) {
      return t.syncing;
    }
    if (status.connected) {
      return t.connected;
    }
    if (hasError) {
      return t.reconnecting;
    }
    return t.offline;
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

  String _formatLastSynced(BuildContext context, DateTime? value) {
    if (value == null) return context.t.notYet;
    return DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
  }

  String _formatQueueStats(BuildContext context, UploadQueueStats? stats) {
    if (stats == null) return context.t.loading;
    final sizeKb = ((stats.size ?? 0) / 1024).toStringAsFixed(1);
    return '${stats.count} items ($sizeKb KB)';
  }
}

class _ConnectionBadge extends StatelessWidget {
  final String label;
  final bool hasError;
  final bool isConnected;

  const _ConnectionBadge({
    required this.label,
    required this.hasError,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = hasError
        ? AppColors.error.withValues(alpha: 0.12)
        : isConnected
        ? AppColors.success.withValues(alpha: 0.12)
        : Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final foregroundColor = hasError
        ? AppColors.error
        : isConnected
        ? AppColors.success
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
