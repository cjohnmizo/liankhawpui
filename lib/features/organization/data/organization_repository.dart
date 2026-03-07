import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:liankhawpui/core/services/image_service.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/services/storage_budget_service.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/features/organization/domain/office_bearer.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class OrganizationRepository {
  static const String _mediaBucket = 'post-attachments';
  static const int _maxImageInputBytes = 15 * 1024 * 1024;
  static const String _logoCacheControl = 'public, max-age=31536000, immutable';
  static const String _memberPhotoCacheControl =
      'public, max-age=31536000, immutable';

  final _powerSync = PowerSyncService();
  final _imageService = ImageService();
  final _storageBudgetService = StorageBudgetService();
  final _uuid = const Uuid();

  Future<PowerSyncDatabase> _ensureDb() async {
    await _powerSync.ensureLocalDatabaseReady();
    return _powerSync.db;
  }

  Stream<List<Organization>> watchOrganizations() async* {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (error) {
      debugPrint('watchOrganizations failed to initialize local DB: $error');
      yield const <Organization>[];
      return;
    }

    yield* db
        .watch('SELECT * FROM organizations ORDER BY name COLLATE NOCASE ASC')
        .map(
          (results) => results.map((row) => Organization.fromRow(row)).toList(),
        )
        .handleError((error) {
          debugPrint('watchOrganizations stream error: $error');
        });
  }

  Future<List<Organization>> getAllOrganizations() async {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (_) {
      return const <Organization>[];
    }
    final result = await db.getAll(
      'SELECT * FROM organizations ORDER BY name ASC',
    );
    return result.map((row) => Organization.fromRow(row)).toList();
  }

  Stream<List<Organization>> watchOrganizationTree() {
    return watchOrganizations().map(_buildTree);
  }

  Future<List<Organization>> getOrganizationTree() async {
    final allOrgs = await getAllOrganizations();
    return _buildTree(allOrgs);
  }

  Future<List<OfficeBearer>> getOfficeBearers(String orgId) async {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (_) {
      return const <OfficeBearer>[];
    }
    final result = await db.getAll(
      'SELECT * FROM office_bearers WHERE org_id = ? ORDER BY rank_order ASC',
      [orgId],
    );
    return result.map((row) => OfficeBearer.fromRow(row)).toList();
  }

  Stream<List<OfficeBearer>> watchOfficeBearers(String orgId) async* {
    late final PowerSyncDatabase db;
    try {
      db = await _ensureDb();
    } catch (error) {
      debugPrint('watchOfficeBearers failed to initialize local DB: $error');
      yield const <OfficeBearer>[];
      return;
    }

    yield* db
        .watch(
          '''
          SELECT * FROM office_bearers
          WHERE org_id = ?
          ORDER BY rank_order ASC, name COLLATE NOCASE ASC
          ''',
          parameters: [orgId],
        )
        .map(
          (results) => results.map((row) => OfficeBearer.fromRow(row)).toList(),
        )
        .handleError((error) {
          debugPrint('watchOfficeBearers stream error: $error');
        });
  }

  Future<Organization?> getOrganizationById(String id) async {
    final db = await _ensureDb();
    final row = await db.getOptional(
      'SELECT * FROM organizations WHERE id = ? LIMIT 1',
      [id],
    );
    if (row == null) return null;
    return Organization.fromRow(row);
  }

  Future<String> createOrganization({
    required String name,
    String? type,
    String? parentId,
    String? contactPhone,
    String? description,
    String? currentTerm,
  }) async {
    final db = await _ensureDb();
    final id = _uuid.v4();

    await db.execute(
      '''
      INSERT INTO organizations (
        id, name, type, parent_id, logo_url, contact_phone, description, current_term
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        _requiredValue(name, field: 'name'),
        _optionalValue(type),
        _optionalValue(parentId),
        null,
        _optionalValue(contactPhone),
        _optionalValue(description),
        _optionalValue(currentTerm),
      ],
    );

    return id;
  }

  Future<void> updateOrganization({
    required String id,
    required String name,
    String? type,
    String? parentId,
    String? contactPhone,
    String? description,
    String? currentTerm,
  }) async {
    final db = await _ensureDb();
    final normalizedParentId = _optionalValue(parentId);

    await db.execute(
      '''
      UPDATE organizations
      SET name = ?, type = ?, parent_id = ?, contact_phone = ?, description = ?, current_term = ?
      WHERE id = ?
      ''',
      [
        _requiredValue(name, field: 'name'),
        _optionalValue(type),
        normalizedParentId == id ? null : normalizedParentId,
        _optionalValue(contactPhone),
        _optionalValue(description),
        _optionalValue(currentTerm),
        id,
      ],
    );
  }

  Future<void> deleteOrganization(String id) async {
    final db = await _ensureDb();
    final child = await db.getOptional(
      'SELECT id FROM organizations WHERE parent_id = ? LIMIT 1',
      [id],
    );
    if (child != null) {
      throw StateError('Remove child organizations before deleting this one.');
    }

    await db.execute('DELETE FROM office_bearers WHERE org_id = ?', [id]);
    await db.execute('DELETE FROM organizations WHERE id = ?', [id]);
  }

  Future<String> createOfficeBearer({
    required String orgId,
    required String name,
    required String position,
    String? phone,
    int rankOrder = 0,
  }) async {
    final db = await _ensureDb();
    final id = _uuid.v4();

    await db.execute(
      '''
      INSERT INTO office_bearers (id, org_id, name, position, phone, photo_url, rank_order)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        orgId,
        _requiredValue(name, field: 'name'),
        _requiredValue(position, field: 'position'),
        _optionalValue(phone),
        null,
        rankOrder,
      ],
    );

    return id;
  }

  Future<void> updateOfficeBearer({
    required String id,
    required String name,
    required String position,
    String? phone,
    int rankOrder = 0,
  }) async {
    final db = await _ensureDb();

    await db.execute(
      '''
      UPDATE office_bearers
      SET name = ?, position = ?, phone = ?, rank_order = ?
      WHERE id = ?
      ''',
      [
        _requiredValue(name, field: 'name'),
        _requiredValue(position, field: 'position'),
        _optionalValue(phone),
        rankOrder,
        id,
      ],
    );
  }

  Future<void> deleteOfficeBearer(String id) async {
    final db = await _ensureDb();
    await db.execute('DELETE FROM office_bearers WHERE id = ?', [id]);
  }

  Future<String> uploadOrganizationLogo({
    required String organizationId,
    required File imageFile,
    required bool lowDataMode,
  }) async {
    final organization = await getOrganizationById(organizationId);
    if (organization == null) {
      throw StateError('Organization not found.');
    }

    final processed = await _prepareImageForUpload(
      imageFile,
      preset: MediaPreset.ngoLogo,
    );
    final objectPath = await _uploadImageBytes(
      bytes: processed.bytes,
      folder: 'organization-logos',
      entityId: organizationId,
      contentType: processed.contentType,
      cacheControl: _logoCacheControl,
    );
    final publicUrl = SupabaseService.client.storage
        .from(_mediaBucket)
        .getPublicUrl(objectPath);

    final db = await _ensureDb();
    await db.execute('UPDATE organizations SET logo_url = ? WHERE id = ?', [
      publicUrl,
      organizationId,
    ]);
    await _storageBudgetService.recordEntries([
      MediaBudgetEntry(
        objectPath: objectPath,
        mimeType: processed.contentType,
        sizeBytes: processed.sizeBytes,
        kind: MediaBudgetKind.image,
        width: processed.width,
        height: processed.height,
        originalFileName: imageFile.uri.pathSegments.isEmpty
            ? null
            : imageFile.uri.pathSegments.last,
      ),
    ]);

    final oldObjectPath = _extractStorageObjectPath(organization.logoUrl);
    if (oldObjectPath != null && oldObjectPath != objectPath) {
      await _removeStoredObjects([oldObjectPath]);
    }

    return publicUrl;
  }

  Future<void> removeOrganizationLogo(String organizationId) async {
    final organization = await getOrganizationById(organizationId);
    if (organization == null) {
      throw StateError('Organization not found.');
    }

    final db = await _ensureDb();
    await db.execute('UPDATE organizations SET logo_url = NULL WHERE id = ?', [
      organizationId,
    ]);

    final oldObjectPath = _extractStorageObjectPath(organization.logoUrl);
    if (oldObjectPath != null) {
      await _removeStoredObjects([oldObjectPath]);
    }
  }

  Future<String> uploadOfficeBearerPhoto({
    required String bearerId,
    required File imageFile,
    required bool lowDataMode,
  }) async {
    final bearer = await _getOfficeBearerById(bearerId);
    if (bearer == null) {
      throw StateError('Office bearer not found.');
    }

    final processed = await _prepareImageForUpload(
      imageFile,
      preset: lowDataMode ? MediaPreset.lowDataAvatar : MediaPreset.avatar,
    );
    final objectPath = await _uploadImageBytes(
      bytes: processed.bytes,
      folder: 'office-bearers',
      entityId: bearerId,
      contentType: processed.contentType,
      cacheControl: _memberPhotoCacheControl,
    );
    final publicUrl = SupabaseService.client.storage
        .from(_mediaBucket)
        .getPublicUrl(objectPath);

    final db = await _ensureDb();
    await db.execute('UPDATE office_bearers SET photo_url = ? WHERE id = ?', [
      publicUrl,
      bearerId,
    ]);
    await _storageBudgetService.recordEntries([
      MediaBudgetEntry(
        objectPath: objectPath,
        mimeType: processed.contentType,
        sizeBytes: processed.sizeBytes,
        kind: MediaBudgetKind.image,
        width: processed.width,
        height: processed.height,
        originalFileName: imageFile.uri.pathSegments.isEmpty
            ? null
            : imageFile.uri.pathSegments.last,
      ),
    ]);

    final oldObjectPath = _extractStorageObjectPath(bearer.photoUrl);
    if (oldObjectPath != null && oldObjectPath != objectPath) {
      await _removeStoredObjects([oldObjectPath]);
    }

    return publicUrl;
  }

  Future<void> removeOfficeBearerPhoto(String bearerId) async {
    final bearer = await _getOfficeBearerById(bearerId);
    if (bearer == null) {
      throw StateError('Office bearer not found.');
    }

    final db = await _ensureDb();
    await db.execute(
      'UPDATE office_bearers SET photo_url = NULL WHERE id = ?',
      [bearerId],
    );

    final oldObjectPath = _extractStorageObjectPath(bearer.photoUrl);
    if (oldObjectPath != null) {
      await _removeStoredObjects([oldObjectPath]);
    }
  }

  List<Organization> _buildTree(List<Organization> allOrgs) {
    final orgIds = allOrgs.map((org) => org.id).toSet();
    final Map<String, List<Organization>> childrenMap = {};
    for (final org in allOrgs) {
      if (org.parentId != null) {
        childrenMap.putIfAbsent(org.parentId!, () => []).add(org);
      }
    }

    List<Organization> buildBranch(String? parentId) {
      final children = [...(childrenMap[parentId] ?? const <Organization>[])];
      children.sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );
      return children
          .map((child) => child.copyWith(children: buildBranch(child.id)))
          .toList();
    }

    final roots =
        allOrgs
            .where(
              (org) => org.parentId == null || !orgIds.contains(org.parentId),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.name.toLowerCase().compareTo(right.name.toLowerCase()),
          );

    return roots
        .map((root) => root.copyWith(children: buildBranch(root.id)))
        .toList();
  }

  String _requiredValue(String value, {required String field}) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$field cannot be empty.');
    }
    return normalized;
  }

  String? _optionalValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<ProcessedImage> _prepareImageForUpload(
    File imageFile, {
    required MediaPreset preset,
  }) async {
    final originalSize = await imageFile.length();
    if (originalSize > _maxImageInputBytes) {
      throw Exception('Image is too large. Please choose one under 15 MB.');
    }

    return _imageService.processImage(imageFile, preset: preset);
  }

  Future<String> _uploadImageBytes({
    required Uint8List bytes,
    required String folder,
    required String entityId,
    required String contentType,
    required String cacheControl,
  }) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in required before uploading media.');
    }

    final extension = _extensionForContentType(contentType);
    final objectPath =
        '$userId/$folder/${entityId}_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}$extension';

    try {
      await SupabaseService.client.storage
          .from(_mediaBucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              cacheControl: cacheControl,
              upsert: false,
            ),
          );
    } on StorageException catch (error) {
      throw Exception('Image upload failed: ${error.message}');
    }

    return objectPath;
  }

  Future<OfficeBearer?> _getOfficeBearerById(String id) async {
    final db = await _ensureDb();
    final row = await db.getOptional(
      'SELECT * FROM office_bearers WHERE id = ? LIMIT 1',
      [id],
    );
    if (row == null) return null;
    return OfficeBearer.fromRow(row);
  }

  String _extensionForContentType(String contentType) {
    final normalized = contentType.toLowerCase();
    if (normalized.contains('webp')) return '.webp';
    if (normalized.contains('png')) return '.png';
    if (normalized.contains('jpeg') || normalized.contains('jpg')) {
      return '.jpg';
    }
    return '.bin';
  }

  String? _extractStorageObjectPath(String? url) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      return raw;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    const markerPrefix = '/storage/v1/object/public/';
    const marker = '$markerPrefix$_mediaBucket/';
    final index = uri.path.indexOf(marker);
    if (index == -1) return null;
    return Uri.decodeComponent(uri.path.substring(index + marker.length));
  }

  Future<void> _removeStoredObjects(Iterable<String> objectPaths) async {
    final normalized = objectPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      return;
    }

    try {
      await SupabaseService.client.storage
          .from(_mediaBucket)
          .remove(normalized.toList());
    } catch (_) {
      // Keep data mutations resilient if storage cleanup fails.
    }
    await _storageBudgetService.removeEntriesByObjectPaths(normalized);
  }
}
