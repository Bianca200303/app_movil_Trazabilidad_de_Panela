class ExitItem {
  final String id;
  final String exitRegistrationId;
  final String productionBatchId;
  final double quantityKg;
  final bool isAutoconsumo;
  final double bagsCount;
  final double unitPrice;
  final double totalValue;
  final String? notes;
  final String? itemDocumentNumber;
  final String cooperativeId;
  final DateTime createdAt;

  const ExitItem({
    required this.id,
    required this.exitRegistrationId,
    required this.productionBatchId,
    required this.quantityKg,
    required this.isAutoconsumo,
    required this.bagsCount,
    required this.unitPrice,
    required this.totalValue,
    this.notes,
    this.itemDocumentNumber,
    required this.cooperativeId,
    required this.createdAt,
  });

  factory ExitItem.fromJson(Map<String, dynamic> json) {
    return ExitItem(
      id: json['id'] as String,
      exitRegistrationId: json['exit_registration_id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      isAutoconsumo: json['is_autoconsumo'] as bool,
      bagsCount: (json['bags_count'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalValue: (json['total_value'] as num).toDouble(),
      notes: json['notes'] as String?,
      itemDocumentNumber: json['item_document_number'] as String?,
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exit_registration_id': exitRegistrationId,
      'production_batch_id': productionBatchId,
      'quantity_kg': quantityKg,
      'is_autoconsumo': isAutoconsumo,
      'bags_count': bagsCount,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'notes': notes,
      'item_document_number': itemDocumentNumber,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExitItem copyWith({
    String? id,
    String? exitRegistrationId,
    String? productionBatchId,
    double? quantityKg,
    bool? isAutoconsumo,
    double? bagsCount,
    double? unitPrice,
    double? totalValue,
    String? notes,
    String? itemDocumentNumber,
    String? cooperativeId,
    DateTime? createdAt,
  }) {
    return ExitItem(
      id: id ?? this.id,
      exitRegistrationId: exitRegistrationId ?? this.exitRegistrationId,
      productionBatchId: productionBatchId ?? this.productionBatchId,
      quantityKg: quantityKg ?? this.quantityKg,
      isAutoconsumo: isAutoconsumo ?? this.isAutoconsumo,
      bagsCount: bagsCount ?? this.bagsCount,
      unitPrice: unitPrice ?? this.unitPrice,
      totalValue: totalValue ?? this.totalValue,
      notes: notes ?? this.notes,
      itemDocumentNumber: itemDocumentNumber ?? this.itemDocumentNumber,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ExitItem('
        'id: $id, '
        'exitRegistrationId: $exitRegistrationId, '
        'productionBatchId: $productionBatchId, '
        'quantityKg: $quantityKg, '
        'isAutoconsumo: $isAutoconsumo, '
        'bagsCount: $bagsCount, '
        'unitPrice: $unitPrice, '
        'totalValue: $totalValue, '
        'cooperativeId: $cooperativeId'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExitItem &&
        other.id == id &&
        other.exitRegistrationId == exitRegistrationId &&
        other.productionBatchId == productionBatchId &&
        other.quantityKg == quantityKg &&
        other.isAutoconsumo == isAutoconsumo &&
        other.bagsCount == bagsCount &&
        other.unitPrice == unitPrice &&
        other.totalValue == totalValue &&
        other.notes == notes &&
        other.cooperativeId == cooperativeId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      exitRegistrationId,
      productionBatchId,
      quantityKg,
      isAutoconsumo,
      bagsCount,
      unitPrice,
      totalValue,
      notes,
      cooperativeId,
    );
  }

  // Helper methods
  String get typeDescription => isAutoconsumo ? 'Autoconsumo' : 'Salida por sacos';
  String get quantityDescription => isAutoconsumo 
      ? '$quantityKg kg'
      : '$bagsCount sacos ($quantityKg kg)';
  
  double get pricePerBag => isAutoconsumo ? 0 : (unitPrice * 50);
}

class CreateExitItemRequest {
  final String exitRegistrationId;
  final String productionBatchId;
  final double quantityKg;
  final bool isAutoconsumo;
  final double? bagsCount;
  final double unitPrice;
  final String? notes;
  final String? itemDocumentNumber;
  final String cooperativeId;

  const CreateExitItemRequest({
    required this.exitRegistrationId,
    required this.productionBatchId,
    required this.quantityKg,
    required this.isAutoconsumo,
    this.bagsCount,
    this.unitPrice = 0.0,
    this.notes,
    this.itemDocumentNumber,
    required this.cooperativeId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'exit_registration_id': exitRegistrationId,
      'production_batch_id': productionBatchId,
      'quantity_kg': quantityKg,
      'is_autoconsumo': isAutoconsumo,
      'unit_price': unitPrice,
      'cooperative_id': cooperativeId,
    };

    if (bagsCount != null) json['bags_count'] = bagsCount;
    if (notes != null) json['notes'] = notes;
    if (itemDocumentNumber != null) json['item_document_number'] = itemDocumentNumber;

    return json;
  }
}

class UpdateExitItemRequest {
  final double? quantityKg;
  final bool? isAutoconsumo;
  final double? bagsCount;
  final double? unitPrice;
  final String? notes;
  final String? itemDocumentNumber;

  const UpdateExitItemRequest({
    this.quantityKg,
    this.isAutoconsumo,
    this.bagsCount,
    this.unitPrice,
    this.notes,
    this.itemDocumentNumber,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (quantityKg != null) json['quantity_kg'] = quantityKg;
    if (isAutoconsumo != null) json['is_autoconsumo'] = isAutoconsumo;
    if (bagsCount != null) json['bags_count'] = bagsCount;
    if (unitPrice != null) json['unit_price'] = unitPrice;
    if (notes != null) json['notes'] = notes;
    if (itemDocumentNumber != null) json['item_document_number'] = itemDocumentNumber;

    return json;
  }

  bool get isEmpty =>
      quantityKg == null &&
      isAutoconsumo == null &&
      bagsCount == null &&
      unitPrice == null &&
      notes == null &&
      itemDocumentNumber == null;
}