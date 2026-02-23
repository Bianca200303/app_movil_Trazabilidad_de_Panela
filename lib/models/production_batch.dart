import 'package:panela_sys/core/production_calculator.dart';

class ProductionBatch {
  final String id;
  final String batchCode;
  final DateTime harvestDate;
  final DateTime processDate;
  final double caneKg;
  final double juiceLiters;
  final double panelaKg;
  final double confitilloKg;
  final double? porcentajeExtraccion;
  final double? cachazaPercentage;
  final double efficiencyPercentage;
  final String producerId;
  final String? plotId;
  final String cooperativeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductionBatch({
    required this.id,
    required this.batchCode,
    required this.harvestDate,
    required this.processDate,
    required this.caneKg,
    required this.juiceLiters,
    required this.panelaKg,
    required this.confitilloKg,
    this.porcentajeExtraccion,
    this.cachazaPercentage,
    required this.efficiencyPercentage,
    required this.producerId,
    this.plotId,
    required this.cooperativeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductionBatch.fromJson(Map<String, dynamic> json) {
    return ProductionBatch(
      id: json['id'] as String,
      batchCode: json['batch_code'] as String,
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      processDate: DateTime.parse(json['process_date'] as String),
      caneKg: (json['cane_kg'] as num).toDouble(),
      juiceLiters: (json['juice_liters'] as num).toDouble(),
      panelaKg: (json['panela_kg'] as num?)?.toDouble() ?? 0.0,
      confitilloKg: (json['confitillo_kg'] as num?)?.toDouble() ?? 0.0,
      porcentajeExtraccion: (json['porcentaje_extraccion'] as num?)?.toDouble(),
      cachazaPercentage: (json['cachaza_percentage'] as num?)?.toDouble(),
      efficiencyPercentage: (json['efficiency_percentage'] as num).toDouble(),
      producerId: json['producer_id'] as String,
      plotId: json['plot_id'] as String?,
      cooperativeId: json['cooperative_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_code': batchCode,
      'harvest_date': harvestDate.toIso8601String().split('T')[0], // Date only
      'process_date': processDate.toIso8601String().split('T')[0], // Date only
      'cane_kg': caneKg,
      'juice_liters': juiceLiters,
      'panela_kg': panelaKg,
      'confitillo_kg': confitilloKg,
      'porcentaje_extraccion': porcentajeExtraccion,
      'cachaza_percentage': cachazaPercentage,
      'efficiency_percentage': efficiencyPercentage,
      'producer_id': producerId,
      'plot_id': plotId,
      'cooperative_id': cooperativeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Process calculations using real panela production formulas

  /// Peso de jugo (kg) = Jugo extraído × Densidad de caña
  double get pesoJugoKg => ProductionCalculator.calculateJuiceWeight(juiceLiters);

  /// Bagazo (kg) = Caña ingresada × (1 – % de extracción)
  double get bagazoKg => porcentajeExtraccion != null
      ? ProductionCalculator.calculateBagasse(caneKg, porcentajeExtraccion!)
      : 0.0;

  /// Cachaza (kg) = Peso de jugo (kg) × % de cachaza
  double get cachazaKg => cachazaPercentage != null
      ? ProductionCalculator.calculateCachaza(pesoJugoKg, cachazaPercentage!)
      : 0.0;

  /// Rendimiento (%) = (Kg de panela obtenida / Litros de jugo extraído) × 100
  double get rendimientoPercentage => ProductionCalculator.calculateYield(panelaKg, juiceLiters);

  /// Pérdida de agua (kg) = Peso de jugo (kg) – Panela obtenida (kg) – Confitillo (kg) – Cachaza (kg)
  double get perdidaAguaKg => ProductionCalculator.calculateWaterLoss(
    pesoJugoKg,
    panelaKg,
    confitilloKg,
    cachazaKg
  );

  // Legacy efficiency calculation (kept for compatibility)
  double get calculatedEfficiency => rendimientoPercentage;

  // Formatted batch code display
  String get formattedBatchCode => batchCode.replaceAll('_', ' ');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductionBatch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProductionBatch(id: $id, batchCode: $batchCode, caneKg: $caneKg, juiceLiters: $juiceLiters, panelaKg: $panelaKg, confitilloKg: $confitilloKg)';

  ProductionBatch copyWith({
    String? id,
    String? batchCode,
    DateTime? harvestDate,
    DateTime? processDate,
    double? caneKg,
    double? juiceLiters,
    double? panelaKg,
    double? confitilloKg,
    double? porcentajeExtraccion,
    double? cachazaPercentage,
    double? efficiencyPercentage,
    String? producerId,
    String? plotId,
    String? cooperativeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductionBatch(
      id: id ?? this.id,
      batchCode: batchCode ?? this.batchCode,
      harvestDate: harvestDate ?? this.harvestDate,
      processDate: processDate ?? this.processDate,
      caneKg: caneKg ?? this.caneKg,
      juiceLiters: juiceLiters ?? this.juiceLiters,
      panelaKg: panelaKg ?? this.panelaKg,
      confitilloKg: confitilloKg ?? this.confitilloKg,
      porcentajeExtraccion: porcentajeExtraccion ?? this.porcentajeExtraccion,
      cachazaPercentage: cachazaPercentage ?? this.cachazaPercentage,
      efficiencyPercentage: efficiencyPercentage ?? this.efficiencyPercentage,
      producerId: producerId ?? this.producerId,
      plotId: plotId ?? this.plotId,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}