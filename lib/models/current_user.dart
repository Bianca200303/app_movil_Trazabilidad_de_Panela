enum UserRole {
  adminSistema,
  adminModulo,
  productor;

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin_sistema':
        return UserRole.adminSistema;
      case 'admin_modulo':
        return UserRole.adminModulo;
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

  const CurrentUser({
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdminSistema => role == UserRole.adminSistema;
  bool get isAdminModulo => role == UserRole.adminModulo;
  bool get isProductor => role == UserRole.productor;
  bool get canManageUsers => role == UserRole.adminSistema;
  bool get canManageModules => role == UserRole.adminSistema;
}
