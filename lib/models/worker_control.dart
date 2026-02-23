// Worker control model for tracking employee hygiene and safety compliance
// Based on COOP-MP-RE-BPM-09 form from Cooperativa Norandino

enum WorkArea {
  molienda('M', 'Molienda'),
  hornilla('H', 'Hornilla'),
  tratamientoTermico('TT', 'Tratamiento Térmico'),
  tallerEmpaque('TEA', 'Taller de Empaque y Almacén'),
  otros('rr', 'Otros');

  final String code;
  final String displayName;

  const WorkArea(this.code, this.displayName);

  static WorkArea fromCode(String code) {
    return WorkArea.values.firstWhere(
      (area) => area.code == code,
      orElse: () => throw Exception('Invalid work area code: $code'),
    );
  }
}

class WorkerControl {
  final String id;
  final String cooperativeId;
  final String productionBatchId;
  final String workerName;
  final WorkArea workArea;
  final bool uniformComplete;
  final bool noMakeup;
  final bool nailsShortClean;
  final bool nailsNoPolish;
  final bool handsClean;
  final bool noJewelry;
  final bool hairCovered;
  final bool noBeard;
  final bool noWounds;
  final String? observations;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkerControl({
    required this.id,
    required this.cooperativeId,
    required this.productionBatchId,
    required this.workerName,
    required this.workArea,
    required this.uniformComplete,
    required this.noMakeup,
    required this.nailsShortClean,
    required this.nailsNoPolish,
    required this.handsClean,
    required this.noJewelry,
    required this.hairCovered,
    required this.noBeard,
    required this.noWounds,
    this.observations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkerControl.fromJson(Map<String, dynamic> json) {
    return WorkerControl(
      id: json['id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      workerName: json['worker_name'] as String,
      workArea: WorkArea.fromCode(json['work_area'] as String),
      uniformComplete: json['uniform_complete'] as bool,
      noMakeup: json['no_makeup'] as bool,
      nailsShortClean: json['nails_short_clean'] as bool,
      nailsNoPolish: json['nails_no_polish'] as bool,
      handsClean: json['hands_clean'] as bool,
      noJewelry: json['no_jewelry'] as bool,
      hairCovered: json['hair_covered'] as bool,
      noBeard: json['no_beard'] as bool,
      noWounds: json['no_wounds'] as bool,
      observations: json['observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'production_batch_id': productionBatchId,
      'worker_name': workerName,
      'work_area': workArea.code,
      'uniform_complete': uniformComplete,
      'no_makeup': noMakeup,
      'nails_short_clean': nailsShortClean,
      'nails_no_polish': nailsNoPolish,
      'hands_clean': handsClean,
      'no_jewelry': noJewelry,
      'hair_covered': hairCovered,
      'no_beard': noBeard,
      'no_wounds': noWounds,
      'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method: count compliance items
  int get complianceCount {
    final items = [
      uniformComplete,
      noMakeup,
      nailsShortClean,
      nailsNoPolish,
      handsClean,
      noJewelry,
      hairCovered,
      noBeard,
      noWounds,
    ];
    return items.where((v) => v).length;
  }

  // Helper method: compliance percentage
  double get compliancePercentage => (complianceCount / 9) * 100;

  // Helper method: check if fully compliant
  bool get isFullyCompliant => complianceCount == 9;
}

// Request class for creating new worker control records
class CreateWorkerControlRequest {
  final String productionBatchId;
  final String workerName;
  final WorkArea workArea;
  final bool uniformComplete;
  final bool noMakeup;
  final bool nailsShortClean;
  final bool nailsNoPolish;
  final bool handsClean;
  final bool noJewelry;
  final bool hairCovered;
  final bool noBeard;
  final bool noWounds;
  final String? observations;
  final String cooperativeId;

  const CreateWorkerControlRequest({
    required this.productionBatchId,
    required this.workerName,
    required this.workArea,
    required this.uniformComplete,
    required this.noMakeup,
    required this.nailsShortClean,
    required this.nailsNoPolish,
    required this.handsClean,
    required this.noJewelry,
    required this.hairCovered,
    required this.noBeard,
    required this.noWounds,
    this.observations,
    required this.cooperativeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'cooperative_id': cooperativeId,
      'production_batch_id': productionBatchId,
      'worker_name': workerName,
      'work_area': workArea.code,
      'uniform_complete': uniformComplete,
      'no_makeup': noMakeup,
      'nails_short_clean': nailsShortClean,
      'nails_no_polish': nailsNoPolish,
      'hands_clean': handsClean,
      'no_jewelry': noJewelry,
      'hair_covered': hairCovered,
      'no_beard': noBeard,
      'no_wounds': noWounds,
      if (observations != null && observations!.isNotEmpty)
        'observations': observations,
      // created_by is auto-populated by database trigger
    };
  }
}
