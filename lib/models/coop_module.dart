class CoopModule {
  final String id;
  final String name;
  final double defaultDensity;

  CoopModule({
    required this.id,
    required this.name,
    this.defaultDensity = 1.08,
  });

  factory CoopModule.fromJson(Map<String, dynamic> json) {
    return CoopModule(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultDensity: (json['default_density'] as num?)?.toDouble() ?? 1.08,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_density': defaultDensity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoopModule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CoopModule(id: $id, name: $name)';
}