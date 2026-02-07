import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/organization/data/organization_repository.dart';
import 'package:liankhawpui/features/organization/domain/office_bearer.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository();
});

final organizationTreeProvider = FutureProvider<List<Organization>>((
  ref,
) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getOrganizationTree();
});

final officeBearersProvider = FutureProvider.family<List<OfficeBearer>, String>(
  (ref, orgId) async {
    final repo = ref.watch(organizationRepositoryProvider);
    return repo.getOfficeBearers(orgId);
  },
);
