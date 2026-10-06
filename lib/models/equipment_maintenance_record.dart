import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';

// ============================================================================
// ENUM: MaintenanceType
// Represents the type of maintenance performed
// ============================================================================
enum MaintenanceType {
  preventive('P', 'Preventivo'),
  corrective('C', 'Correctivo');

  final String code;
  final String displayName;

  const MaintenanceType(this.code, this.displayName);

  /// Parse maintenance type from database code
  static MaintenanceType fromCode(String code) {
    return values.firstWhere(
      (type) => type.code == code,
      orElse: () => throw Exception('Invalid MaintenanceType code: $code'),
    );
  }
}

// ============================================================================
// MODEL: EquipmentMaintenanceRecord
// Represents a single equipment maintenance record
// ============================================================================
class EquipmentMaintenanceRecord {
  final String id;
  final String cooperativeId;
  final String coopModuleId;
  final DateTime maintenanceDate;
  final String equipmentName;
  final MaintenanceType maintenanceType;
  final String maintenanceCause;
  final String? materialsUsed; // Optional
  final double durationHours;
  final String responsiblePerson;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (from related tables)
  final String? moduleName; // From coop_modules join
  final String? registeredByName; // Nombre del usuario que registró (join users)

  const EquipmentMaintenanceRecord({
    required this.id,
    required this.cooperativeId,
    required this.coopModuleId,
    required this.maintenanceDate,
    required this.equipmentName,
    required this.maintenanceType,
    required this.maintenanceCause,
    this.materialsUsed,
    required this.durationHours,
    required this.responsiblePerson,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.moduleName,
    this.registeredByName,
  });

  /// Create EquipmentMaintenanceRecord from JSON (Supabase response)
  factory EquipmentMaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return EquipmentMaintenanceRecord(
      id: json['id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      maintenanceDate: DateTime.parse(json['maintenance_date'] as String),
      equipmentName: json['equipment_name'] as String,
      maintenanceType:
          MaintenanceType.fromCode(json['maintenance_type'] as String),
      maintenanceCause: json['maintenance_cause'] as String,
      materialsUsed: json['materials_used'] as String?,
      durationHours: (json['duration_hours'] as num).toDouble(),
      responsiblePerson: json['responsible_person'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Handle joined module name from nested object
      moduleName: json['module'] != null
          ? (json['module'] is Map
              ? json['module']['name'] as String?
              : null)
          : null,
      registeredByName: json['registered_by_user'] is Map
          ? '${json['registered_by_user']['first_name']} ${json['registered_by_user']['last_name']}'
          : null,
    );
  }

  /// Convert EquipmentMaintenanceRecord to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'coop_module_id': coopModuleId,
      'maintenance_date':
          maintenanceDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'equipment_name': equipmentName,
      'maintenance_type': maintenanceType.code,
      'maintenance_cause': maintenanceCause,
      if (materialsUsed != null) 'materials_used': materialsUsed,
      'duration_hours': durationHours,
      'responsible_person': responsiblePerson,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ============================================================================
  // HELPER METHODS: Formatting and display
  // ============================================================================

  /// Get formatted date (dd/MM/yyyy)
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(maintenanceDate);
  }

  /// Get formatted duration with "h" suffix
  String get formattedDuration {
    return '${durationHours.toStringAsFixed(1)} h';
  }

  /// Get maintenance type display name in Spanish
  String get maintenanceTypeDisplayName {
    return maintenanceType.displayName;
  }

  /// Check if materials were used
  bool get hasMaterials {
    return materialsUsed != null && materialsUsed!.trim().isNotEmpty;
  }

  /// Get formatted created date
  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  /// Get formatted updated date
  String get formattedUpdatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt);
  }

  // ============================================================================
  // COPY WITH: For creating modified copies
  // ============================================================================

  EquipmentMaintenanceRecord copyWith({
    String? id,
    String? cooperativeId,
    String? coopModuleId,
    DateTime? maintenanceDate,
    String? equipmentName,
    MaintenanceType? maintenanceType,
    String? maintenanceCause,
    String? materialsUsed,
    double? durationHours,
    String? responsiblePerson,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? moduleName,
  }) {
    return EquipmentMaintenanceRecord(
      id: id ?? this.id,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      coopModuleId: coopModuleId ?? this.coopModuleId,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      equipmentName: equipmentName ?? this.equipmentName,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      maintenanceCause: maintenanceCause ?? this.maintenanceCause,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      durationHours: durationHours ?? this.durationHours,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moduleName: moduleName ?? this.moduleName,
    );
  }
}

