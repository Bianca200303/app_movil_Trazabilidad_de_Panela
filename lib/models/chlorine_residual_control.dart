// =====================================================
// Chlorine Residual Control Models
// =====================================================

import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';

// =====================================================
// 1. Main Model - ChlorineResidualControl
// =====================================================

/// Represents a chlorine residual control record with two measurement points
class ChlorineResidualControl {
  final String id;
  final String cooperativeId;
  final String coopModuleId;
  final DateTime controlDate;
  final String controlTime; // Format: "HH:mm:ss"
  final double measurementPoint1; // M1: Sanitization water supply (ppm)
  final double measurementPoint2; // M2: Process/sieving water supply (ppm)
  final String? correctiveActions;
  final String? observations;
  final String responsiblePerson;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (populated via query, not in database)
  final String? moduleName;

  ChlorineResidualControl({
    required this.id,
    required this.cooperativeId,
    required this.coopModuleId,
    required this.controlDate,
    required this.controlTime,
    required this.measurementPoint1,
    required this.measurementPoint2,
    this.correctiveActions,
    this.observations,
    required this.responsiblePerson,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.moduleName,
  });

  // ===== Factory Constructor =====

  factory ChlorineResidualControl.fromJson(Map<String, dynamic> json) {
    return ChlorineResidualControl(
      id: json['id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      controlDate: DateTime.parse(json['control_date'] as String),
      controlTime: json['control_time'] as String,
      measurementPoint1: (json['measurement_point_1'] as num).toDouble(),
      measurementPoint2: (json['measurement_point_2'] as num).toDouble(),
      correctiveActions: json['corrective_actions'] as String?,
      observations: json['observations'] as String?,
      responsiblePerson: json['responsible_person'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      moduleName: json['module_name'] as String?,
    );
  }

  // ===== Serialization =====

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'coop_module_id': coopModuleId,
      'control_date': DateFormat('yyyy-MM-dd').format(controlDate),
      'control_time': controlTime,
      'measurement_point_1': measurementPoint1,
      'measurement_point_2': measurementPoint2,
      'corrective_actions': correctiveActions,
      'observations': observations,
      'responsible_person': responsiblePerson,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ===== Helper Methods =====

  /// Formatted date for display (dd/MM/yyyy)
  String get formattedDate => DateFormat('dd/MM/yyyy').format(controlDate);

  /// Formatted time for display (HH:mm)
  String get formattedTime {
    // Handle both "HH:mm:ss" and "HH:mm" formats
    if (controlTime.length >= 5) {
      return controlTime.substring(0, 5);
    }
    return controlTime;
  }

  /// Combined date and time for display
  String get formattedDateTime => '$formattedDate $formattedTime';

  /// Check if M1 measurement is within safe range (0.5-2.0 ppm)
  bool get isM1InSafeRange =>
      measurementPoint1 >= 0.5 && measurementPoint1 <= 2.0;

  /// Check if M2 measurement is within safe range (0.5-2.0 ppm)
  bool get isM2InSafeRange =>
      measurementPoint2 >= 0.5 && measurementPoint2 <= 2.0;

  /// Check if both measurements are within safe range
  bool get areBothInSafeRange => isM1InSafeRange && isM2InSafeRange;

  /// Check if corrective actions are required (any measurement outside safe range)
  bool get requiresCorrectiveAction => !isM1InSafeRange || !isM2InSafeRange;

  /// Get warning message if measurements are outside safe range
  String? get safetyWarningMessage {
    if (areBothInSafeRange) return null;

    final issues = <String>[];
    if (!isM1InSafeRange) {
      issues.add('M1 (${measurementPoint1.toStringAsFixed(2)} ppm)');
    }
    if (!isM2InSafeRange) {
      issues.add('M2 (${measurementPoint2.toStringAsFixed(2)} ppm)');
    }

    return 'Fuera del rango seguro (0.5-2.0 ppm): ${issues.join(', ')}';
  }
}

// =====================================================
// 2. Request Class for Creating New Control
// =====================================================

/// Request class for creating a new chlorine residual control record
class CreateChlorineResidualControlRequest {
  final String coopModuleId;
  final DateTime controlDate;
  final String controlTime; // Format: "HH:mm:ss" or "HH:mm"
  final double measurementPoint1;
  final double measurementPoint2;
  final String? correctiveActions;
  final String? observations;
  final String responsiblePerson;

  const CreateChlorineResidualControlRequest({
    required this.coopModuleId,
    required this.controlDate,
    required this.controlTime,
    required this.measurementPoint1,
    required this.measurementPoint2,
    this.correctiveActions,
    this.observations,
    required this.responsiblePerson,
  });

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'cooperative_id': AppConfig.current.id,
      'coop_module_id': coopModuleId,
      'control_date': DateFormat('yyyy-MM-dd').format(controlDate),
      'control_time': _formatTime(controlTime),
      'measurement_point_1': measurementPoint1,
      'measurement_point_2': measurementPoint2,
      if (correctiveActions != null && correctiveActions!.trim().isNotEmpty)
        'corrective_actions': correctiveActions!.trim(),
      if (observations != null && observations!.trim().isNotEmpty)
        'observations': observations!.trim(),
      'responsible_person': responsiblePerson.trim(),
    };
  }

