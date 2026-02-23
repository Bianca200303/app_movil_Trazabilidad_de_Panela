// Health incident model for tracking employee health incidents and accidents
// Based on MP-RE-HSS-04 form from Cooperativa Norandino

class HealthIncident {
  final String id;
  final String coopModuleId;
  final String employeeName;
  final String workArea;
  final DateTime registrationDate;
  final String symptomsDescription;
  final bool actionRest;
  final bool actionMedicalAttention;
  final bool actionRelocation;
  final bool actionMedication;
  final bool actionOther;
  final String? otherActionDetail;
  final DateTime? returnDate;
  final bool certificatePresented;
  final String cooperativeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthIncident({
    required this.id,
    required this.coopModuleId,
    required this.employeeName,
    required this.workArea,
    required this.registrationDate,
    required this.symptomsDescription,
    required this.actionRest,
    required this.actionMedicalAttention,
    required this.actionRelocation,
    required this.actionMedication,
    required this.actionOther,
    this.otherActionDetail,
    this.returnDate,
    required this.certificatePresented,
    required this.cooperativeId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthIncident.fromJson(Map<String, dynamic> json) {
    return HealthIncident(
      id: json['id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      employeeName: json['employee_name'] as String,
      workArea: json['work_area'] as String,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      symptomsDescription: json['symptoms_description'] as String,
      actionRest: json['action_rest'] as bool,
      actionMedicalAttention: json['action_medical_attention'] as bool,
      actionRelocation: json['action_relocation'] as bool,
      actionMedication: json['action_medication'] as bool,
      actionOther: json['action_other'] as bool,
      otherActionDetail: json['other_action_detail'] as String?,
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'] as String)
          : null,
      certificatePresented: json['certificate_presented'] as bool,
      cooperativeId: json['cooperative_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coop_module_id': coopModuleId,
      'employee_name': employeeName,
      'work_area': workArea,
      'registration_date': registrationDate.toIso8601String().split('T')[0],
      'symptoms_description': symptomsDescription,
      'action_rest': actionRest,
      'action_medical_attention': actionMedicalAttention,
      'action_relocation': actionRelocation,
      'action_medication': actionMedication,
      'action_other': actionOther,
      'other_action_detail': otherActionDetail,
      'return_date': returnDate?.toIso8601String().split('T')[0],
      'certificate_presented': certificatePresented,
      'cooperative_id': cooperativeId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for display
  String get formattedRegistrationDate =>
      '${registrationDate.day.toString().padLeft(2, '0')}/'
      '${registrationDate.month.toString().padLeft(2, '0')}/'
      '${registrationDate.year}';

  String get formattedReturnDate {
    if (returnDate == null) return 'No registrada';
    return '${returnDate!.day.toString().padLeft(2, '0')}/'
        '${returnDate!.month.toString().padLeft(2, '0')}/'
        '${returnDate!.year}';
  }

  String get actionsDisplayText {
    final List<String> actions = [];
    if (actionRest) actions.add('Descanso');
    if (actionMedicalAttention) actions.add('Atención médica');
    if (actionRelocation) actions.add('Reubicación');
    if (actionMedication) actions.add('Medicación');
    if (actionOther) {
      actions.add('Otro${otherActionDetail != null ? ': $otherActionDetail' : ''}');
    }
    return actions.isEmpty ? 'Ninguna' : actions.join(', ');
  }

  bool get hasAnyAction {
    return actionRest ||
        actionMedicalAttention ||
        actionRelocation ||
        actionMedication ||
        actionOther;
  }

  String get certificatePresentedText =>
      certificatePresented ? 'Sí' : 'No';
}

// Request class for creating new health incidents
class CreateHealthIncidentRequest {
  final String coopModuleId;
  final String employeeName;
  final String workArea;
  final DateTime registrationDate;
  final String symptomsDescription;
  final bool actionRest;
  final bool actionMedicalAttention;
  final bool actionRelocation;
  final bool actionMedication;
  final bool actionOther;
  final String? otherActionDetail;
  final DateTime? returnDate;
  final bool certificatePresented;
  final String cooperativeId;

  const CreateHealthIncidentRequest({
    required this.coopModuleId,
    required this.employeeName,
    required this.workArea,
    required this.registrationDate,
    required this.symptomsDescription,
    required this.actionRest,
    required this.actionMedicalAttention,
    required this.actionRelocation,
    required this.actionMedication,
    required this.actionOther,
    this.otherActionDetail,
    this.returnDate,
    required this.certificatePresented,
    required this.cooperativeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'coop_module_id': coopModuleId,
      'employee_name': employeeName,
      'work_area': workArea,
      'registration_date': registrationDate.toIso8601String().split('T')[0],
      'symptoms_description': symptomsDescription,
      'action_rest': actionRest,
      'action_medical_attention': actionMedicalAttention,
      'action_relocation': actionRelocation,
      'action_medication': actionMedication,
      'action_other': actionOther,
      if (otherActionDetail != null && otherActionDetail!.isNotEmpty)
        'other_action_detail': otherActionDetail,
      if (returnDate != null)
        'return_date': returnDate!.toIso8601String().split('T')[0],
      'certificate_presented': certificatePresented,
      'cooperative_id': cooperativeId,
      // created_by is auto-populated by database trigger
    };
  }
}
