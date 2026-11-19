enum AuditActionType {
  cancellation,
  checkIn,
  checkOut,
  roleChange,
  subscription,
  hotel,
  other;

  String get label => switch (this) {
        AuditActionType.cancellation => 'Cancelación',
        AuditActionType.checkIn => 'Check-in',
        AuditActionType.checkOut => 'Check-out',
        AuditActionType.roleChange => 'Cambio de Rol',
        AuditActionType.subscription => 'Suscripción',
        AuditActionType.hotel => 'Hotel',
        AuditActionType.other => 'Operación',
      };
}

class AuditLog {
  final String id;
  final String action;
  final String description;
  final String performedBy;
  final String? performedByName;
  final String? reason;
  final String targetId;
  final DateTime timestamp;
  final String hotelId;

  const AuditLog({
    required this.id,
    required this.action,
    required this.description,
    required this.performedBy,
    this.performedByName,
    this.reason,
    required this.targetId,
    required this.timestamp,
    this.hotelId = 'hotel_101',
  });

  /// Clasificación de la acción para filtrado y presentación visual
  AuditActionType get actionType {
    final act = action.toUpperCase();
    if (act.contains('CANCEL')) return AuditActionType.cancellation;
    if (act.contains('CHECK_IN') || act == 'CHECKIN') return AuditActionType.checkIn;
    if (act.contains('CHECK_OUT') || act == 'CHECKOUT') return AuditActionType.checkOut;
    if (act.contains('EMPLOYEE') || act.contains('ROLE')) return AuditActionType.roleChange;
    if (act.contains('PLAN') || act.contains('SUBSCRIPTION')) return AuditActionType.subscription;
    if (act.contains('HOTEL')) return AuditActionType.hotel;
    return AuditActionType.other;
  }

  /// Retorna el nombre visible del operador o en su defecto el correo / identificador
  String get operatorDisplayName {
    if (performedByName != null && performedByName!.trim().isNotEmpty) {
      return performedByName!.trim();
    }
    if (performedBy.trim().isNotEmpty) {
      return performedBy.trim();
    }
    return 'Sistema';
  }

  /// Indica si la acción es crítica y requiere especial atención visual
  bool get isCritical => actionType == AuditActionType.cancellation || actionType == AuditActionType.roleChange;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'performedBy': performedBy,
      if (performedByName != null) 'performedByName': performedByName,
      if (reason != null) 'reason': reason,
      'targetId': targetId,
      'timestamp': timestamp,
      'hotelId': hotelId,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedTimestamp;
    final rawTs = map['timestamp'];
    if (rawTs == null) {
      parsedTimestamp = DateTime.now();
    } else if (rawTs is DateTime) {
      parsedTimestamp = rawTs;
    } else if (rawTs is String) {
      parsedTimestamp = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      // Dynamic fallback for cloud_firestore Timestamp without direct coupling to firestore
      try {
        parsedTimestamp = (rawTs as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedTimestamp = DateTime.now();
      }
    }

    return AuditLog(
      id: id.isNotEmpty ? id : (map['id'] as String? ?? ''),
      action: map['action'] as String? ?? 'OPERACION',
      description: map['description'] as String? ?? '',
      performedBy: map['performedBy'] as String? ?? '',
      performedByName: map['performedByName'] as String?,
      reason: map['reason'] as String?,
      targetId: map['targetId'] as String? ?? '',
      timestamp: parsedTimestamp,
      hotelId: map['hotelId'] as String? ?? 'hotel_101',
    );
  }

  AuditLog copyWith({
    String? id,
    String? action,
    String? description,
    String? performedBy,
    String? performedByName,
    String? reason,
    String? targetId,
    DateTime? timestamp,
    String? hotelId,
  }) {
    return AuditLog(
      id: id ?? this.id,
      action: action ?? this.action,
      description: description ?? this.description,
      performedBy: performedBy ?? this.performedBy,
      performedByName: performedByName ?? this.performedByName,
      reason: reason ?? this.reason,
      targetId: targetId ?? this.targetId,
      timestamp: timestamp ?? this.timestamp,
      hotelId: hotelId ?? this.hotelId,
    );
  }
}
