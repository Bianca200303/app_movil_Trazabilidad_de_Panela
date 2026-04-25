/// Production calculator for panela manufacturing process
///
/// This class provides centralized calculations for all production-related
/// formulas used in the panela manufacturing process. All constants and
/// calculation methods are defined here to ensure consistency across the app.
///
/// All formulas are based on standard panela production processes.
class ProductionCalculator {
  ProductionCalculator._();

  // ============================================================================
  // CONSTANTS
  // ============================================================================

  /// Sugar cane juice density in kg/L
  /// This is the single source of truth for this constant value
  static const double sugarCaneDensity = 1.08;

  /// Display-friendly version for UI (auto-generated from constant)
  /// Example: "1.05 kg/L"
  static String get sugarCaneDensityDisplay => '${sugarCaneDensity.toStringAsFixed(2)} kg/L';

  // ============================================================================
  // INDIVIDUAL CALCULATION METHODS
  // ============================================================================

  /// Calculates juice weight in kilograms from liters
  ///
  /// Formula: Peso de jugo (kg) = Jugo extraído (L) × Densidad de caña
  ///
  /// Example:
  /// ```dart
  /// final juiceWeightKg = ProductionCalculator.calculateJuiceWeight(100);
  /// // Returns: 105.0 kg
  /// ```
  static double calculateJuiceWeight(double juiceLiters, {double density = sugarCaneDensity}) {
    return juiceLiters * density;
  }

  /// Calculates cane input in kilograms from juice weight and extraction percentage
  ///
  /// Formula: Caña ingresada (kg) = Peso de jugo (kg) / (% de extracción / 100)
  ///
  /// Example:
  /// ```dart
  /// final juiceWeightKg = 105.0;
  /// final caneKg = ProductionCalculator.calculateCaneInput(juiceWeightKg, 62.5);
  /// // Returns: 168.0 kg
  /// ```
  static double calculateCaneInput(double juiceWeightKg, double extractionPercentage) {
    if (extractionPercentage <= 0) return 0.0;
    return juiceWeightKg / (extractionPercentage / 100);
  }

  /// Calculates bagasse (residue) in kilograms
  ///
  /// Formula: Bagazo (kg) = Caña ingresada (kg) × (1 – % de extracción / 100)
  ///
  /// Example:
  /// ```dart
  /// final caneKg = 168.0;
  /// final bagazoKg = ProductionCalculator.calculateBagasse(caneKg, 62.5);
  /// // Returns: 63.0 kg
  /// ```
  static double calculateBagasse(double caneKg, double extractionPercentage) {
    return caneKg * (1 - (extractionPercentage / 100));
  }

  /// Calculates cachaza (scum) in kilograms
  ///
  /// Formula: Cachaza (kg) = Peso de jugo (kg) × (% de cachaza / 100)
  ///
  /// Example:
  /// ```dart
  /// final juiceWeightKg = 105.0;
  /// final cachazaKg = ProductionCalculator.calculateCachaza(juiceWeightKg, 2.5);
  /// // Returns: 2.625 kg
  /// ```
  static double calculateCachaza(double juiceWeightKg, double cachazaPercentage) {
    return juiceWeightKg * (cachazaPercentage / 100);
  }

  /// Calculates yield (rendimiento) percentage
  ///
  /// Formula: Rendimiento (%) = (Kg de panela obtenida / Litros de jugo extraído) × 100
  ///
  /// Example:
  /// ```dart
  /// final panelaKg = 15.0;
  /// final juiceLiters = 100.0;
  /// final yieldPercentage = ProductionCalculator.calculateYield(panelaKg, juiceLiters);
  /// // Returns: 15.0%
  /// ```
  static double calculateYield(double panelaKg, double juiceLiters) {
    return juiceLiters > 0 ? (panelaKg / juiceLiters) * 100 : 0.0;
  }

