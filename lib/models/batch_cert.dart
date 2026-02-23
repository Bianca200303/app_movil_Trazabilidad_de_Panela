import 'package:panela_sys/models/certificate_exclusion_group.dart';

class BatchCert {
  final String id;
  final String name;
  final String? exclusionGroupId;
  final bool isDefault;
  final CertificateExclusionGroup? exclusionGroup;

  BatchCert({
    required this.id,
    required this.name,
    this.exclusionGroupId,
    required this.isDefault,
    this.exclusionGroup,
  });

  factory BatchCert.fromJson(Map<String, dynamic> json) {
    return BatchCert(
      id: json['id'] as String,
      name: json['name'] as String,
      exclusionGroupId: json['exclusion_group_id'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      exclusionGroup: json['certificate_exclusion_groups'] != null
          ? CertificateExclusionGroup.fromJson(json['certificate_exclusion_groups'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exclusion_group_id': exclusionGroupId,
      'is_default': isDefault,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchCert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BatchCert(id: $id, name: $name, exclusionGroupId: $exclusionGroupId, isDefault: $isDefault)';

  BatchCert copyWith({
    String? id,
    String? name,
    String? exclusionGroupId,
    bool? isDefault,
    CertificateExclusionGroup? exclusionGroup,
  }) {
    return BatchCert(
      id: id ?? this.id,
      name: name ?? this.name,
      exclusionGroupId: exclusionGroupId ?? this.exclusionGroupId,
      isDefault: isDefault ?? this.isDefault,
      exclusionGroup: exclusionGroup ?? this.exclusionGroup,
    );
  }
}