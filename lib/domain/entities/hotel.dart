/// Entidad de dominio que representa a un inquilino (Hotel) en la arquitectura multi-tenant.
class Hotel {
  static const int currentSchemaVersion = 2;

  final String id;
  final String name;
  final int floors;
  final String address;
  final DateTime createdAt;
  final String plan; // 'basic' | 'standard' | 'premium'
  final int schemaVersion;
  final int? customMaxRooms;
  final int? customMaxUsers;
  final String? requestedPlan;
  final DateTime? planChangeRequestedAt;

  const Hotel({
    required this.id,
    required this.name,
    required this.floors,
    required this.address,
    required this.createdAt,
    this.plan = 'standard',
    this.schemaVersion = currentSchemaVersion,
    this.customMaxRooms,
    this.customMaxUsers,
    this.requestedPlan,
    this.planChangeRequestedAt,
  });

  /// Límites canónicos de habitaciones por plan
  static int defaultMaxRoomsForPlan(String planKey) {
    return switch (planKey.toLowerCase()) {
      'basic' => 20,
      'premium' => 150,
      _ => 50, // standard / intermedio
    };
  }

  /// Límites canónicos de usuarios por plan
  static int defaultMaxUsersForPlan(String planKey) {
    return switch (planKey.toLowerCase()) {
      'basic' => 5,
      'premium' => 50,
      _ => 15, // standard / intermedio
    };
  }

  /// Etiqueta legible del plan
  String get planLabel => switch (plan.toLowerCase()) {
        'basic' => 'Básico',
        'premium' => 'Premium',
        _ => 'Intermedio',
      };

  /// Límite efectivo de habitaciones contratadas
  int get maxRooms => customMaxRooms ?? defaultMaxRoomsForPlan(plan);

  /// Límite efectivo de usuarios contratados
  int get maxUsers => customMaxUsers ?? defaultMaxUsersForPlan(plan);

  /// Indica si hay una solicitud de cambio de plan pendiente
  bool get hasPendingPlanChange =>
      requestedPlan != null && requestedPlan!.trim().isNotEmpty;

  Hotel copyWith({
    String? id,
    String? name,
    int? floors,
    String? address,
    DateTime? createdAt,
    String? plan,
    int? schemaVersion,
    int? customMaxRooms,
    int? customMaxUsers,
    String? requestedPlan,
    DateTime? planChangeRequestedAt,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      floors: floors ?? this.floors,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      plan: plan ?? this.plan,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      customMaxRooms: customMaxRooms ?? this.customMaxRooms,
      customMaxUsers: customMaxUsers ?? this.customMaxUsers,
      requestedPlan: requestedPlan ?? this.requestedPlan,
      planChangeRequestedAt:
          planChangeRequestedAt ?? this.planChangeRequestedAt,
    );
  }

  @override
  String toString() =>
      'Hotel(id: $id, name: $name, plan: $plan, maxRooms: $maxRooms, maxUsers: $maxUsers)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Hotel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
