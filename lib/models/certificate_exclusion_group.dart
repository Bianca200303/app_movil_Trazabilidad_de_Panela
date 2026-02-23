class CertificateExclusionGroup {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final bool isRequired;
  final String cooperativeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  CertificateExclusionGroup({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.isRequired,
    required this.cooperativeId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory CertificateExclusionGroup.fromJson(Map<String, dynamic> json) {
    return CertificateExclusionGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      isRequired: json['is_required'] as bool,
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'is_required': isRequired,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CertificateExclusionGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CertificateExclusionGroup(id: $id, name: $name, displayName: $displayName, isRequired: $isRequired)';
  }

  CertificateExclusionGroup copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    bool? isRequired,
    String? cooperativeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return CertificateExclusionGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}