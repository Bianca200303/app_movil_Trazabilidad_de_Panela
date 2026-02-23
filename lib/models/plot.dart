class Plot {
  final String id;
  final String name;
  final String code;
  final String producerId;
  final bool isActive;
  final double? defaultExtractionPercentage;
  final double? defaultCachazaPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plot({
    required this.id,
    required this.name,
    required this.code,
    required this.producerId,
    required this.isActive,
    this.defaultExtractionPercentage,
    this.defaultCachazaPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    return Plot(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      producerId: json['producer_id'] as String,
      isActive: json['is_active'] as bool,
      defaultExtractionPercentage: (json['default_extraction_percentage'] as num?)?.toDouble(),
      defaultCachazaPercentage: (json['default_cachaza_percentage'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'producer_id': producerId,
      'is_active': isActive,
      'default_extraction_percentage': defaultExtractionPercentage,
      'default_cachaza_percentage': defaultCachazaPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Plot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Plot(id: $id, name: $name, code: $code, producerId: $producerId)';

  Plot copyWith({
    String? id,
    String? name,
    String? code,
    String? producerId,
    bool? isActive,
    double? defaultExtractionPercentage,
    double? defaultCachazaPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plot(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      producerId: producerId ?? this.producerId,
      isActive: isActive ?? this.isActive,
      defaultExtractionPercentage: defaultExtractionPercentage ?? this.defaultExtractionPercentage,
      defaultCachazaPercentage: defaultCachazaPercentage ?? this.defaultCachazaPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}