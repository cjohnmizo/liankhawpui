import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/organization/domain/office_bearer.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';

class OrganizationRepository {
  final _db = PowerSyncService().db;

  Future<List<Organization>> getAllOrganizations() async {
    final result = await _db.getAll(
      'SELECT * FROM organizations ORDER BY name ASC',
    );
    return result.map((row) => Organization.fromRow(row)).toList();
  }

  Future<List<Organization>> getOrganizationTree() async {
    // Determine tree in memory for simplicity (unless we use recursive CTEs in SQLite).
    // Getting all orgs is usually fine for village scale (likely < 500 orgs).
    final allOrgs = await getAllOrganizations();

    // Build tree
    final Map<String, List<Organization>> childrenMap = {};
    for (var org in allOrgs) {
      if (org.parentId != null) {
        childrenMap.putIfAbsent(org.parentId!, () => []).add(org);
      }
    }

    // Assign children to parents recursively?
    // Or just return a list of root nodes (parentId == null) with children populated.

    List<Organization> buildTree(String? parentId) {
      final children = childrenMap[parentId] ?? [];
      return children.map((child) {
        return child.copyWith(children: buildTree(child.id));
      }).toList();
    }

    // Get roots (those with null parentId)
    final roots = allOrgs.where((o) => o.parentId == null).toList();

    return roots.map((root) {
      return root.copyWith(children: buildTree(root.id));
    }).toList();
  }

  Future<List<OfficeBearer>> getOfficeBearers(String orgId) async {
    final result = await _db.getAll(
      'SELECT * FROM office_bearers WHERE org_id = ? ORDER BY rank_order ASC',
      [orgId],
    );
    return result.map((row) => OfficeBearer.fromRow(row)).toList();
  }
}
