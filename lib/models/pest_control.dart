// =====================================================
// Pest Control Models
// =====================================================

import 'package:intl/intl.dart';

// =====================================================
// 1. JSONB Structure Classes
// =====================================================

/// Represents a single bait station in the JSONB array
class BaitStation {
  final int stationNumber;
  final bool ate; // true = ate, false = didn't eat

  const BaitStation({
    required this.stationNumber,
    required this.ate,
  });

  factory BaitStation.fromJson(Map<String, dynamic> json) {
    return BaitStation(
      stationNumber: json['station_number'] as int,
      ate: json['ate'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_number': stationNumber,
      'ate': ate,
    };
  }

  BaitStation copyWith({
    int? stationNumber,
    bool? ate,
  }) {
    return BaitStation(
      stationNumber: stationNumber ?? this.stationNumber,
      ate: ate ?? this.ate,
    );
  }
}

/// Represents a single insect record in the JSONB array
class InsectData {
  final int? flies;
  final int? bees;
  final int? ants;
  final int? cockroaches;
  final String area;
  final String? observations;

  const InsectData({
    this.flies,
    this.bees,
    this.ants,
    this.cockroaches,
    required this.area,
    this.observations,
  });

  factory InsectData.fromJson(Map<String, dynamic> json) {
    return InsectData(
      flies: json['flies'] as int?,
      bees: json['bees'] as int?,
      ants: json['ants'] as int?,
      cockroaches: json['cockroaches'] as int?,
      area: json['area'] as String,
      observations: json['observations'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (flies != null) 'flies': flies,
      if (bees != null) 'bees': bees,
      if (ants != null) 'ants': ants,
      if (cockroaches != null) 'cockroaches': cockroaches,
      'area': area,
      if (observations != null && observations!.isNotEmpty)
        'observations': observations,
    };
  }

  /// Get total insect count across all types
  int getTotalCount() {
    return (flies ?? 0) + (bees ?? 0) + (ants ?? 0) + (cockroaches ?? 0);
  }

  InsectData copyWith({
    int? flies,
    int? bees,
    int? ants,
    int? cockroaches,
    String? area,
    String? observations,
  }) {
    return InsectData(
      flies: flies ?? this.flies,
      bees: bees ?? this.bees,
      ants: ants ?? this.ants,
      cockroaches: cockroaches ?? this.cockroaches,
      area: area ?? this.area,
      observations: observations ?? this.observations,
    );
  }
}

// =====================================================
// 2. Parent Model: PestControl
// =====================================================

class PestControl {
  final String id;
  final String cooperativeId;
  final String coopModuleId;
  final DateTime controlDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? moduleName;
  final String? registeredByName;

  const PestControl({
    required this.id,
    required this.cooperativeId,
    required this.coopModuleId,
    required this.controlDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.moduleName,
    this.registeredByName,
  });

  factory PestControl.fromJson(Map<String, dynamic> json) {
    return PestControl(
      id: json['id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      controlDate: DateTime.parse(json['control_date'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      moduleName: json['module']?['name'] as String?,
      registeredByName: json['registered_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'coop_module_id': coopModuleId,
      'control_date': DateFormat('yyyy-MM-dd').format(controlDate),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(controlDate);
  }
}

// =====================================================
// 3. Child Model: PestControlBaitRecord
// =====================================================

class PestControlBaitRecord {
  final String id;
  final String pestControlId;
  final String productName;
  final double quantity;
  final String unit;
  final List<BaitStation> baitStations;
  final String? baitObservations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PestControlBaitRecord({
    required this.id,
    required this.pestControlId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.baitStations,
    this.baitObservations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PestControlBaitRecord.fromJson(Map<String, dynamic> json) {
    return PestControlBaitRecord(
      id: json['id'] as String,
      pestControlId: json['pest_control_id'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      baitStations: (json['bait_stations'] as List)
          .map((e) => BaitStation.fromJson(e as Map<String, dynamic>))
          .toList(),
      baitObservations: json['bait_observations'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pest_control_id': pestControlId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'bait_stations': baitStations.map((s) => s.toJson()).toList(),
      if (baitObservations != null) 'bait_observations': baitObservations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  int get totalStations => baitStations.length;

  int get stationsWithBaitEaten =>
      baitStations.where((s) => s.ate).length;

  double get consumptionPercentage {
    if (totalStations == 0) return 0.0;
    return (stationsWithBaitEaten / totalStations) * 100;
  }
}

// =====================================================
// 4. Child Model: PestControlInsectRecord
// =====================================================

class PestControlInsectRecord {
  final String id;
  final String pestControlId;
  final String productName;
  final double quantity;
  final String unit;
  final List<InsectData> insectData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PestControlInsectRecord({
    required this.id,
    required this.pestControlId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.insectData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PestControlInsectRecord.fromJson(Map<String, dynamic> json) {
    return PestControlInsectRecord(
      id: json['id'] as String,
      pestControlId: json['pest_control_id'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      insectData: (json['insect_data'] as List)
          .map((e) => InsectData.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pest_control_id': pestControlId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'insect_data': insectData.map((d) => d.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  int get totalFlies => insectData.fold<int>(0, (sum, d) => sum + (d.flies ?? 0));

  int get totalBees => insectData.fold<int>(0, (sum, d) => sum + (d.bees ?? 0));

  int get totalAnts => insectData.fold<int>(0, (sum, d) => sum + (d.ants ?? 0));

  int get totalCockroaches =>
      insectData.fold<int>(0, (sum, d) => sum + (d.cockroaches ?? 0));

  int get totalInsects => totalFlies + totalBees + totalAnts + totalCockroaches;

  Set<String> get uniqueAreas => insectData.map((d) => d.area).toSet();
}

// =====================================================
// 5. Request Classes
// =====================================================

class CreatePestControlBaitRequest {
  final String productName;
  final double quantity;
  final String unit;
  final List<BaitStation> baitStations;
  final String? baitObservations;

  const CreatePestControlBaitRequest({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.baitStations,
    this.baitObservations,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'bait_stations': baitStations.map((s) => s.toJson()).toList(),
      if (baitObservations != null && baitObservations!.isNotEmpty)
        'bait_observations': baitObservations,
    };
  }
}

class CreatePestControlInsectRequest {
  final String productName;
  final double quantity;
  final String unit;
  final List<InsectData> insectData;

  const CreatePestControlInsectRequest({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.insectData,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'insect_data': insectData.map((d) => d.toJson()).toList(),
    };
  }
}

class CreatePestControlRequest {
  final String coopModuleId;
  final DateTime controlDate;
  final String cooperativeId;
  final CreatePestControlBaitRequest? baitRecord;
  final CreatePestControlInsectRequest? insectRecord;

  const CreatePestControlRequest({
    required this.coopModuleId,
    required this.controlDate,
    required this.cooperativeId,
    this.baitRecord,
    this.insectRecord,
  });

  Map<String, dynamic> toParentJson() {
    return {
      'coop_module_id': coopModuleId,
      'control_date': DateFormat('yyyy-MM-dd').format(controlDate),
      'cooperative_id': cooperativeId,
    };
  }
}
