class CertifiedWorker {
  final String id;
  final String firstName;
  final String lastName;
  final String? position;

  /// Fin de la certificación ('YYYY-MM-DD'). Null = no vence.
  final String? certifiedUntil;

  // Solo se cargan en la pantalla de gestión (CertifiedWorkersService
  // .fetchAllForManagement); en los formularios no hacen falta.
  final String? coopModuleId;
  final String? dni;
  final bool isActive;

  const CertifiedWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.position,
    this.certifiedUntil,
    this.coopModuleId,
    this.dni,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName';

  /// Certificación vencida: solo se advierte, el trabajador sigue
  /// seleccionable (se regulariza después sin frenar la producción).
  bool get isExpired {
    final until = certifiedUntil;
    if (until == null || until.isEmpty) return false;
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return until.compareTo(today) < 0;
  }

  factory CertifiedWorker.fromJson(Map<String, dynamic> json) {
    return CertifiedWorker(
      id:             json['id']              as String,
      firstName:      json['first_name']      as String,
      lastName:       json['last_name']       as String,
      position:       json['position']        as String?,
      certifiedUntil: json['certified_until'] as String?,
      coopModuleId:   json['coop_module_id']  as String?,
      dni:            json['dni']             as String?,
      isActive:       json['is_active']       as bool? ?? true,
    );
  }
}
