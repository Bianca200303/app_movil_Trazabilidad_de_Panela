// Enums for stowage and transport inspection
enum VehicleCondition {
  adequate,
  deficient;

  String get value {
    switch (this) {
      case VehicleCondition.adequate:
        return 'adequate';
      case VehicleCondition.deficient:
        return 'deficient';
    }
  }

  static VehicleCondition fromString(String value) {
    return VehicleCondition.values.firstWhere(
      (condition) => condition.value == value,
      orElse: () => VehicleCondition.adequate,
    );
  }
}

extension VehicleConditionExtension on VehicleCondition {
  String get displayName {
    switch (this) {
      case VehicleCondition.adequate:
        return 'Adecuada';
      case VehicleCondition.deficient:
        return 'Deficiente';
    }
  }
}

enum SackCondition {
  good,
  regular,
  bad;

  String get value {
    switch (this) {
      case SackCondition.good:
        return 'good';
      case SackCondition.regular:
        return 'regular';
      case SackCondition.bad:
        return 'bad';
    }
  }

  static SackCondition fromString(String value) {
    return SackCondition.values.firstWhere(
      (condition) => condition.value == value,
      orElse: () => SackCondition.good,
    );
  }
}

extension SackConditionExtension on SackCondition {
  String get displayName {
    switch (this) {
      case SackCondition.good:
        return 'Bueno';
      case SackCondition.regular:
        return 'Regular';
      case SackCondition.bad:
        return 'Malo';
    }
  }
}

class StowageTransportInspection {
  final String id;
  final String exitRegistrationId;
  final DateTime inspectionDate;
  final String cooperativeId;

  // Carrier data
  final String carrierName;
  final String? carrierRuc;
  final String? carrierLicense;

  // Vehicle data
  final String vehicleBrand;
  final String vehiclePlate;

  // Vehicle condition checklist
  final VehicleCondition vehicleCondition;
  final bool hasSpareTire;
  final bool hasValidSoat;
  final bool hasTechnicalReview;
  final bool hasFirstAidKit;
  final bool hasFireExtinguisher;
  final bool hasGps;
  final bool hasCleaningSupplies;

  // Cleaning conditions
  final bool floorsClean;
  final bool wallsClean;
  final bool ceilingsClean;
  final bool noStrangeOdors;
  final bool tarpClean;
  final bool palletsClean;

  // Sack conditions
  final SackCondition sackCleanCondition;
  final SackCondition sackTiedCondition;

  // Observations
  final String? observations;