// ============================================================================
// REQUEST: CreateEquipmentMaintenanceRequest
// Data transfer object for creating a new equipment maintenance record
// ============================================================================
class CreateEquipmentMaintenanceRequest {
  final String coopModuleId;
  final DateTime maintenanceDate;
  final String equipmentName;
  final MaintenanceType maintenanceType;
  final String maintenanceCause;
  final String? materialsUsed; // Optional
  final double durationHours;
  final String responsiblePerson;

  const CreateEquipmentMaintenanceRequest({
    required this.coopModuleId,
    required this.maintenanceDate,
    required this.equipmentName,
    required this.maintenanceType,
    required this.maintenanceCause,
    this.materialsUsed,
    required this.durationHours,
    required this.responsiblePerson,
  });

  /// Convert to JSON for Supabase insert
  /// Note: created_by is auto-populated by database trigger
  Map<String, dynamic> toJson() {
    return {
      'cooperative_id': AppConfig.current.id,
      'coop_module_id': coopModuleId,
      'maintenance_date':
          maintenanceDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'equipment_name': equipmentName.trim(),
      'maintenance_type': maintenanceType.code,
      'maintenance_cause': maintenanceCause.trim(),
      if (materialsUsed != null && materialsUsed!.trim().isNotEmpty)
        'materials_used': materialsUsed!.trim(),
      'duration_hours': durationHours,
      'responsible_person': responsiblePerson.trim(),
    };
  }

  /// Validate request data
  List<String> validate() {
    final errors = <String>[];

    if (equipmentName.trim().isEmpty) {
      errors.add('El nombre del equipo es obligatorio');
    }

    if (maintenanceCause.trim().isEmpty) {
      errors.add('La causa del mantenimiento es obligatoria');
    }

    if (durationHours <= 0) {
      errors.add('La duración debe ser mayor a 0');
    }

    if (responsiblePerson.trim().isEmpty) {
      errors.add('El responsable es obligatorio');
    }

    return errors;
  }

  /// Check if request is valid
  bool get isValid => validate().isEmpty;
}

// ============================================================================
// REQUEST: UpdateEquipmentMaintenanceRequest
// Data transfer object for updating an existing equipment maintenance record
// ============================================================================
class UpdateEquipmentMaintenanceRequest {
  final String id;
  final String? coopModuleId;
  final DateTime? maintenanceDate;
  final String? equipmentName;
  final MaintenanceType? maintenanceType;
  final String? maintenanceCause;
  final String? materialsUsed;
  final double? durationHours;
  final String? responsiblePerson;

  const UpdateEquipmentMaintenanceRequest({
    required this.id,
    this.coopModuleId,
    this.maintenanceDate,
    this.equipmentName,
    this.maintenanceType,
    this.maintenanceCause,
    this.materialsUsed,
    this.durationHours,
    this.responsiblePerson,
  });

  /// Convert to JSON for Supabase update
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (coopModuleId != null) {
      json['coop_module_id'] = coopModuleId;
    }

    if (maintenanceDate != null) {
      json['maintenance_date'] =
          maintenanceDate!.toIso8601String().split('T')[0];
    }

    if (equipmentName != null) {
      json['equipment_name'] = equipmentName!.trim();
    }

    if (maintenanceType != null) {
      json['maintenance_type'] = maintenanceType!.code;
    }

    if (maintenanceCause != null) {
      json['maintenance_cause'] = maintenanceCause!.trim();
    }

    if (materialsUsed != null) {
      if (materialsUsed!.trim().isEmpty) {
        json['materials_used'] = null; // Clear materials if empty
      } else {
        json['materials_used'] = materialsUsed!.trim();
      }
    }

    if (durationHours != null) {
      json['duration_hours'] = durationHours;
    }

    if (responsiblePerson != null) {
      json['responsible_person'] = responsiblePerson!.trim();
    }

    return json;
  }

  /// Validate update request data
  List<String> validate() {
    final errors = <String>[];

    if (equipmentName != null && equipmentName!.trim().isEmpty) {
      errors.add('El nombre del equipo no puede estar vacío');
    }

    if (maintenanceCause != null && maintenanceCause!.trim().isEmpty) {
      errors.add('La causa del mantenimiento no puede estar vacía');
    }

    if (durationHours != null && durationHours! <= 0) {
      errors.add('La duración debe ser mayor a 0');
    }

    if (responsiblePerson != null && responsiblePerson!.trim().isEmpty) {
      errors.add('El responsable no puede estar vacío');
    }

    return errors;
  }

  /// Check if update request is valid
  bool get isValid => validate().isEmpty;
}
