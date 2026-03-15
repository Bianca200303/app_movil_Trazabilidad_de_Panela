// Enum for inspection condition
enum InspectionCondition {
  compliant,
  nonCompliant;

  String get value {
    switch (this) {
      case InspectionCondition.compliant:
        return 'compliant';
      case InspectionCondition.nonCompliant:
        return 'non_compliant';
    }
  }

  static InspectionCondition fromString(String value) {
    return InspectionCondition.values.firstWhere(
      (condition) => condition.value == value,
      orElse: () => InspectionCondition.compliant,
    );
  }
}

extension InspectionConditionExtension on InspectionCondition {
  String get displayName {
    switch (this) {
      case InspectionCondition.compliant:
        return 'C';
      case InspectionCondition.nonCompliant:
        return 'NC';
    }
  }

  String get fullDisplayName {
    switch (this) {
      case InspectionCondition.compliant:
        return 'Conforme';
      case InspectionCondition.nonCompliant:
        return 'No Conforme';
    }
  }
}

// Area codes constants
class EnvironmentInspectionAreas {
  static const String receptionMilling = 'reception_milling';
  static const String thermalTreatment = 'thermal_treatment';
  static const String sievingPacking = 'sieving_packing';
  static const String warehouses = 'warehouses';
  static const String dressingRooms = 'dressing_rooms';
  static const String restrooms = 'restrooms';
  static const String cleaningImplements = 'cleaning_implements';
  static const String reservoir = 'reservoir';

  static List<String> get all => [
        receptionMilling,
        thermalTreatment,
        sievingPacking,
        warehouses,
        dressingRooms,
        restrooms,
        cleaningImplements,
        reservoir,
      ];

  static String getDisplayName(String code) {
    switch (code) {
      case receptionMilling:
        return 'ÁREA DE RECEPCIÓN MATERIA PRIMA – MOLIENDA – SECADO DE BAGAZO';
      case thermalTreatment:
        return 'ÁREA DE TRATAMIENTO TÉRMICO';
      case sievingPacking:
        return 'ÁREA DE TAMIZADO Y ENVASADO';
      case warehouses:
        return 'ÁREA DE ALMACENES';
      case dressingRooms:
        return 'ÁREA DE VESTUARIOS';
      case restrooms:
        return 'ÁREA DE SERVICIOS HIGIÉNICOS';
      case cleaningImplements:
        return 'ÁREA DE IMPLEMENTOS DE LIMPIEZA';
      case reservoir:
        return 'ÁREA DE RESERVORIO';
      default:
        return code;
    }
  }
}