  /// Calculates water loss in kilograms
  ///
  /// Formula: Pérdida de agua (kg) = Peso de jugo (kg) – Panela (kg) – Confitillo (kg) – Cachaza (kg)
  ///
  /// Example:
  /// ```dart
  /// final waterLoss = ProductionCalculator.calculateWaterLoss(105.0, 15.0, 2.0, 2.625);
  /// // Returns: 85.375 kg
  /// ```
  static double calculateWaterLoss(
    double juiceWeightKg,
    double panelaKg,
    double confitilloKg,
    double cachazaKg,
  ) {
    return juiceWeightKg - panelaKg - confitilloKg - cachazaKg;
  }

  // ============================================================================
  // CONVENIENCE METHOD - Calculate all values at once
  // ============================================================================

  /// Calculates all production values in a single call
  ///
  /// This is a convenience method that calculates all production metrics
  /// at once. Use this when you need multiple calculations to avoid
  /// redundant computations.
  ///
  /// Example:
  /// ```dart
  /// final results = ProductionCalculator.calculateAll(
  ///   juiceLiters: 100,
  ///   panelaKg: 15,
  ///   confitilloKg: 2,
  ///   extractionPercentage: 62.5,
  ///   cachazaPercentage: 2.5,
  /// );
  ///
  /// print(results.caneKg); // 168.0
  /// print(results.rendimientoPercentage); // 15.0
  /// ```
  static ProductionCalculations calculateAll({
    required double juiceLiters,
    required double panelaKg,
    required double confitilloKg,
    required double extractionPercentage,
    required double cachazaPercentage,
    double density = sugarCaneDensity,
  }) {
    // Calculate intermediate values
    final juiceWeightKg = calculateJuiceWeight(juiceLiters, density: density);
    final caneKg = calculateCaneInput(juiceWeightKg, extractionPercentage);

    // Calculate final values
    final bagazoKg = calculateBagasse(caneKg, extractionPercentage);
    final cachazaKg = calculateCachaza(juiceWeightKg, cachazaPercentage);
    final rendimientoPercentage = calculateYield(panelaKg, juiceLiters);
    final perdidaAguaKg = calculateWaterLoss(
      juiceWeightKg,
      panelaKg,
      confitilloKg,
      cachazaKg,
    );

    return ProductionCalculations(
      caneKg: caneKg,
      juiceWeightKg: juiceWeightKg,
      bagazoKg: bagazoKg,
      cachazaKg: cachazaKg,
      rendimientoPercentage: rendimientoPercentage,
      perdidaAguaKg: perdidaAguaKg,
    );
  }
}

// ==============================================================================
// RESULTS CLASS
// ==============================================================================

/// Immutable class that holds all production calculation results
///
/// This class is returned by [ProductionCalculator.calculateAll] and contains
/// all calculated values for a production batch.
class ProductionCalculations {
  /// Sugar cane input in kilograms (calculated)
  final double caneKg;

  /// Juice weight in kilograms (calculated from liters × density)
  final double juiceWeightKg;

  /// Bagasse (residue) in kilograms
  final double bagazoKg;

  /// Cachaza (scum) in kilograms
  final double cachazaKg;

  /// Yield percentage (rendimiento)
  final double rendimientoPercentage;

  /// Water loss in kilograms
  final double perdidaAguaKg;

  const ProductionCalculations({
    required this.caneKg,
    required this.juiceWeightKg,
    required this.bagazoKg,
    required this.cachazaKg,
    required this.rendimientoPercentage,
    required this.perdidaAguaKg,
  });

  @override
  String toString() {
    return 'ProductionCalculations('
        'caneKg: ${caneKg.toStringAsFixed(2)}, '
        'juiceWeightKg: ${juiceWeightKg.toStringAsFixed(2)}, '
        'bagazoKg: ${bagazoKg.toStringAsFixed(2)}, '
        'cachazaKg: ${cachazaKg.toStringAsFixed(2)}, '
        'rendimientoPercentage: ${rendimientoPercentage.toStringAsFixed(2)}%, '
        'perdidaAguaKg: ${perdidaAguaKg.toStringAsFixed(2)}'
        ')';
  }
}
