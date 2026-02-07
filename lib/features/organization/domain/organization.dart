class Organization {
  final String id;
  final String name;
  final String? type; // 'council', 'ngo', 'church', 'institution'
  final String? parentId;
  final String? logoUrl;
  final String? contactPhone;
  final String? description;
  final String? currentTerm;

  // Not persisted, but useful for UI tree construction
  final List<Organization> children;

  const Organization({
    required this.id,
    required this.name,
    this.type,
    this.parentId,
    this.logoUrl,
    this.contactPhone,
    this.description,
    this.currentTerm,
    this.children = const [],
  });

  factory Organization.fromRow(Map<String, dynamic> row) {
    return Organization(
      id: row['id'] as String,
      name: row['name'] as String,
      type: row['type'] as String?,
      parentId: row['parent_id'] as String?,
      logoUrl: row['logo_url'] as String?,
      contactPhone: row['contact_phone'] as String?,
      description: row['description'] as String?,
      currentTerm: row['current_term'] as String?,
    );
  }

  Organization copyWith({List<Organization>? children}) {
    return Organization(
      id: id,
      name: name,
      type: type,
      parentId: parentId,
      logoUrl: logoUrl,
      contactPhone: contactPhone,
      description: description,
      currentTerm: currentTerm,
      children: children ?? this.children,
    );
  }
}
