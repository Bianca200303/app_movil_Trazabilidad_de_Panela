/// Nivel de alerta del cupo de un productor para una certificación/campaña.
/// Usado por la UI para decidir color y tipo de mensaje sin lógica en el widget.
enum QuotaStatusLevel {
  ok,       // < 80 % consumido — sin alerta
  warning,  // 80–99 % consumido — alerta amarilla
  exceeded, // >= 100 % — alerta roja
}

/// Estado de cupo de un productor para una certificación y campaña específicas.
/// Mapea directamente la respuesta del RPC get_producer_quota_statuses.
class ProducerQuotaStatus {
  final String quotaId;
  final String certName;
  final double cupoKg;
  final double acumuladoKg;
  final double disponibleKg;
  final double porcentajeUsado;
  final bool superado;
  final int year;
  final String? notes;

  const ProducerQuotaStatus({
    required this.quotaId,
    required this.certName,
    required this.cupoKg,
    required this.acumuladoKg,
    required this.disponibleKg,
    required this.porcentajeUsado,
    required this.superado,
    required this.year,
    this.notes,
  });

  factory ProducerQuotaStatus.fromJson(Map<String, dynamic> json) {
    return ProducerQuotaStatus(
      quotaId:         json['quota_id']         as String,
      certName:        json['cert_name']         as String,
      cupoKg:          (json['cupo_kg']          as num).toDouble(),
      acumuladoKg:     (json['acumulado_kg']     as num).toDouble(),
      disponibleKg:    (json['disponible_kg']    as num).toDouble(),
      porcentajeUsado: (json['porcentaje_usado'] as num).toDouble(),
      superado:        json['superado']          as bool,
      year:            json['year']              as int,
      notes:           json['notes']             as String?,
    );
  }

  // ─── Propiedades derivadas para la UI ───────────────────────────────────

  QuotaStatusLevel get statusLevel {
    if (superado) return QuotaStatusLevel.exceeded;
    if (porcentajeUsado >= 80) return QuotaStatusLevel.warning;
    return QuotaStatusLevel.ok;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProducerQuotaStatus && other.quotaId == quotaId;
  }

  @override
  int get hashCode => quotaId.hashCode;

  @override
  String toString() =>
      'ProducerQuotaStatus(cert: $certName, cupo: $cupoKg kg, '
      'acumulado: $acumuladoKg kg, superado: $superado)';
}

/// Resultado completo de una verificación de cupos.
/// Encapsula tanto los datos como el contexto de conectividad para que la UI
/// no necesite lógica extra: solo lee este objeto y decide qué mostrar.
class QuotaCheckResult {
  final List<ProducerQuotaStatus> statuses;

  /// true cuando la consulta no pudo ejecutarse por falta de conexión.
  /// La UI muestra un aviso suave en lugar de una alerta de cupo.
  final bool isOffline;

  const QuotaCheckResult({
    required this.statuses,
    this.isOffline = false,
  });

  static const QuotaCheckResult offline = QuotaCheckResult(
    statuses: [],
    isOffline: true,
  );

  static const QuotaCheckResult empty = QuotaCheckResult(
    statuses: [],
  );

  bool get hasQuotas   => statuses.isNotEmpty;
  bool get hasWarning  => statuses.any((s) => s.statusLevel == QuotaStatusLevel.warning);
  bool get hasExceeded => statuses.any((s) => s.statusLevel == QuotaStatusLevel.exceeded);
  bool get allOk       => !hasWarning && !hasExceeded;
}
