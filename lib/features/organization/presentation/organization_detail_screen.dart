import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/services/image_service.dart';
import 'package:liankhawpui/core/services/storage_budget_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/adaptive_cached_image.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/organization/domain/office_bearer.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganizationDetailScreen extends ConsumerWidget {
  final String orgId;

  const OrganizationDetailScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(organizationTreeProvider);
    final officeBearersAsync = ref.watch(officeBearersProvider(orgId));
    final currentUser = ref.watch(currentUserProvider);
    final storageBudgetAsync = ref.watch(storageBudgetProvider);
    final canManage = currentUser.role.isEditor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Organization Details'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Edit organization',
              onPressed: () =>
                  context.push('/dashboard/organizations/edit/$orgId'),
              icon: const Icon(Icons.edit_rounded),
            ),
          if (canManage)
            IconButton(
              tooltip: 'Delete organization',
              onPressed: () => _deleteOrganization(context, ref),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: treeAsync.when(
            data: (roots) {
              final org = _findOrg(roots, orgId);
              if (org == null) {
                return const AppEmptyState(
                  message: 'Organization not found',
                  icon: Icons.business_center_outlined,
                );
              }

              final parent = _findParent(roots, orgId);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OrgAvatar(url: org.logoUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                org.name,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoChip(
                                    icon: Icons.label_outline_rounded,
                                    label: _typeLabel(org.type),
                                  ),
                                  if ((org.currentTerm ?? '').trim().isNotEmpty)
                                    _InfoChip(
                                      icon: Icons.event_note_rounded,
                                      label: 'Term: ${org.currentTerm!.trim()}',
                                    ),
                                  if ((org.contactPhone ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    _InfoChip(
                                      icon: Icons.call_rounded,
                                      label:
                                          'Phone: ${org.contactPhone!.trim()}',
                                    ),
                                  if (parent != null)
                                    _InfoChip(
                                      icon: Icons.account_tree_rounded,
                                      label: 'Parent: ${parent.name}',
                                    ),
                                  if (org.children.isNotEmpty)
                                    _InfoChip(
                                      icon: Icons.groups_rounded,
                                      label:
                                          'Child groups: ${org.children.length}',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _uploadOrganizationLogo(context, ref, org),
                          icon: const Icon(Icons.add_a_photo_rounded),
                          label: Text(
                            (org.logoUrl ?? '').trim().isEmpty
                                ? 'Upload Logo'
                                : 'Replace Logo',
                          ),
                        ),
                        if ((org.logoUrl ?? '').trim().isNotEmpty)
                          TextButton.icon(
                            onPressed: () =>
                                _removeOrganizationLogo(context, ref, org),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                            label: const Text(
                              'Remove Logo',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                    storageBudgetAsync.when(
                      data: (budget) {
                        if (budget.percentOf1GB < 80) {
                          return const SizedBox.shrink();
                        }
                        final blocked = budget.percentOf1GB >= 95;
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: GlassCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  blocked
                                      ? Icons.warning_amber_rounded
                                      : Icons.storage_rounded,
                                  color: blocked
                                      ? AppColors.error
                                      : AppColors.accentGold,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    blocked
                                        ? 'Storage is almost full (${budget.percentOf1GB.toStringAsFixed(1)}% of 1 GB). New uploads are blocked.'
                                        : 'Storage nearing limit (${budget.percentOf1GB.toStringAsFixed(1)}% of 1 GB used).',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                  if ((org.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'About',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassCard(
                      child: Text(
                        org.description!.trim(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Office Bearers',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canManage)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showOfficeBearerSheet(context, orgId: org.id),
                          icon: const Icon(Icons.person_add_alt_rounded),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  officeBearersAsync.when(
                    data: (bearers) {
                      if (bearers.isEmpty) {
                        return GlassCard(
                          child: Text(
                            canManage
                                ? 'No office bearers listed yet. Add members to complete the organization profile.'
                                : 'No office bearers listed yet.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final bearer in bearers)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: bearer.photoUrl == null
                                            ? Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                ),
                                              )
                                            : AdaptiveCachedImage(
                                                imageUrl: bearer.photoUrl!,
                                                fit: BoxFit.cover,
                                                cacheWidth: 120,
                                                cacheHeight: 120,
                                                placeholderBuilder: (_) =>
                                                    Container(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                    ),
                                                errorBuilder: (_) => const Icon(
                                                  Icons.person_rounded,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bearer.name,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            bearer.position,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          if ((bearer.phone ?? '')
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              bearer.phone!.trim(),
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () => _callOfficeBearer(
                                                    context,
                                                    bearer.phone!,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.call_rounded,
                                                    size: 16,
                                                  ),
                                                  label: const Text('Call'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _openWhatsAppForOfficeBearer(
                                                        context,
                                                        bearer.phone!,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.chat_rounded,
                                                    size: 16,
                                                  ),
                                                  label: const Text('WhatsApp'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (canManage)
                                      PopupMenuButton<String>(
                                        tooltip: 'Manage office bearer',
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            await _showOfficeBearerSheet(
                                              context,
                                              orgId: org.id,
                                              bearer: bearer,
                                            );
                                            return;
                                          }
                                          if (value == 'upload_photo') {
                                            await _uploadOfficeBearerPhoto(
                                              context,
                                              ref,
                                              bearer,
                                            );
                                            return;
                                          }
                                          if (value == 'remove_photo') {
                                            await _removeOfficeBearerPhoto(
                                              context,
                                              ref,
                                              bearer,
                                            );
                                            return;
                                          }
                                          await _deleteOfficeBearer(
                                            context,
                                            ref,
                                            bearer,
                                          );
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_rounded),
                                              title: Text('Edit'),
                                              contentPadding: EdgeInsets.zero,
                                              minLeadingWidth: 18,
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'upload_photo',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.add_a_photo_rounded,
                                              ),
                                              title: Text('Upload Photo'),
                                              contentPadding: EdgeInsets.zero,
                                              minLeadingWidth: 18,
                                            ),
                                          ),
                                          if ((bearer.photoUrl ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            const PopupMenuItem<String>(
                                              value: 'remove_photo',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons
                                                      .image_not_supported_rounded,
                                                ),
                                                title: Text('Remove Photo'),
                                                contentPadding: EdgeInsets.zero,
                                                minLeadingWidth: 18,
                                              ),
                                            ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.delete_outline_rounded,
                                                color: AppColors.error,
                                              ),
                                              title: Text('Delete'),
                                              contentPadding: EdgeInsets.zero,
                                              minLeadingWidth: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const AppLoadingState(
                      message: 'Loading office bearers...',
                    ),
                    error: (error, _) => AppEmptyState(
                      message: 'Could not load office bearers: $error',
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoadingState(
              message: 'Loading organization details...',
            ),
            error: (error, _) => AppEmptyState(
              message: 'Could not load details: $error',
              icon: Icons.error_outline_rounded,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteOrganization(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization?'),
        content: const Text(
          'Child organizations must be removed first. Office bearers will be removed with this organization.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(organizationRepositoryProvider).deleteOrganization(orgId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Organization deleted.')));
      context.go('/dashboard/organizations');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _showOfficeBearerSheet(
    BuildContext context, {
    required String orgId,
    OfficeBearer? bearer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _OfficeBearerEditorSheet(orgId: orgId, bearer: bearer),
    );
  }

  Future<void> _deleteOfficeBearer(
    BuildContext context,
    WidgetRef ref,
    OfficeBearer bearer,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Office Bearer?'),
        content: Text('Remove ${bearer.name} from this organization?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await ref
        .read(organizationRepositoryProvider)
        .deleteOfficeBearer(bearer.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${bearer.name} removed.')));
  }

  Future<void> _uploadOrganizationLogo(
    BuildContext context,
    WidgetRef ref,
    Organization organization,
  ) async {
    if (!_canUploadMore(context, ref)) return;
    final file = await _pickImageFile(context, ref);
    if (file == null) return;

    try {
      final lowDataMode = ref.read(lowDataModeEnabledProvider);
      await ref
          .read(organizationRepositoryProvider)
          .uploadOrganizationLogo(
            organizationId: organization.id,
            imageFile: file,
            lowDataMode: lowDataMode,
          );
      ref.invalidate(storageBudgetProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logo updated.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logo upload failed: $error')));
    }
  }

  Future<void> _removeOrganizationLogo(
    BuildContext context,
    WidgetRef ref,
    Organization organization,
  ) async {
    try {
      await ref
          .read(organizationRepositoryProvider)
          .removeOrganizationLogo(organization.id);
      ref.invalidate(storageBudgetProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logo removed.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove logo: $error')));
    }
  }

  Future<void> _uploadOfficeBearerPhoto(
    BuildContext context,
    WidgetRef ref,
    OfficeBearer bearer,
  ) async {
    if (!_canUploadMore(context, ref)) return;
    final file = await _pickImageFile(context, ref);
    if (file == null) return;

    try {
      final lowDataMode = ref.read(lowDataModeEnabledProvider);
      await ref
          .read(organizationRepositoryProvider)
          .uploadOfficeBearerPhoto(
            bearerId: bearer.id,
            imageFile: file,
            lowDataMode: lowDataMode,
          );
      ref.invalidate(storageBudgetProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${bearer.name} photo updated.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo upload failed: $error')));
    }
  }

  Future<void> _removeOfficeBearerPhoto(
    BuildContext context,
    WidgetRef ref,
    OfficeBearer bearer,
  ) async {
    try {
      await ref
          .read(organizationRepositoryProvider)
          .removeOfficeBearerPhoto(bearer.id);
      ref.invalidate(storageBudgetProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${bearer.name} photo removed.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove photo: $error')));
    }
  }

  bool _canUploadMore(BuildContext context, WidgetRef ref) {
    final budget = ref.read(storageBudgetProvider).valueOrNull;
    if ((budget?.percentOf1GB ?? 0) < 95) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Storage is almost full. Delete old attachments or reduce uploads.',
        ),
      ),
    );
    return false;
  }

  Future<ImageSource?> _pickImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickImageFile(BuildContext context, WidgetRef ref) async {
    final source = await _pickImageSource(context);
    if (source == null) return null;

    final imageService = ImageService();
    final lowDataMode = ref.read(lowDataModeEnabledProvider);
    if (source == ImageSource.gallery) {
      return imageService.pickImageFromGallery(lowDataMode: lowDataMode);
    }
    return imageService.pickImageFromCamera(lowDataMode: lowDataMode);
  }

  Organization? _findOrg(List<Organization> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = _findOrg(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  Organization? _findParent(List<Organization> nodes, String id) {
    for (final node in nodes) {
      for (final child in node.children) {
        if (child.id == id) return node;
      }
      final found = _findParent(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  String _typeLabel(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'Institution';
    }
    return normalized;
  }

  Future<void> _callOfficeBearer(BuildContext context, String rawPhone) async {
    final telPhone = _normalizePhoneForTel(rawPhone);
    if (telPhone == null) {
      _showContactLaunchError(context, 'Phone number is not valid for calling.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: telPhone);
    await _launchContactUri(
      context,
      uri,
      fallbackMessage: 'Could not start a phone call on this device.',
    );
  }

  Future<void> _openWhatsAppForOfficeBearer(
    BuildContext context,
    String rawPhone,
  ) async {
    final whatsappPhone = _normalizePhoneForWhatsApp(rawPhone);
    if (whatsappPhone == null) {
      _showContactLaunchError(
        context,
        'Phone number is not valid for WhatsApp.',
      );
      return;
    }

    final uri = Uri.parse('https://wa.me/$whatsappPhone');
    await _launchContactUri(
      context,
      uri,
      fallbackMessage: 'Could not open WhatsApp on this device.',
    );
  }

  Future<void> _launchContactUri(
    BuildContext context,
    Uri uri, {
    required String fallbackMessage,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showContactLaunchError(context, fallbackMessage);
      }
    } catch (_) {
      if (context.mounted) {
        _showContactLaunchError(context, fallbackMessage);
      }
    }
  }

  void _showContactLaunchError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _normalizePhoneForTel(String rawPhone) {
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return null;

    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return null;

    final hasTooManyPlus =
        '+'.allMatches(cleaned).length > 1 || cleaned.indexOf('+') > 0;
    if (hasTooManyPlus) return null;

    final digitsOnly = cleaned.replaceAll('+', '');
    if (digitsOnly.length < 7) return null;
    return cleaned;
  }

  String? _normalizePhoneForWhatsApp(String rawPhone) {
    final telPhone = _normalizePhoneForTel(rawPhone);
    if (telPhone == null) return null;

    final digitsOnly = telPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7) return null;
    return digitsOnly;
  }
}

class _OrgAvatar extends StatelessWidget {
  final String? url;

  const _OrgAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    if ((url ?? '').isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.accentGold.withValues(alpha: 0.14),
        ),
        child: const Icon(Icons.business_rounded, color: AppColors.accentGold),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        height: 58,
        child: AdaptiveCachedImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          cacheWidth: 174,
          cacheHeight: 174,
          placeholderBuilder: (_) =>
              Container(color: AppColors.surfaceVariantLight),
          errorBuilder: (_) => const Icon(Icons.business_rounded),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficeBearerEditorSheet extends ConsumerStatefulWidget {
  final String orgId;
  final OfficeBearer? bearer;

  const _OfficeBearerEditorSheet({required this.orgId, this.bearer});

  bool get isEditing => bearer != null;

  @override
  ConsumerState<_OfficeBearerEditorSheet> createState() =>
      _OfficeBearerEditorSheetState();
}

class _OfficeBearerEditorSheetState
    extends ConsumerState<_OfficeBearerEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rankController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.bearer?.name ?? '';
    _positionController.text = widget.bearer?.position ?? '';
    _phoneController.text = widget.bearer?.phone ?? '';
    _rankController.text = '${widget.bearer?.rankOrder ?? 0}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _rankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit Office Bearer' : 'Add Office Bearer',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Position is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rankController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Display order',
                  helperText: 'Lower numbers appear first.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.isEditing
                              ? Icons.save_rounded
                              : Icons.person_add_alt_rounded,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : widget.isEditing
                        ? 'Save Changes'
                        : 'Add Office Bearer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final repository = ref.read(organizationRepositoryProvider);
    final rankOrder = int.tryParse(_rankController.text.trim()) ?? 0;

    try {
      if (widget.isEditing) {
        await repository.updateOfficeBearer(
          id: widget.bearer!.id,
          name: _nameController.text,
          position: _positionController.text,
          phone: _phoneController.text,
          rankOrder: rankOrder,
        );
      } else {
        await repository.createOfficeBearer(
          orgId: widget.orgId,
          name: _nameController.text,
          position: _positionController.text,
          phone: _phoneController.text,
          rankOrder: rankOrder,
        );
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Office bearer updated.'
                : 'Office bearer added.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
