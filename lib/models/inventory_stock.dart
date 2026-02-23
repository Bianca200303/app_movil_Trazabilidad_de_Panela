class InventoryStock {
  final String id;
  final String productionBatchId;
  final double currentKg;
  final double reservedKg;
  final double availableKg;
  final String cooperativeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryStock({
    required this.id,
    required this.productionBatchId,
    required this.currentKg,
    required this.reservedKg,
    required this.availableKg,
    required this.cooperativeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryStock.fromJson(Map<String, dynamic> json) {
    return InventoryStock(
      id: json['id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      currentKg: (json['current_kg'] as num).toDouble(),
      reservedKg: (json['reserved_kg'] as num).toDouble(),
      availableKg: (json['available_kg'] as num).toDouble(),
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'production_batch_id': productionBatchId,
      'current_kg': currentKg,
      'reserved_kg': reservedKg,
      'available_kg': availableKg,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryStock copyWith({
    String? id,
    String? productionBatchId,
    double? currentKg,
    double? reservedKg,
    double? availableKg,
    String? cooperativeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryStock(
      id: id ?? this.id,
      productionBatchId: productionBatchId ?? this.productionBatchId,
      currentKg: currentKg ?? this.currentKg,
      reservedKg: reservedKg ?? this.reservedKg,
      availableKg: availableKg ?? this.availableKg,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'InventoryStock('
        'id: $id, '
        'productionBatchId: $productionBatchId, '
        'currentKg: $currentKg, '
        'reservedKg: $reservedKg, '
        'availableKg: $availableKg, '
        'cooperativeId: $cooperativeId, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryStock &&
        other.id == id &&
        other.productionBatchId == productionBatchId &&
        other.currentKg == currentKg &&
        other.reservedKg == reservedKg &&
        other.availableKg == availableKg &&
        other.cooperativeId == cooperativeId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      productionBatchId,
      currentKg,
      reservedKg,
      availableKg,
      cooperativeId,
      createdAt,
      updatedAt,
    );
  }

  // Helper methods
  bool get hasStock => availableKg > 0;
  bool get isLowStock => availableKg < 50; // Less than 1 bag equivalent
  int get availableBags => (availableKg / 50).floor(); // Number of complete bags
}

class CreateInventoryStockRequest {
  final String productionBatchId;
  final double currentKg;
  final double reservedKg;
  final String cooperativeId;

  const CreateInventoryStockRequest({
    required this.productionBatchId,
    required this.currentKg,
    this.reservedKg = 0.0,
    required this.cooperativeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'production_batch_id': productionBatchId,
      'current_kg': currentKg,
      'reserved_kg': reservedKg,
      'cooperative_id': cooperativeId,
    };
  }
}

class UpdateInventoryStockRequest {
  final double? currentKg;
  final double? reservedKg;

  const UpdateInventoryStockRequest({
    this.currentKg,
    this.reservedKg,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (currentKg != null) json['current_kg'] = currentKg;
    if (reservedKg != null) json['reserved_kg'] = reservedKg;
    return json;
  }

  bool get isEmpty => currentKg == null && reservedKg == null;
}