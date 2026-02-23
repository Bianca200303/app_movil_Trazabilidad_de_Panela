class Producer {
  final String id;
  final String firstName;
  final String lastName;
  final String dni;
  final String cooperativeId;
  final String coopModuleId;
  final bool isMember;
  final bool isActive;
  final String? appagropCode;
  final double defaultExtractionPercentage;
  final double defaultCachazaPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Producer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.cooperativeId,
    required this.coopModuleId,
    required this.isMember,
    required this.isActive,
    this.appagropCode,
    required this.defaultExtractionPercentage,
    required this.defaultCachazaPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Producer.fromJson(Map<String, dynamic> json) {
    return Producer(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dni: json['dni'] as String,
      cooperativeId: json['cooperative_id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      isMember: json['is_member'] as bool,
      isActive: json['is_active'] as bool,
      appagropCode: json['appagrop_code'] as String?,
      defaultExtractionPercentage: (json['default_extraction_percentage'] as num?)?.toDouble() ?? 62.5,
      defaultCachazaPercentage: (json['default_cachaza_percentage'] as num?)?.toDouble() ?? 2.5,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'dni': dni,
      'cooperative_id': cooperativeId,
      'coop_module_id': coopModuleId,
      'is_member': isMember,
      'is_active': isActive,
      'appagrop_code': appagropCode,
      'default_extraction_percentage': defaultExtractionPercentage,
      'default_cachaza_percentage': defaultCachazaPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  String get memberStatus => isMember ? 'SOCIO' : 'NO SOCIO';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Producer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Producer(id: $id, fullName: $fullName, dni: $dni)';

  Producer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? dni,
    String? cooperativeId,
    String? coopModuleId,
    bool? isMember,
    bool? isActive,
    String? appagropCode,
    double? defaultExtractionPercentage,
    double? defaultCachazaPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Producer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dni: dni ?? this.dni,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      coopModuleId: coopModuleId ?? this.coopModuleId,
      isMember: isMember ?? this.isMember,
      isActive: isActive ?? this.isActive,
      appagropCode: appagropCode ?? this.appagropCode,
      defaultExtractionPercentage: defaultExtractionPercentage ?? this.defaultExtractionPercentage,
      defaultCachazaPercentage: defaultCachazaPercentage ?? this.defaultCachazaPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}