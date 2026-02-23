class BatchTemperature {
  final String id;
  final String productionBatchId;
  final double temperature;
  final int sequenceNumber;
  final String cooperativeId;
  final DateTime createdAt;

  BatchTemperature({
    required this.id,
    required this.productionBatchId,
    required this.temperature,
    required this.sequenceNumber,
    required this.cooperativeId,
    required this.createdAt,
  });

  factory BatchTemperature.fromJson(Map<String, dynamic> json) {
    return BatchTemperature(
      id: json['id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      sequenceNumber: json['sequence_number'] as int,
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'production_batch_id': productionBatchId,
      'temperature': temperature,
      'sequence_number': sequenceNumber,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Formatted temperature display
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';

  // Validation for reasonable temperature range
  bool get isValidTemperature => temperature >= -50 && temperature <= 200;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchTemperature && 
           other.productionBatchId == productionBatchId && 
           other.sequenceNumber == sequenceNumber;
  }

  @override
  int get hashCode => productionBatchId.hashCode ^ sequenceNumber.hashCode;

  @override
  String toString() => 'BatchTemperature(productionBatchId: $productionBatchId, seq: $sequenceNumber, temp: $formattedTemperature)';

  BatchTemperature copyWith({
    String? id,
    String? productionBatchId,
    double? temperature,
    int? sequenceNumber,
    String? cooperativeId,
    DateTime? createdAt,
  }) {
    return BatchTemperature(
      id: id ?? this.id,
      productionBatchId: productionBatchId ?? this.productionBatchId,
      temperature: temperature ?? this.temperature,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}