  /// Ensure time is in "HH:mm:ss" format
  String _formatTime(String time) {
    // If already has seconds, return as-is
    if (time.split(':').length == 3) {
      return time;
    }
    // If only HH:mm, append :00
    return '$time:00';
  }
}

// =====================================================
// 3. Request Class for Updating Control
// =====================================================

/// Request class for updating an existing chlorine residual control record
class UpdateChlorineResidualControlRequest {
  final String id;
  final DateTime? controlDate;
  final String? controlTime;
  final double? measurementPoint1;
  final double? measurementPoint2;
  final String? correctiveActions;
  final String? observations;
  final String? responsiblePerson;

  const UpdateChlorineResidualControlRequest({
    required this.id,
    this.controlDate,
    this.controlTime,
    this.measurementPoint1,
    this.measurementPoint2,
    this.correctiveActions,
    this.observations,
    this.responsiblePerson,
  });

  /// Convert to JSON for API submission (only include non-null fields)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (controlDate != null) {
      json['control_date'] = DateFormat('yyyy-MM-dd').format(controlDate!);
    }
    if (controlTime != null) {
      json['control_time'] = controlTime;
    }
    if (measurementPoint1 != null) {
      json['measurement_point_1'] = measurementPoint1;
    }
    if (measurementPoint2 != null) {
      json['measurement_point_2'] = measurementPoint2;
    }
    if (correctiveActions != null) {
      json['corrective_actions'] =
          correctiveActions!.trim().isEmpty ? null : correctiveActions!.trim();
    }
    if (observations != null) {
      json['observations'] =
          observations!.trim().isEmpty ? null : observations!.trim();
    }
    if (responsiblePerson != null) {
      json['responsible_person'] = responsiblePerson!.trim();
    }

    return json;
  }
}

// =====================================================
// 4. Helper Class for Safe Range Constants
// =====================================================

/// Constants for chlorine measurement safe ranges
class ChlorineSafeRange {
  static const double minSafePpm = 0.5;
  static const double maxSafePpm = 2.0;
  static const double minValidPpm = 0.0;
  static const double maxValidPpm = 10.0;

  /// Check if a measurement is within safe range
  static bool isSafe(double ppm) => ppm >= minSafePpm && ppm <= maxSafePpm;

  /// Check if a measurement is valid (within database constraints)
  static bool isValid(double ppm) => ppm >= minValidPpm && ppm <= maxValidPpm;

  /// Get status message for a measurement
  static String getStatusMessage(double ppm) {
    if (!isValid(ppm)) {
      return 'Fuera del rango válido (0-10 ppm)';
    }
    if (!isSafe(ppm)) {
      if (ppm < minSafePpm) {
        return 'Por debajo del rango seguro (0.5-2.0 ppm)';
      }
      return 'Por encima del rango seguro (0.5-2.0 ppm)';
    }
    return 'Dentro del rango seguro';
  }
}
