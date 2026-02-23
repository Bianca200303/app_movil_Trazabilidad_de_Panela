class ExitRegistration {
  final String id;
  final String exitCode;
  final String? documentNumber;
  final DateTime exitDate;
  final double totalKg;
  final String exitType;
  final String? destination;
  final String? notes;
  final String cooperativeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExitRegistration({
    required this.id,
    required this.exitCode,
    this.documentNumber,
    required this.exitDate,
    required this.totalKg,
    required this.exitType,
    this.destination,
    this.notes,
    required this.cooperativeId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExitRegistration.fromJson(Map<String, dynamic> json) {
    return ExitRegistration(
      id: json['id'] as String,
      exitCode: json['exit_code'] as String,
      documentNumber: json['document_number'] as String?,
      exitDate: DateTime.parse(json['exit_date'] as String),
      totalKg: (json['total_kg'] as num).toDouble(),
      exitType: json['exit_type'] as String,
      destination: json['destination'] as String?,
      notes: json['notes'] as String?,
      cooperativeId: json['cooperative_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exit_code': exitCode,
      'document_number': documentNumber,
      'exit_date': exitDate.toIso8601String().split('T')[0], // Date only
      'total_kg': totalKg,
      'exit_type': exitType,
      'destination': destination,
      'notes': notes,
      'cooperative_id': cooperativeId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ExitRegistration copyWith({
    String? id,
    String? exitCode,
    String? documentNumber,
    DateTime? exitDate,
    double? totalKg,
    String? exitType,
    String? destination,
    String? notes,
    String? cooperativeId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExitRegistration(
      id: id ?? this.id,
      exitCode: exitCode ?? this.exitCode,
      documentNumber: documentNumber ?? this.documentNumber,
      exitDate: exitDate ?? this.exitDate,
      totalKg: totalKg ?? this.totalKg,
      exitType: exitType ?? this.exitType,
      destination: destination ?? this.destination,
      notes: notes ?? this.notes,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ExitRegistration('
        'id: $id, '
        'exitCode: $exitCode, '
        'documentNumber: $documentNumber, '
        'exitDate: $exitDate, '
        'totalKg: $totalKg, '
        'exitType: $exitType, '
        'destination: $destination, '
        'cooperativeId: $cooperativeId, '
        'createdBy: $createdBy'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExitRegistration &&
        other.id == id &&
        other.exitCode == exitCode &&
        other.documentNumber == documentNumber &&
        other.exitDate == exitDate &&
        other.totalKg == totalKg &&
        other.exitType == exitType &&
        other.destination == destination &&
        other.notes == notes &&
        other.cooperativeId == cooperativeId &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      exitCode,
      documentNumber,
      exitDate,
      totalKg,
      exitType,
      destination,
      notes,
      cooperativeId,
      createdBy,
    );
  }

  // Helper methods
  bool get isToday => 
      exitDate.year == DateTime.now().year &&
      exitDate.month == DateTime.now().month &&
      exitDate.day == DateTime.now().day;

  String get formattedDate => '${exitDate.day.toString().padLeft(2, '0')}/'
      '${exitDate.month.toString().padLeft(2, '0')}/'
      '${exitDate.year}';

  int get totalBags => (totalKg / 50).round();
}

class CreateExitRegistrationRequest {
  final String? exitCode; // Optional, will be auto-generated if not provided
  final String? documentNumber;
  final DateTime? exitDate;
  final String exitType;
  final String? destination;
  final String? notes;
  final String cooperativeId;
  final String createdBy; // User ID (DNI) of the user creating the exit

  const CreateExitRegistrationRequest({
    this.exitCode,
    this.documentNumber,
    this.exitDate,
    this.exitType = 'SALIDA',
    this.destination,
    this.notes,
    required this.cooperativeId,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'exit_type': exitType,
      'cooperative_id': cooperativeId,
      'created_by': createdBy,
    };

    if (exitCode != null) json['exit_code'] = exitCode;
    if (documentNumber != null) json['document_number'] = documentNumber;
    if (exitDate != null) json['exit_date'] = exitDate!.toIso8601String().split('T')[0];
    if (destination != null) json['destination'] = destination;
    if (notes != null) json['notes'] = notes;

    return json;
  }
}

class UpdateExitRegistrationRequest {
  final String? documentNumber;
  final DateTime? exitDate;
  final String? exitType;
  final String? destination;
  final String? notes;

  const UpdateExitRegistrationRequest({
    this.documentNumber,
    this.exitDate,
    this.exitType,
    this.destination,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (documentNumber != null) json['document_number'] = documentNumber;
    if (exitDate != null) json['exit_date'] = exitDate!.toIso8601String().split('T')[0];
    if (exitType != null) json['exit_type'] = exitType;
    if (destination != null) json['destination'] = destination;
    if (notes != null) json['notes'] = notes;

    return json;
  }

  bool get isEmpty => 
      documentNumber == null &&
      exitDate == null &&
      exitType == null &&
      destination == null &&
      notes == null;
}

// Enum for exit types
enum ExitType {
  salida('SALIDA'),
  ajuste('AJUSTE'),
  merma('MERMA');

  const ExitType(this.value);
  final String value;

  static ExitType fromString(String value) {
    return ExitType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ExitType.salida,
    );
  }
}