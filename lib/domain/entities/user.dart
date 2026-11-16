/// Estados posibles de una cuenta de usuario
enum UserStatus {
  pending,
  active,
  rejected,
  inactive;

  String get label => switch (this) {
        UserStatus.pending => 'Pendiente',
        UserStatus.active => 'Activo',
        UserStatus.rejected => 'Rechazado',
        UserStatus.inactive => 'Inactivo',
      };
}

/// Roles de usuario disponibles en el sistema del hotel
enum UserRole {
  unassigned,
  admin,
  receptionist,
  housekeeper,
  maintenance;

  String get label => switch (this) {
        UserRole.unassigned => 'Sin asignar',
        UserRole.admin => 'Administrador',
        UserRole.receptionist => 'Recepcionista',
        UserRole.housekeeper => 'Ama de llaves',
        UserRole.maintenance => 'Mantenimiento',
      };
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final String? avatarUrl;
  final DateTime createdAt;
  final String hotelId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = UserStatus.pending,
    this.avatarUrl,
    required this.createdAt,
    this.hotelId = 'hotel_101',
  });

  /// Retorna true si el usuario es administrador
  bool get isAdmin => role == UserRole.admin;

  /// Retorna true si el usuario es recepcionista
  bool get isReceptionist => role == UserRole.receptionist;

  /// Retorna true si el usuario tiene rol asignado (no es unassigned)
  bool get hasRole => role != UserRole.unassigned;

  /// Crea una copia de la entidad con los campos modificados
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    UserStatus? status,
    String? avatarUrl,
    DateTime? createdAt,
    String? hotelId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      hotelId: hotelId ?? this.hotelId,
    );
  }

  @override
  String toString() =>
      'User(id: $id, name: $name, hotelId: $hotelId, role: ${role.label}, status: ${status.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && other.id == id;

  @override
  int get hashCode => id.hashCode;
}