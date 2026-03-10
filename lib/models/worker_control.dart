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

  final List<WorkerEvaluation> workersList;

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
    this.workersList = const [],
  });

  factory WorkerControl.fromJson(Map<String, dynamic> json) {
    var extractedWorkers = <WorkerEvaluation>[];
    if (json['worker_control_items'] != null) {
      extractedWorkers = (json['worker_control_items'] as List)
          .map((item) => WorkerEvaluation.fromJson(item))
          .toList();
    }
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
      workersList: extractedWorkers,
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

  // --- REEMPLAZA TUS HELPER METHODS DEL FINAL POR ESTOS ---
  
  // 1. Devuelve los nombres separados por comas
  String get displayNames {
    if (workersList.isEmpty) return workerName; // Historial antiguo
    return workersList.map((w) => w.workerName).join(', '); // Historial nuevo
  }

  // 2. Calcula el total de criterios a evaluar (9 por persona)
  int get totalCriteria => workersList.isEmpty ? 9 : workersList.length * 9;

  // 3. Suma los cumplimientos
  int get complianceCount {
    if (workersList.isEmpty) {
      // Lógica antigua para compatibilidad
      final items = [uniformComplete, noMakeup, nailsShortClean, nailsNoPolish, handsClean, noJewelry, hairCovered, noBeard, noWounds];
      return items.where((v) => v).length;
    } else {
      // Lógica nueva: Suma los puntos de todos los trabajadores de la lista
      return workersList.fold(0, (sum, worker) => sum + worker.complianceCount);
    }
  }

  // 4. Porcentaje general del grupo
  double get compliancePercentage => totalCriteria == 0 ? 0 : (complianceCount / totalCriteria) * 100;

  bool get isFullyCompliant => complianceCount == totalCriteria;

}

// Request class for creating new worker control records
class CreateWorkerControlRequest {
  // 1. Datos generales (La Cabecera)
  final String productionBatchId;
  final WorkArea workArea;
  final String? observations;
  final String cooperativeId;

  // 2. La lista de trabajadores (Los Detalles)
  final List<WorkerEvaluation> workers;

  const CreateWorkerControlRequest({
    required this.productionBatchId,
    required this.workArea,
    this.observations,
    required this.cooperativeId,
    required this.workers,
  });

  // Nota: Dejé el toJson vacío por ahora porque lo vamos a cambiar
  // en el Paso 2 cuando toquemos el Service de Supabase.
  Map<String, dynamic> toHeaderJson() {
    return {
      'cooperative_id': cooperativeId,
      'production_batch_id': productionBatchId,
      'work_area': workArea.code,
      if (observations != null && observations!.isNotEmpty)
        'observations': observations,
    };
  }
}

class WorkerEvaluation {
  final String workerName;
  final bool uniformComplete;
  final bool noMakeup;
  final bool nailsShortClean;
  final bool nailsNoPolish;
  final bool handsClean;
  final bool noJewelry;
  final bool hairCovered;
  final bool noBeard;
  final bool noWounds;

  const WorkerEvaluation({
    required this.workerName,
    this.uniformComplete = true,
    this.noMakeup = true,
    this.nailsShortClean = true,
    this.nailsNoPolish = true,
    this.handsClean = true,
    this.noJewelry = true,
    this.hairCovered = true,
    this.noBeard = true,
    this.noWounds = true,
  });

  factory WorkerEvaluation.fromJson(Map<String, dynamic> json) {
    return WorkerEvaluation(
      workerName: json['worker_name'] ?? 'Desconocido',
      uniformComplete: json['uniform_complete'] ?? true,
      noMakeup: json['no_makeup'] ?? true,
      nailsShortClean: json['nails_short_clean'] ?? true,
      nailsNoPolish: json['nails_no_polish'] ?? true,
      handsClean: json['hands_clean'] ?? true,
      noJewelry: json['no_jewelry'] ?? true,
      hairCovered: json['hair_covered'] ?? true,
      noBeard: json['no_beard'] ?? true,
      noWounds: json['no_wounds'] ?? true,
    );
  }

  Map<String, dynamic> toJson(String workerControlId) {
    return {
      'worker_control_id': workerControlId,
      'worker_name': workerName,
      'uniform_complete': uniformComplete,
      'no_makeup': noMakeup,
      'nails_short_clean': nailsShortClean,
      'nails_no_polish': nailsNoPolish,
      'hands_clean': handsClean,
      'no_jewelry': noJewelry,
      'hair_covered': hairCovered,
      'no_beard': noBeard,
      'no_wounds': noWounds,
    };
  }

  // NUEVO: Permite crear una copia del objeto modificando solo campos específicos
  WorkerEvaluation copyWith({
    String? workerName,
    bool? uniformComplete,
    bool? noMakeup,
    bool? nailsShortClean,
    bool? nailsNoPolish,
    bool? handsClean,
    bool? noJewelry,
    bool? hairCovered,
    bool? noBeard,
    bool? noWounds,
  }) {
    return WorkerEvaluation(
      workerName: workerName ?? this.workerName,
      uniformComplete: uniformComplete ?? this.uniformComplete,
      noMakeup: noMakeup ?? this.noMakeup,
      nailsShortClean: nailsShortClean ?? this.nailsShortClean,
      nailsNoPolish: nailsNoPolish ?? this.nailsNoPolish,
      handsClean: handsClean ?? this.handsClean,
      noJewelry: noJewelry ?? this.noJewelry,
      hairCovered: hairCovered ?? this.hairCovered,
      noBeard: noBeard ?? this.noBeard,
      noWounds: noWounds ?? this.noWounds,
    );
  }

  int get complianceCount {
    final items = [uniformComplete, noMakeup, nailsShortClean, nailsNoPolish, handsClean, noJewelry, hairCovered, noBeard, noWounds];
    return items.where((v) => v).length;
  }
}
