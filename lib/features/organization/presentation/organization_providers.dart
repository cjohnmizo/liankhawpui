import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/organization/data/organization_repository.dart';
import 'package:liankhawpui/features/organization/domain/office_bearer.dart';
import 'package:liankhawpui/features/organization/domain/organization.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository();
});

final organizationListProvider = StreamProvider<List<Organization>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.watchOrganizations();
});

final organizationTreeProvider = StreamProvider<List<Organization>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.watchOrganizationTree();
});

final officeBearersProvider = StreamProvider.family<List<OfficeBearer>, String>(
  (ref, orgId) {
    final repo = ref.watch(organizationRepositoryProvider);
    return repo.watchOfficeBearers(orgId);
  },
);
