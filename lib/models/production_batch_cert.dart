class ProductionBatchCert {
  final String id;
  final String productionBatchId;
  final String batchCertId;
  final String cooperativeId;
  final DateTime createdAt;

  ProductionBatchCert({
    required this.id,
    required this.productionBatchId,
    required this.batchCertId,
    required this.cooperativeId,
    required this.createdAt,
  });

  factory ProductionBatchCert.fromJson(Map<String, dynamic> json) {
    return ProductionBatchCert(
      id: json['id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      batchCertId: json['batch_cert_id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'production_batch_id': productionBatchId,
      'batch_cert_id': batchCertId,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductionBatchCert && 
           other.productionBatchId == productionBatchId && 
           other.batchCertId == batchCertId;
  }

  @override
  int get hashCode => productionBatchId.hashCode ^ batchCertId.hashCode;

  @override
  String toString() => 'ProductionBatchCert(productionBatchId: $productionBatchId, batchCertId: $batchCertId)';

  ProductionBatchCert copyWith({
    String? id,
    String? productionBatchId,
    String? batchCertId,
    String? cooperativeId,
    DateTime? createdAt,
  }) {
    return ProductionBatchCert(
      id: id ?? this.id,
      productionBatchId: productionBatchId ?? this.productionBatchId,
      batchCertId: batchCertId ?? this.batchCertId,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}