// Predefined checklist items per area
class EnvironmentInspectionItemTemplates {
  static List<Map<String, String>> getItemsForArea(String areaCode) {
    switch (areaCode) {
      case EnvironmentInspectionAreas.receptionMilling:
        return [
          {'code': 'walls', 'description': 'Paredes'},
          {'code': 'floors', 'description': 'Pisos'},
          {'code': 'mill', 'description': 'Trapiche'},
          {'code': 'engine', 'description': 'Motor'},
          {'code': 'personnel', 'description': 'Personal'},
          {'code': 'pests', 'description': 'Presencia o signos de plagas'},
        ];
      case EnvironmentInspectionAreas.thermalTreatment:
        return [
          {'code': 'walls', 'description': 'Paredes'},
          {
            'code': 'doors_windows_screens',
            'description': 'Puertas, ventanas y mallas'
          },
          {'code': 'floors_gutters', 'description': 'Pisos y canaletas'},
          {'code': 'filters', 'description': 'Filtros'},
          {'code': 'juice_receiver', 'description': 'Receptor de jugo'},
          {'code': 'utensils', 'description': 'Utensilios'},
          {'code': 'pans', 'description': 'Pailas'},
          {'code': 'buckets', 'description': 'Baldes'},
          {'code': 'personnel', 'description': 'Personal'},
        ];
      case EnvironmentInspectionAreas.sievingPacking:
        return [
          {'code': 'walls', 'description': 'Paredes'},
          {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
          {'code': 'floors', 'description': 'Pisos'},
          {'code': 'bunkers', 'description': 'Bunques'},
          {'code': 'utensils', 'description': 'Utensilios'},
          {'code': 'personnel', 'description': 'Personal'},
          {'code': 'pests', 'description': 'Presencia o signos de plagas'},
        ];
      case EnvironmentInspectionAreas.warehouses:
        return [
          {'code': 'walls', 'description': 'Paredes'},
          {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
          {'code': 'floors', 'description': 'Pisos'},
          {'code': 'platform_scale', 'description': 'Balanza plataforma'},
          {'code': 'pallets', 'description': 'Parihuelas'},
          {'code': 'pests', 'description': 'Presencia o signos de plagas'},
        ];
      case EnvironmentInspectionAreas.dressingRooms:
        return [
          {'code': 'walls', 'description': 'Paredes'},
          {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
          {'code': 'floors', 'description': 'Pisos'},
          {'code': 'lockers', 'description': 'Armario'},
        ];
      case EnvironmentInspectionAreas.restrooms:
        return [
          {'code': 'walls', 'description': 'Paredes'},
          {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
          {'code': 'floors', 'description': 'Pisos'},
          {
            'code': 'bathrooms_sinks_showers',
            'description': 'Baños, lavatorios y duchas'
          },
        ];
      case EnvironmentInspectionAreas.cleaningImplements:
        return [
          {
            'code': 'color_chart',
            'description': 'Según cartilla colores MP-IN-HSS-02'
          },
          {
            'code': 'trash_bins',
            'description': 'Tachos y recipientes de basura limpios y con bolsa interna'
          },
          {'code': 'cleanliness_order', 'description': 'Limpieza y orden'},
        ];
      case EnvironmentInspectionAreas.reservoir:
        return [
          {'code': 'tank', 'description': 'Tanque'},
          {'code': 'reservoir', 'description': 'Reservorio'},
        ];
      default:
        return [];
    }
  }

  static int getTotalItemCount() {
    return EnvironmentInspectionAreas.all
        .map((area) => getItemsForArea(area).length)
        .reduce((a, b) => a + b);
  }

  static String? getPersonnelNote(String itemCode) {
    if (itemCode == 'personnel') {
      return 'Uniforme correcto, uñas/manos limpias, cabello recogido, sin joyas, conducta adecuada, sin signos de enfermedad';
    }
    return null;
  }
}

// Child model: Individual inspection item
class EnvironmentInspectionItem {
  final String id;
  final String environmentInspectionId;
  final String areaCode;
  final String itemCode;
  final String itemDescription;
  final InspectionCondition condition;
  final String? correctiveActions;
  final String? observations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EnvironmentInspectionItem({
    required this.id,
    required this.environmentInspectionId,
    required this.areaCode,
    required this.itemCode,
    required this.itemDescription,
    required this.condition,
    this.correctiveActions,
    this.observations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnvironmentInspectionItem.fromJson(Map<String, dynamic> json) {
    return EnvironmentInspectionItem(
      id: json['id'] as String,
      environmentInspectionId: json['environment_inspection_id'] as String,
      areaCode: json['area_code'] as String,
      itemCode: json['item_code'] as String,
      itemDescription: json['item_description'] as String,
      condition: InspectionCondition.fromString(json['condition'] as String),
      correctiveActions: json['corrective_actions'] as String?,
      observations: json['observations'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'environment_inspection_id': environmentInspectionId,
      'area_code': areaCode,
      'item_code': itemCode,
      'item_description': itemDescription,
      'condition': condition.value,
      'corrective_actions': correctiveActions,
      'observations': observations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isCompliant => condition == InspectionCondition.compliant;
  bool get hasCorrectiveActions =>
      correctiveActions != null && correctiveActions!.isNotEmpty;
  bool get hasObservations => observations != null && observations!.isNotEmpty;
  String? get personnelNote =>
      EnvironmentInspectionItemTemplates.getPersonnelNote(itemCode);
}

// Parent model: Environment inspection
class EnvironmentInspection {
  final String id;
  final String coopModuleId;
  final DateTime inspectionDate;
  final String cooperativeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Associated items (loaded via JOIN or separate query)
  final List<EnvironmentInspectionItem>? items;

  const EnvironmentInspection({
    required this.id,
    required this.coopModuleId,
    required this.inspectionDate,
    required this.cooperativeId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory EnvironmentInspection.fromJson(Map<String, dynamic> json) {
    // Handle items if included in response
    List<EnvironmentInspectionItem>? items;
    if (json['environment_inspection_items'] != null) {
      items = (json['environment_inspection_items'] as List)
          .map((item) => EnvironmentInspectionItem.fromJson(item))
          .toList();
    }

    return EnvironmentInspection(
      id: json['id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      inspectionDate: DateTime.parse(json['inspection_date'] as String),
      cooperativeId: json['cooperative_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coop_module_id': coopModuleId,
      'inspection_date': inspectionDate.toIso8601String().split('T')[0],
      'cooperative_id': cooperativeId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedDate =>
      '${inspectionDate.day.toString().padLeft(2, '0')}/'
      '${inspectionDate.month.toString().padLeft(2, '0')}/'
      '${inspectionDate.year}';

  // Compliance calculations (requires items to be loaded)
  int get totalItems => items?.length ?? 0;

  int get compliantItems =>
      items?.where((item) => item.isCompliant).length ?? 0;

  int get nonCompliantItems =>
      items?.where((item) => !item.isCompliant).length ?? 0;

  double get compliancePercentage {
    if (totalItems == 0) return 0.0;
    return (compliantItems / totalItems) * 100;
  }

  bool get isFullyCompliant => totalItems > 0 && nonCompliantItems == 0;

  // Get items by area
  List<EnvironmentInspectionItem> getItemsForArea(String areaCode) {
    return items?.where((item) => item.areaCode == areaCode).toList() ?? [];
  }

  // Area compliance status
  Map<String, bool> getAreaComplianceMap() {
    final map = <String, bool>{};
    for (final area in EnvironmentInspectionAreas.all) {
      final areaItems = getItemsForArea(area);
      map[area] =
          areaItems.isNotEmpty && areaItems.every((item) => item.isCompliant);
    }
    return map;
  }

  // Count non-compliant items by area
  Map<String, int> getNonCompliantCountByArea() {
    final map = <String, int>{};
    for (final area in EnvironmentInspectionAreas.all) {
      final areaItems = getItemsForArea(area);
      map[area] = areaItems.where((item) => !item.isCompliant).length;
    }
    return map;
  }
}

// Request classes for API calls
class CreateEnvironmentInspectionItemRequest {
  final String areaCode;
  final String itemCode;
  final String itemDescription;
  final InspectionCondition condition;
  final String? correctiveActions;
  final String? observations;

  const CreateEnvironmentInspectionItemRequest({
    required this.areaCode,
    required this.itemCode,
    required this.itemDescription,
    required this.condition,
    this.correctiveActions,
    this.observations,
  });

  Map<String, dynamic> toJson() {
    return {
      'area_code': areaCode,
      'item_code': itemCode,
      'item_description': itemDescription,
      'condition': condition.value,
      if (correctiveActions != null && correctiveActions!.isNotEmpty)
        'corrective_actions': correctiveActions,
      if (observations != null && observations!.isNotEmpty)
        'observations': observations,
    };
  }
}

class CreateEnvironmentInspectionRequest {
  final String coopModuleId;
  final DateTime? inspectionDate;
  final String cooperativeId;
  final List<CreateEnvironmentInspectionItemRequest> items;

  const CreateEnvironmentInspectionRequest({
    required this.coopModuleId,
    this.inspectionDate,
    required this.cooperativeId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'coop_module_id': coopModuleId,
      'inspection_date': inspectionDate?.toIso8601String().split('T')[0] ??
          DateTime.now().toIso8601String().split('T')[0],
      'cooperative_id': cooperativeId,
      // created_by is auto-populated by database trigger
    };
  }
}
