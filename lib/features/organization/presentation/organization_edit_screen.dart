import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:liankhawpui/features/organization/presentation/organization_providers.dart';

class OrganizationEditScreen extends ConsumerStatefulWidget {
  final String? organizationId;

  const OrganizationEditScreen({super.key, this.organizationId});

  bool get isEditing => organizationId != null;

  @override
  ConsumerState<OrganizationEditScreen> createState() =>
      _OrganizationEditScreenState();
}

class _OrganizationEditScreenState
    extends ConsumerState<OrganizationEditScreen> {
  static const _types = <String>[
    'Council',
    'NGO',
    'Church',
    'Institution',
    'Health',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _termController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _didSeed = false;
  bool _isSaving = false;
  String? _selectedType;
  String? _selectedParentId;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _termController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizationsAsync = ref.watch(organizationListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          widget.isEditing ? 'Edit Organization' : 'New Organization',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: organizationsAsync.when(
            data: (organizations) {
              final existing = widget.organizationId == null
                  ? null
                  : _findOrganization(organizations, widget.organizationId!);
              if (widget.isEditing && existing == null) {
                return const AppEmptyState(
                  message: 'Organization not found.',
                  icon: Icons.business_center_outlined,
                );
              }

              _seedForm(existing);
              final parentOptions = _buildParentOptions(
                organizations,
                existing?.id,
              );
              final selectedParentStillValid = parentOptions.any(
                (item) => item.id == _selectedParentId,
              );
              if (!selectedParentStillValid) {
                _selectedParentId = null;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organization Information',
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
                              labelText: 'Organization name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Organization name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Select category'),
                              ),
                              ..._types.map(
                                (type) => DropdownMenuItem<String?>(
                                  value: type,
                                  child: Text(type),
                                ),
                              ),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    setState(() => _selectedType = value);
                                  },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedParentId,
                            decoration: const InputDecoration(
                              labelText: 'Parent organization',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No parent'),
                              ),
                              ...parentOptions.map(
                                (item) => DropdownMenuItem<String?>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              ),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    setState(() => _selectedParentId = value);
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contactController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact phone',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _termController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Current term',
                              hintText: '2026-2027',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 7,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Logo and staff photo uploads are intentionally excluded here. Uploads remain picker-only across the app.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveOrganization,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      widget.isEditing
                                          ? Icons.save_rounded
                                          : Icons.add_business_rounded,
                                    ),
                              label: Text(
                                _isSaving
                                    ? 'Saving...'
                                    : widget.isEditing
                                    ? 'Save Changes'
                                    : 'Create Organization',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () =>
                const AppLoadingState(message: 'Loading organization form...'),
            error: (_, __) => const AppEmptyState(
              message: 'Could not load organizations.',
              icon: Icons.error_outline_rounded,
            ),
          ),
        ),
      ),
    );
  }

  void _seedForm(Organization? existing) {
    if (_didSeed) return;
    _didSeed = true;

    if (existing == null) {
      return;
    }

    _nameController.text = existing.name;
    _contactController.text = existing.contactPhone ?? '';
    _termController.text = existing.currentTerm ?? '';
    _descriptionController.text = existing.description ?? '';
    _selectedType = existing.type?.trim().isEmpty ?? true
        ? null
        : existing.type!.trim();
    _selectedParentId = existing.parentId;
  }

  Organization? _findOrganization(List<Organization> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<_ParentOption> _buildParentOptions(
    List<Organization> organizations,
    String? currentId,
  ) {
    if (currentId == null) {
      final options = organizations
          .map((org) => _ParentOption(id: org.id, name: org.name))
          .toList();
      options.sort((left, right) => left.name.compareTo(right.name));
      return options;
    }

    final blockedIds = _collectDescendantIds(currentId, organizations)
      ..add(currentId);

    final options = organizations
        .where((org) => !blockedIds.contains(org.id))
        .map((org) => _ParentOption(id: org.id, name: org.name))
        .toList();
    options.sort((left, right) => left.name.compareTo(right.name));
    return options;
  }

  Set<String> _collectDescendantIds(
    String rootId,
    List<Organization> organizations,
  ) {
    final childrenByParent = <String, List<String>>{};
    for (final organization in organizations) {
      final parentId = organization.parentId;
      if (parentId == null) continue;
      childrenByParent
          .putIfAbsent(parentId, () => <String>[])
          .add(organization.id);
    }

    final descendants = <String>{};
    final queue = <String>[rootId];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final childId in childrenByParent[current] ?? const <String>[]) {
        if (descendants.add(childId)) {
          queue.add(childId);
        }
      }
    }
    return descendants;
  }

  Future<void> _saveOrganization() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(organizationRepositoryProvider);
      if (widget.isEditing) {
        await repository.updateOrganization(
          id: widget.organizationId!,
          name: _nameController.text,
          type: _selectedType,
          parentId: _selectedParentId,
          contactPhone: _contactController.text,
          description: _descriptionController.text,
          currentTerm: _termController.text,
        );
      } else {
        await repository.createOrganization(
          name: _nameController.text,
          type: _selectedType,
          parentId: _selectedParentId,
          contactPhone: _contactController.text,
          description: _descriptionController.text,
          currentTerm: _termController.text,
        );
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Organization updated successfully.'
                : 'Organization created successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
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

class _ParentOption {
  final String id;
  final String name;

  const _ParentOption({required this.id, required this.name});
}
