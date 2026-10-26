enum UserRole {
  adminSistema,
  adminModulo,
  tecnicoCampo,
  productor;

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin_sistema':
        return UserRole.adminSistema;
      case 'admin_modulo':
        return UserRole.adminModulo;
      case 'tecnico_campo':
        return UserRole.tecnicoCampo;
      default:
        return UserRole.productor;
    }
  }

  String get value {
    switch (this) {
      case UserRole.adminSistema:
        return 'admin_sistema';
      case UserRole.adminModulo:
        return 'admin_modulo';
      case UserRole.tecnicoCampo:
        return 'tecnico_campo';
      case UserRole.productor:
        return 'productor';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.adminSistema:
        return 'Administrador del Sistema';
      case UserRole.adminModulo:
        return 'Administrador de Módulo';
      case UserRole.tecnicoCampo:
        return 'Técnico de Campo';
      case UserRole.productor:
        return 'Productor';
    }
  }
}

class CurrentUser {
  final String dni;
  final String firstName;
  final String lastName;
  final UserRole role;
  /// Module IDs assigned to this user (relevant for adminModulo and tecnicoCampo).
  final List<String> moduleIds;

  const CurrentUser({
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.moduleIds = const [],
  });

  String get fullName => '$firstName $lastName';

  bool get isAdminSistema => role == UserRole.adminSistema;
  bool get isAdminModulo => role == UserRole.adminModulo;
  bool get isTecnicoCampo => role == UserRole.tecnicoCampo;
  bool get isProductor => role == UserRole.productor;
  /// True for roles that have module-based restrictions (adminModulo and tecnicoCampo).
  bool get hasModuleRestriction => role == UserRole.adminModulo || role == UserRole.tecnicoCampo;
  bool get canManageUsers => role == UserRole.adminSistema;
  bool get canManageModules => role == UserRole.adminSistema;
  /// Agregar, editar y dar de baja parcelas después del registro del
  /// productor (la base de datos aplica la misma regla).
  bool get canManagePlots =>
      role == UserRole.adminSistema || role == UserRole.adminModulo;
  /// Editar datos de productores (la base de datos aplica la misma regla).
  bool get canManageProducers =>
      role == UserRole.adminSistema || role == UserRole.adminModulo;
}
