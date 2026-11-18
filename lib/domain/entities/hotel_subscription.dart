/// Entidad de dominio que representa la información de suscripción y uso del hotel.
class HotelSubscription {
  final String hotelId;
  final String plan; // 'basic', 'standard', 'premium'
  final int maxRooms;
  final int maxUsers;
  final int currentRooms;
  final int currentUsers;
  final String? requestedPlan;
  final DateTime? planChangeRequestedAt;

  const HotelSubscription({
    required this.hotelId,
    required this.plan,
    required this.maxRooms,
    required this.maxUsers,
    required this.currentRooms,
    required this.currentUsers,
    this.requestedPlan,
    this.planChangeRequestedAt,
  });

  /// Etiqueta en español del plan activo
  String get planLabel => switch (plan.toLowerCase()) {
        'basic' => 'Básico',
        'premium' => 'Premium',
        _ => 'Intermedio',
      };

  /// Etiqueta en español del plan solicitado (si hay cambio pendiente)
  String? get requestedPlanLabel {
    if (requestedPlan == null || requestedPlan!.trim().isEmpty) return null;
    return switch (requestedPlan!.toLowerCase()) {
      'basic' => 'Básico',
      'premium' => 'Premium',
      _ => 'Intermedio',
    };
  }

  /// Retorna true si el hotel ya alcanzó o superó el límite de habitaciones de su plan
  bool get isRoomsLimitReached => currentRooms >= maxRooms;

  /// Retorna true si el hotel ya alcanzó o superó el límite de usuarios de su plan
  bool get isUsersLimitReached => currentUsers >= maxUsers;

  /// Porcentaje de ocupación de habitaciones (0.0 a 1.0)
  double get roomsUsagePercentage =>
      maxRooms > 0 ? (currentRooms / maxRooms).clamp(0.0, 1.0) : 0.0;

  /// Porcentaje de ocupación de usuarios (0.0 a 1.0)
  double get usersUsagePercentage =>
      maxUsers > 0 ? (currentUsers / maxUsers).clamp(0.0, 1.0) : 0.0;

  /// Indica si hay una solicitud de cambio de plan pendiente
  bool get hasPendingPlanChange =>
      requestedPlan != null && requestedPlan!.trim().isNotEmpty;

  HotelSubscription copyWith({
    String? hotelId,
    String? plan,
    int? maxRooms,
    int? maxUsers,
    int? currentRooms,
    int? currentUsers,
    String? requestedPlan,
    DateTime? planChangeRequestedAt,
  }) {
    return HotelSubscription(
      hotelId: hotelId ?? this.hotelId,
      plan: plan ?? this.plan,
      maxRooms: maxRooms ?? this.maxRooms,
      maxUsers: maxUsers ?? this.maxUsers,
      currentRooms: currentRooms ?? this.currentRooms,
      currentUsers: currentUsers ?? this.currentUsers,
      requestedPlan: requestedPlan ?? this.requestedPlan,
      planChangeRequestedAt:
          planChangeRequestedAt ?? this.planChangeRequestedAt,
    );
  }

  @override
  String toString() =>
      'HotelSubscription(hotelId: $hotelId, plan: $planLabel, rooms: $currentRooms/$maxRooms, users: $currentUsers/$maxUsers)';
}
