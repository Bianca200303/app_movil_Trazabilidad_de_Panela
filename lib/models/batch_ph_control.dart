class BatchPhControl {
  final String id;
  final String productionBatchId;
  final DateTime recordDate;
  final String regulatorType;
  final double phInitial;
  final double phFinal;
  final double? regulatorQuantityValue;
  final String? regulatorQuantityUnit;
  final double? brix;
  final String? correctiveAction;
  final String cooperativeId;
  final DateTime createdAt;

  BatchPhControl({
    required this.id,
    required this.productionBatchId,
    required this.recordDate,
    required this.regulatorType,
    required this.phInitial,
    required this.phFinal,
    this.regulatorQuantityValue,
    this.regulatorQuantityUnit,
    this.brix,
    this.correctiveAction,
    required this.cooperativeId,
    required this.createdAt,
  });

  factory BatchPhControl.fromJson(Map<String, dynamic> json) {
    return BatchPhControl(
      id: json['id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      regulatorType: json['regulator_type'] as String,
      phInitial: (json['ph_initial'] as num).toDouble(),
      phFinal: (json['ph_final'] as num).toDouble(),
      regulatorQuantityValue: json['regulator_quantity_value'] != null ? (json['regulator_quantity_value'] as num).toDouble() : null,
      regulatorQuantityUnit: json['regulator_quantity_unit'] as String?,
      brix: json['brix'] != null ? (json['brix'] as num).toDouble() : null,
      correctiveAction: json['corrective_action'] as String?,
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'production_batch_id': productionBatchId,
      'record_date': recordDate.toIso8601String(),
      'regulator_type': regulatorType,
      'ph_initial': phInitial,
      'ph_final': phFinal,
      'regulator_quantity_value': regulatorQuantityValue,
      'regulator_quantity_unit': regulatorQuantityUnit,
      'brix': brix,
      'corrective_action': correctiveAction,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Calculate pH change
  double get phChange => phFinal - phInitial;

  // Formatted pH display
  String get formattedPhInitial => phInitial.toStringAsFixed(2);
  String get formattedPhFinal => phFinal.toStringAsFixed(2);
  String get formattedBrix => brix != null ? '${brix!.toStringAsFixed(1)}°Bx' : 'N/A';

  // Formatted regulator quantity display
  String get formattedRegulatorQuantity {
    if (regulatorQuantityValue == null || regulatorQuantityUnit == null) {
      return 'N/A';
    }
    return '${regulatorQuantityValue!.toStringAsFixed(2)} $regulatorQuantityUnit';
  }

  // Validation for pH range
  bool get isValidPhRange => 
    phInitial >= 0 && phInitial <= 14 && 
    phFinal >= 0 && phFinal <= 14;

  // Check if pH was successfully adjusted
  bool get isPhAdjusted => phChange.abs() > 0.1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchPhControl && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BatchPhControl(id: $id, productionBatchId: $productionBatchId, pH: $formattedPhInitial→$formattedPhFinal)';

  BatchPhControl copyWith({
    String? id,
    String? productionBatchId,
    DateTime? recordDate,
    String? regulatorType,
    double? phInitial,
    double? phFinal,
    double? regulatorQuantityValue,
    String? regulatorQuantityUnit,
    double? brix,
    String? correctiveAction,
    String? cooperativeId,
    DateTime? createdAt,
  }) {
    return BatchPhControl(
      id: id ?? this.id,
      productionBatchId: productionBatchId ?? this.productionBatchId,
      recordDate: recordDate ?? this.recordDate,
      regulatorType: regulatorType ?? this.regulatorType,
      phInitial: phInitial ?? this.phInitial,
      phFinal: phFinal ?? this.phFinal,
      regulatorQuantityValue: regulatorQuantityValue ?? this.regulatorQuantityValue,
      regulatorQuantityUnit: regulatorQuantityUnit ?? this.regulatorQuantityUnit,
      brix: brix ?? this.brix,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}