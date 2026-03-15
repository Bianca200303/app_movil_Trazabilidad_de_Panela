
import 'package:intl/intl.dart';

// 1. Enums

/// Types of cleaning performed
enum CleaningType {
  daily,
  general,
  deep;

  String getDisplayName() {
    switch (this) {
      case CleaningType.daily:
        return 'Diaria';
      case CleaningType.general:
        return 'General';
      case CleaningType.deep:
        return 'Profunda';
    }
  }

  static CleaningType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
      case 'diaria':
        return CleaningType.daily;
      case 'general':
        return CleaningType.general;
      case 'deep':
      case 'profunda':
        return CleaningType.deep;
      default:
        throw ArgumentError('Unknown cleaning type: $value');
    }
  }
}

/// Products used in cleaning
enum CleaningProduct {
  chlorine,
  detergent,
  other;

  String getDisplayName() {
    switch (this) {
      case CleaningProduct.chlorine:
        return 'Cloro';
      case CleaningProduct.detergent:
        return 'Detergente';
      case CleaningProduct.other:
        return 'Otro';
    }
  }

  static CleaningProduct fromString(String value) {
    switch (value.toLowerCase()) {
      case 'chlorine':
      case 'cloro':
        return CleaningProduct.chlorine;
      case 'detergent':
      case 'detergente':
        return CleaningProduct.detergent;
      case 'other':
      case 'otro':
        return CleaningProduct.other;
      default:
        throw ArgumentError('Unknown cleaning product: $value');
    }
  }
}

// =====================================================
// 2. Constants - Cleaning Areas
// =====================================================

/// Area codes for the cleaning form (8 total areas)
class CleaningAreas {
  // Reception, Milling, and Drying
  static const String receptionMilling = 'reception_milling';

  // Thermal Treatment
  static const String thermalTreatment = 'thermal_treatment';

  // Homogenization, Sieving, and Packaging
  static const String homogenizationPackaging = 'homogenization_packaging';

  // Warehouses
  static const String warehouses = 'warehouses';

  // Changing Rooms
  static const String changingRooms = 'changing_rooms';

  // Restrooms
  static const String restrooms = 'restrooms';

  // Cleaning Equipment
  static const String cleaningEquipment = 'cleaning_equipment';

  // Reservoir
  static const String reservoir = 'reservoir';

  /// Get all area codes
  static List<String> get all => [
        receptionMilling,
        thermalTreatment,
        homogenizationPackaging,
        warehouses,
        changingRooms,
        restrooms,
        cleaningEquipment,
        reservoir,
      ];

  /// Get display name for area code
  static String getDisplayName(String code) {
    switch (code) {
      case receptionMilling:
        return 'Área de Recepción, molienda y secado';
      case thermalTreatment:
        return 'Área de Tratamiento térmico';
      case homogenizationPackaging:
        return 'Área de Homogenizado, tamizado y envasado';
      case warehouses:
        return 'Área de Almacenes';
      case changingRooms:
        return 'Área de Vestuarios';
      case restrooms:
        return 'Área de Servicios higiénicos';
      case cleaningEquipment:
        return 'Área de Implementos de limpieza';
      case reservoir:
        return 'Área de Reservorio';
      default:
        return code;
    }
  }
}

// =====================================================
// 3. Constants - Cleaning Point Templates
// =====================================================

/// Predefined cleaning points for each area (33 total points)
class CleaningPointTemplates {
  /// Get all cleaning points for a specific area
  static List<Map<String, String>> getPointsForArea(String areaCode) {
    switch (areaCode) {
      case CleaningAreas.receptionMilling:
        return _receptionMillingPoints;
      case CleaningAreas.thermalTreatment:
        return _thermalTreatmentPoints;
      case CleaningAreas.homogenizationPackaging:
        return _homogenizationPackagingPoints;
      case CleaningAreas.warehouses:
        return _warehousesPoints;
      case CleaningAreas.changingRooms:
        return _changingRoomsPoints;
      case CleaningAreas.restrooms:
        return _restroomsPoints;
      case CleaningAreas.cleaningEquipment:
        return _cleaningEquipmentPoints;
      case CleaningAreas.reservoir:
        return _reservoirPoints;
      default:
        return [];
    }
  }

