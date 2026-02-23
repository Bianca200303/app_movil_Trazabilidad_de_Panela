class CoopModule {
  final String id;
  final String name;

  CoopModule({
    required this.id,
    required this.name,
  });

  factory CoopModule.fromJson(Map<String, dynamic> json) {
    return CoopModule(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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