  // Metadata
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StowageTransportInspection({
    required this.id,
    required this.exitRegistrationId,
    required this.inspectionDate,
    required this.cooperativeId,
    required this.carrierName,
    this.carrierRuc,
    this.carrierLicense,
    required this.vehicleBrand,
    required this.vehiclePlate,
    required this.vehicleCondition,
    required this.hasSpareTire,
    required this.hasValidSoat,
    required this.hasTechnicalReview,
    required this.hasFirstAidKit,
    required this.hasFireExtinguisher,
    required this.hasGps,
    required this.hasCleaningSupplies,
    required this.floorsClean,
    required this.wallsClean,
    required this.ceilingsClean,
    required this.noStrangeOdors,
    required this.tarpClean,
    required this.palletsClean,
    required this.sackCleanCondition,
    required this.sackTiedCondition,
    this.observations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StowageTransportInspection.fromJson(Map<String, dynamic> json) {
    return StowageTransportInspection(
      id: json['id'] as String,
      exitRegistrationId: json['exit_registration_id'] as String,
      inspectionDate: DateTime.parse(json['inspection_date'] as String),
      cooperativeId: json['cooperative_id'] as String,
      carrierName: json['carrier_name'] as String,
      carrierRuc: json['carrier_ruc'] as String?,
      carrierLicense: json['carrier_license'] as String?,
      vehicleBrand: json['vehicle_brand'] as String,
      vehiclePlate: json['vehicle_plate'] as String,
      vehicleCondition: VehicleCondition.fromString(json['vehicle_condition'] as String),
      hasSpareTire: json['has_spare_tire'] as bool,
      hasValidSoat: json['has_valid_soat'] as bool,
      hasTechnicalReview: json['has_technical_review'] as bool,
      hasFirstAidKit: json['has_first_aid_kit'] as bool,
      hasFireExtinguisher: json['has_fire_extinguisher'] as bool,
      hasGps: json['has_gps'] as bool,
      hasCleaningSupplies: json['has_cleaning_supplies'] as bool,
      floorsClean: json['floors_clean'] as bool,
      wallsClean: json['walls_clean'] as bool,
      ceilingsClean: json['ceilings_clean'] as bool,
      noStrangeOdors: json['no_strange_odors'] as bool,
      tarpClean: json['tarp_clean'] as bool,
      palletsClean: json['pallets_clean'] as bool,
      sackCleanCondition: SackCondition.fromString(json['sack_clean_condition'] as String),
      sackTiedCondition: SackCondition.fromString(json['sack_tied_condition'] as String),
      observations: json['observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exit_registration_id': exitRegistrationId,
      'inspection_date': inspectionDate.toIso8601String().split('T')[0], // Date only
      'cooperative_id': cooperativeId,
      'carrier_name': carrierName,
      'carrier_ruc': carrierRuc,
      'carrier_license': carrierLicense,
      'vehicle_brand': vehicleBrand,
      'vehicle_plate': vehiclePlate,
      'vehicle_condition': vehicleCondition.value,
      'has_spare_tire': hasSpareTire,
      'has_valid_soat': hasValidSoat,
      'has_technical_review': hasTechnicalReview,
      'has_first_aid_kit': hasFirstAidKit,
      'has_fire_extinguisher': hasFireExtinguisher,
      'has_gps': hasGps,
      'has_cleaning_supplies': hasCleaningSupplies,
      'floors_clean': floorsClean,
      'walls_clean': wallsClean,
      'ceilings_clean': ceilingsClean,
      'no_strange_odors': noStrangeOdors,
      'tarp_clean': tarpClean,
      'pallets_clean': palletsClean,
      'sack_clean_condition': sackCleanCondition.value,
      'sack_tied_condition': sackTiedCondition.value,
      'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StowageTransportInspection copyWith({
    String? id,
    String? exitRegistrationId,
    DateTime? inspectionDate,
    String? cooperativeId,
    String? carrierName,
    String? carrierRuc,
    String? carrierLicense,
    String? vehicleBrand,
    String? vehiclePlate,
    VehicleCondition? vehicleCondition,
    bool? hasSpareTire,
    bool? hasValidSoat,
    bool? hasTechnicalReview,
    bool? hasFirstAidKit,
    bool? hasFireExtinguisher,
    bool? hasGps,
    bool? hasCleaningSupplies,
    bool? floorsClean,
    bool? wallsClean,
    bool? ceilingsClean,
    bool? noStrangeOdors,
    bool? tarpClean,
    bool? palletsClean,
    SackCondition? sackCleanCondition,
    SackCondition? sackTiedCondition,
    String? observations,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StowageTransportInspection(
      id: id ?? this.id,
      exitRegistrationId: exitRegistrationId ?? this.exitRegistrationId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      carrierName: carrierName ?? this.carrierName,
      carrierRuc: carrierRuc ?? this.carrierRuc,
      carrierLicense: carrierLicense ?? this.carrierLicense,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleCondition: vehicleCondition ?? this.vehicleCondition,
      hasSpareTire: hasSpareTire ?? this.hasSpareTire,
      hasValidSoat: hasValidSoat ?? this.hasValidSoat,
      hasTechnicalReview: hasTechnicalReview ?? this.hasTechnicalReview,
      hasFirstAidKit: hasFirstAidKit ?? this.hasFirstAidKit,
      hasFireExtinguisher: hasFireExtinguisher ?? this.hasFireExtinguisher,
      hasGps: hasGps ?? this.hasGps,
      hasCleaningSupplies: hasCleaningSupplies ?? this.hasCleaningSupplies,
      floorsClean: floorsClean ?? this.floorsClean,
      wallsClean: wallsClean ?? this.wallsClean,
      ceilingsClean: ceilingsClean ?? this.ceilingsClean,
      noStrangeOdors: noStrangeOdors ?? this.noStrangeOdors,
      tarpClean: tarpClean ?? this.tarpClean,
      palletsClean: palletsClean ?? this.palletsClean,
      sackCleanCondition: sackCleanCondition ?? this.sackCleanCondition,
      sackTiedCondition: sackTiedCondition ?? this.sackTiedCondition,
      observations: observations ?? this.observations,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StowageTransportInspection('
        'id: $id, '
        'exitRegistrationId: $exitRegistrationId, '
        'inspectionDate: $inspectionDate, '
        'carrierName: $carrierName, '
        'vehiclePlate: $vehiclePlate, '
        'vehicleCondition: ${vehicleCondition.displayName}, '
        'sackCleanCondition: ${sackCleanCondition.displayName}, '
        'sackTiedCondition: ${sackTiedCondition.displayName}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StowageTransportInspection &&
        other.id == id &&
        other.exitRegistrationId == exitRegistrationId &&
        other.inspectionDate == inspectionDate &&
        other.cooperativeId == cooperativeId &&
        other.carrierName == carrierName &&
        other.vehiclePlate == vehiclePlate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      exitRegistrationId,
      inspectionDate,
      cooperativeId,
      carrierName,
      vehiclePlate,
    );
  }

  // Helper methods
  String get formattedDate => '${inspectionDate.day.toString().padLeft(2, '0')}/'
      '${inspectionDate.month.toString().padLeft(2, '0')}/'
      '${inspectionDate.year}';

  // Check if all vehicle checklist items are OK
  bool get isVehicleChecklistComplete {
    return hasSpareTire &&
        hasValidSoat &&
        hasTechnicalReview &&
        hasFirstAidKit &&
        hasFireExtinguisher &&
        hasGps &&
        hasCleaningSupplies;
  }

  // Check if all cleaning items are OK
  bool get isCleaningChecklistComplete {
    return floorsClean &&
        wallsClean &&
        ceilingsClean &&
        noStrangeOdors &&
        tarpClean &&
        palletsClean;
  }

  // Overall inspection status
  bool get isFullyCompliant {
    return vehicleCondition == VehicleCondition.adequate &&
        isVehicleChecklistComplete &&
        isCleaningChecklistComplete &&
        sackCleanCondition == SackCondition.good &&
        sackTiedCondition == SackCondition.good;
  }
}

class CreateStowageTransportInspectionRequest {
  final String exitRegistrationId;
  final DateTime? inspectionDate;
  final String cooperativeId;
  final String carrierName;
  final String? carrierRuc;
  final String? carrierLicense;
  final String vehicleBrand;
  final String vehiclePlate;
  final VehicleCondition vehicleCondition;
  final bool hasSpareTire;
  final bool hasValidSoat;
  final bool hasTechnicalReview;
  final bool hasFirstAidKit;
  final bool hasFireExtinguisher;
  final bool hasGps;
  final bool hasCleaningSupplies;
  final bool floorsClean;
  final bool wallsClean;
  final bool ceilingsClean;
  final bool noStrangeOdors;
  final bool tarpClean;
  final bool palletsClean;
  final SackCondition sackCleanCondition;
  final SackCondition sackTiedCondition;
  final String? observations;
  final String createdBy;

  const CreateStowageTransportInspectionRequest({
    required this.exitRegistrationId,
    this.inspectionDate,
    required this.cooperativeId,
    required this.carrierName,
    this.carrierRuc,
    this.carrierLicense,
    required this.vehicleBrand,
    required this.vehiclePlate,
    required this.vehicleCondition,
    this.hasSpareTire = false,
    this.hasValidSoat = false,
    this.hasTechnicalReview = false,
    this.hasFirstAidKit = false,
    this.hasFireExtinguisher = false,
    this.hasGps = false,
    this.hasCleaningSupplies = false,
    this.floorsClean = false,
    this.wallsClean = false,
    this.ceilingsClean = false,
    this.noStrangeOdors = false,
    this.tarpClean = false,
    this.palletsClean = false,
    required this.sackCleanCondition,
    required this.sackTiedCondition,
    this.observations,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'exit_registration_id': exitRegistrationId,
      'inspection_date': inspectionDate?.toIso8601String().split('T')[0] ??
          DateTime.now().toIso8601String().split('T')[0],
      'cooperative_id': cooperativeId,
      'carrier_name': carrierName,
      'carrier_ruc': carrierRuc,
      'carrier_license': carrierLicense,
      'vehicle_brand': vehicleBrand,
      'vehicle_plate': vehiclePlate,
      'vehicle_condition': vehicleCondition.value,
      'has_spare_tire': hasSpareTire,
      'has_valid_soat': hasValidSoat,
      'has_technical_review': hasTechnicalReview,
      'has_first_aid_kit': hasFirstAidKit,
      'has_fire_extinguisher': hasFireExtinguisher,
      'has_gps': hasGps,
      'has_cleaning_supplies': hasCleaningSupplies,
      'floors_clean': floorsClean,
      'walls_clean': wallsClean,
      'ceilings_clean': ceilingsClean,
      'no_strange_odors': noStrangeOdors,
      'tarp_clean': tarpClean,
      'pallets_clean': palletsClean,
      'sack_clean_condition': sackCleanCondition.value,
      'sack_tied_condition': sackTiedCondition.value,
      'observations': observations,
      'created_by': createdBy,
    };
  }
}

class UpdateStowageTransportInspectionRequest {
  final DateTime? inspectionDate;
  final String? carrierName;
  final String? carrierRuc;
  final String? carrierLicense;
  final String? vehicleBrand;
  final String? vehiclePlate;
  final VehicleCondition? vehicleCondition;
  final bool? hasSpareTire;
  final bool? hasValidSoat;
  final bool? hasTechnicalReview;
  final bool? hasFirstAidKit;
  final bool? hasFireExtinguisher;
  final bool? hasGps;
  final bool? hasCleaningSupplies;
  final bool? floorsClean;
  final bool? wallsClean;
  final bool? ceilingsClean;
  final bool? noStrangeOdors;
  final bool? tarpClean;
  final bool? palletsClean;
  final SackCondition? sackCleanCondition;
  final SackCondition? sackTiedCondition;
  final String? observations;

  const UpdateStowageTransportInspectionRequest({
    this.inspectionDate,
    this.carrierName,
    this.carrierRuc,
    this.carrierLicense,
    this.vehicleBrand,
    this.vehiclePlate,
    this.vehicleCondition,
    this.hasSpareTire,
    this.hasValidSoat,
    this.hasTechnicalReview,
    this.hasFirstAidKit,
    this.hasFireExtinguisher,
    this.hasGps,
    this.hasCleaningSupplies,
    this.floorsClean,
    this.wallsClean,
    this.ceilingsClean,
    this.noStrangeOdors,
    this.tarpClean,
    this.palletsClean,
    this.sackCleanCondition,
    this.sackTiedCondition,
    this.observations,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (inspectionDate != null) {
      json['inspection_date'] = inspectionDate!.toIso8601String().split('T')[0];
    }
    if (carrierName != null) json['carrier_name'] = carrierName;
    if (carrierRuc != null) json['carrier_ruc'] = carrierRuc;
    if (carrierLicense != null) json['carrier_license'] = carrierLicense;
    if (vehicleBrand != null) json['vehicle_brand'] = vehicleBrand;
    if (vehiclePlate != null) json['vehicle_plate'] = vehiclePlate;
    if (vehicleCondition != null) json['vehicle_condition'] = vehicleCondition!.value;
    if (hasSpareTire != null) json['has_spare_tire'] = hasSpareTire;
    if (hasValidSoat != null) json['has_valid_soat'] = hasValidSoat;
    if (hasTechnicalReview != null) json['has_technical_review'] = hasTechnicalReview;
    if (hasFirstAidKit != null) json['has_first_aid_kit'] = hasFirstAidKit;
    if (hasFireExtinguisher != null) json['has_fire_extinguisher'] = hasFireExtinguisher;
    if (hasGps != null) json['has_gps'] = hasGps;
    if (hasCleaningSupplies != null) json['has_cleaning_supplies'] = hasCleaningSupplies;
    if (floorsClean != null) json['floors_clean'] = floorsClean;
    if (wallsClean != null) json['walls_clean'] = wallsClean;
    if (ceilingsClean != null) json['ceilings_clean'] = ceilingsClean;
    if (noStrangeOdors != null) json['no_strange_odors'] = noStrangeOdors;
    if (tarpClean != null) json['tarp_clean'] = tarpClean;
    if (palletsClean != null) json['pallets_clean'] = palletsClean;
    if (sackCleanCondition != null) json['sack_clean_condition'] = sackCleanCondition!.value;
    if (sackTiedCondition != null) json['sack_tied_condition'] = sackTiedCondition!.value;
    if (observations != null) json['observations'] = observations;

    return json;
  }

  bool get isEmpty => toJson().isEmpty;
}
