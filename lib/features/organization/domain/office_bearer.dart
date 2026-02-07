class OfficeBearer {
  final String id;
  final String orgId;
  final String name;
  final String position;
  final String? phone;
  final String? photoUrl;
  final int rankOrder;

  const OfficeBearer({
    required this.id,
    required this.orgId,
    required this.name,
    required this.position,
    this.phone,
    this.photoUrl,
    required this.rankOrder,
  });

  factory OfficeBearer.fromRow(Map<String, dynamic> row) {
    return OfficeBearer(
      id: row['id'] as String,
      orgId: row['org_id'] as String,
      name: row['name'] as String,
      position: row['position'] as String,
      phone: row['phone'] as String?,
      photoUrl: row['photo_url'] as String?,
      rankOrder: row['rank_order'] as int? ?? 0,
    );
  }
}