  /// Reception, Milling, and Drying (3 points)
  static final List<Map<String, String>> _receptionMillingPoints = [
    {'code': 'walls', 'description': 'Paredes'},
    {'code': 'floors', 'description': 'Pisos'},
    {'code': 'mill', 'description': 'Trapiche'},
  ];

  /// Thermal Treatment (8 points)
  static final List<Map<String, String>> _thermalTreatmentPoints = [
    {'code': 'walls', 'description': 'Paredes'},
    {'code': 'doors_windows', 'description': 'Puertas, ventanas y mallas'},
    {'code': 'floors_channels', 'description': 'Pisos y canaletas'},
    {'code': 'filters', 'description': 'Filtros'},
    {'code': 'juice_container', 'description': 'Recipiente de jugo'},
    {'code': 'utensils', 'description': 'Utensilios'},
    {'code': 'pans', 'description': 'Pailas'},
    {'code': 'buckets', 'description': 'Baldes'},
  ];

  /// Homogenization, Sieving, and Packaging (5 points)
  static final List<Map<String, String>> _homogenizationPackagingPoints = [
    {'code': 'walls', 'description': 'Paredes'},
    {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
    {'code': 'floors', 'description': 'Pisos'},
    {'code': 'hoppers', 'description': 'Bunques'},
    {'code': 'utensils', 'description': 'Utensilios'},
  ];

  /// Warehouses (5 points)
  static final List<Map<String, String>> _warehousesPoints = [
    {'code': 'walls', 'description': 'Paredes'},
    {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
    {'code': 'floors', 'description': 'Pisos'},
    {'code': 'platform_scale', 'description': 'Balanza de plataforma'},
    {'code': 'pallets', 'description': 'Parihuelas'},
  ];

  /// Changing Rooms (4 points)
  static final List<Map<String, String>> _changingRoomsPoints = [
    {'code': 'walls', 'description': 'Paredes'},
    {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
    {'code': 'floors', 'description': 'Pisos'},
    {'code': 'lockers', 'description': 'Armario'},
  ];

  /// Restrooms (4 points)
  static final List<Map<String, String>> _restroomsPoints = [
    {'code': 'walls', 'description': 'Paredes'},
    {'code': 'doors_windows', 'description': 'Puertas y ventanas'},
    {'code': 'floors', 'description': 'Pisos'},
    {'code': 'bathrooms_sinks', 'description': 'Baños, lavatorios y duchas'},
  ];

  /// Cleaning Equipment (3 points)
  static final List<Map<String, String>> _cleaningEquipmentPoints = [
    {'code': 'bins_containers', 'description': 'Tachos y recipientes'},
    {'code': 'brooms_brushes', 'description': 'Escobas y escobillones'},
    {'code': 'other_equipment', 'description': 'Otros implementos'},
  ];

  /// Reservoir (2 points)
  static final List<Map<String, String>> _reservoirPoints = [
    {'code': 'tank', 'description': 'Tanque'},
    {'code': 'reservoir', 'description': 'Reservorio'},
  ];
}

// =====================================================
// 4. Parent Model - CleaningDisinfection
// =====================================================

/// Parent record for a cleaning and disinfection session
class CleaningDisinfection {
  final String id;
  final String cooperativeId;
  final String coopModuleId;
  final DateTime cleaningDate;
  final String? generalObservations;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (not in database, populated via query)
  final String? moduleName;
  final String? createdByName;

  CleaningDisinfection({
    required this.id,
    required this.cooperativeId,
    required this.coopModuleId,
    required this.cleaningDate,
    this.generalObservations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.moduleName,
    this.createdByName,
  });

  factory CleaningDisinfection.fromJson(Map<String, dynamic> json) {
    return CleaningDisinfection(
      id: json['id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      cleaningDate: DateTime.parse(json['cleaning_date'] as String),
      generalObservations: json['general_observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      moduleName: json['module_name'] as String?,
      createdByName: json['created_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'coop_module_id': coopModuleId,
      'cleaning_date': DateFormat('yyyy-MM-dd').format(cleaningDate),
      'general_observations': generalObservations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// =====================================================
// 5. Child Model - CleaningDisinfectionItem
// =====================================================

/// Individual cleaning point record
class CleaningDisinfectionItem {
  final String id;
  final String cleaningDisinfectionId;
  final String areaCode;
  final String pointCode;
  final String pointDescription;

  // Cleaning types (DEFAULT TRUE in DB)
  final bool isDailyCleaning;
  final bool isGeneralCleaning;
  final bool isDeepCleaning;

  // Products used (DEFAULT TRUE in DB)
  final bool usesChlorine;
  final bool usesDetergent;
  final bool usesOtherProduct;

  final String? observations;
  final DateTime createdAt;
  final DateTime updatedAt;

  CleaningDisinfectionItem({
    required this.id,
    required this.cleaningDisinfectionId,
    required this.areaCode,
    required this.pointCode,
    required this.pointDescription,
    this.isDailyCleaning = true,
    this.isGeneralCleaning = true,
    this.isDeepCleaning = true,
    this.usesChlorine = true,
    this.usesDetergent = true,
    this.usesOtherProduct = true,
    this.observations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CleaningDisinfectionItem.fromJson(Map<String, dynamic> json) {
    return CleaningDisinfectionItem(
      id: json['id'] as String,
      cleaningDisinfectionId: json['cleaning_disinfection_id'] as String,
      areaCode: json['area_code'] as String,
      pointCode: json['point_code'] as String,
      pointDescription: json['point_description'] as String,
      isDailyCleaning: json['is_daily_cleaning'] as bool? ?? true,
      isGeneralCleaning: json['is_general_cleaning'] as bool? ?? true,
      isDeepCleaning: json['is_deep_cleaning'] as bool? ?? true,
      usesChlorine: json['uses_chlorine'] as bool? ?? true,
      usesDetergent: json['uses_detergent'] as bool? ?? true,
      usesOtherProduct: json['uses_other_product'] as bool? ?? true,
      observations: json['observations'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cleaning_disinfection_id': cleaningDisinfectionId,
      'area_code': areaCode,
      'point_code': pointCode,
      'point_description': pointDescription,
      'is_daily_cleaning': isDailyCleaning,
      'is_general_cleaning': isGeneralCleaning,
      'is_deep_cleaning': isDeepCleaning,
      'uses_chlorine': usesChlorine,
      'uses_detergent': usesDetergent,
      'uses_other_product': usesOtherProduct,
      'observations': observations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// =====================================================
// 6. Request Classes for API
// =====================================================

/// Request class for creating a cleaning disinfection item
class CreateCleaningDisinfectionItemRequest {
  final String areaCode;
  final String pointCode;
  final String pointDescription;
  final CleaningType cleaningType;
  final Set<CleaningProduct> cleaningProducts;

  CreateCleaningDisinfectionItemRequest({
    required this.areaCode,
    required this.pointCode,
    required this.pointDescription,
    required this.cleaningType,
    required this.cleaningProducts,
  });

  Map<String, dynamic> toJson() {
    return {
      'area_code': areaCode,
      'point_code': pointCode,
      'point_description': pointDescription,
      // Convert cleaning type to booleans
      'is_daily_cleaning': cleaningType == CleaningType.daily,
      'is_general_cleaning': cleaningType == CleaningType.general,
      'is_deep_cleaning': cleaningType == CleaningType.deep,
      // Convert products set to booleans
      'uses_chlorine': cleaningProducts.contains(CleaningProduct.chlorine),
      'uses_detergent': cleaningProducts.contains(CleaningProduct.detergent),
      'uses_other_product': cleaningProducts.contains(CleaningProduct.other),
    };
  }
}

/// Request class for creating a complete cleaning disinfection record
class CreateCleaningDisinfectionRequest {
  final String coopModuleId;
  final DateTime cleaningDate;
  final String cooperativeId;
  final List<CreateCleaningDisinfectionItemRequest> items;
  final String? generalObservations;

  CreateCleaningDisinfectionRequest({
    required this.coopModuleId,
    required this.cleaningDate,
    required this.cooperativeId,
    required this.items,
    this.generalObservations,
  });

  Map<String, dynamic> toParentJson() {
    return {
      'coop_module_id': coopModuleId,
      'cleaning_date': DateFormat('yyyy-MM-dd').format(cleaningDate),
      'cooperative_id': cooperativeId,
      'general_observations': generalObservations,
    };
  }
}
