/// Estados posibles de una tarea
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get label => switch (this) {
        TaskStatus.pending => 'Pendiente',
        TaskStatus.inProgress => 'En progreso',
        TaskStatus.completed => 'Completada',
        TaskStatus.cancelled => 'Cancelada',
      };
}

/// Niveles de prioridad para una tarea
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
        TaskPriority.low => 'Baja',
        TaskPriority.medium => 'Media',
        TaskPriority.high => 'Alta',
        TaskPriority.urgent => 'Urgente',
      };
}

/// Entidad de dominio que representa una tarea del hotel.
class Task {
  static const int schemaVersion = 1;

  final String id;
  final String roomId;
  final int roomNumber;
  final String taskType;
  final String status;
  final String description;
  final String guestName;
  final String assignedBy;
  final String? assignedByName;

  /// UID del operario asignado. `null` significa sin asignar: la tarea es
  /// visible para todo el personal operativo.
  final String? assignedTo;

  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority;

  /// Observaciones capturadas por el operario desde el reloj al completar.
  final String? notes;

  const Task({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.taskType,
    required this.status,
    required this.description,
    required this.guestName,
    required this.assignedBy,
    this.assignedByName,
    this.assignedTo,
    required this.createdAt,
    this.completedAt,
    this.priority = 3,  
    this.notes,
  });

  /// Etiqueta legible del tipo de tarea (compatible con WearTaskType)
  String get taskTypeLabel => switch (taskType) {
        'cleaning' => 'Limpieza',
        'maintenance' => 'Mantenimiento',
        'inspection' => 'Inspección',
        'delivery' => 'Entrega',
        'guest_request' => 'Solicitud de huésped',
        _ => taskType,
      };

  /// Etiqueta legible del estado
  String get statusLabel => switch (status) {
        'pending' => 'Pendiente',
        'inProgress' => 'En progreso',
        'completed' => 'Completada',
        'cancelled' => 'Cancelada',
        _ => status,
      };

  /// Severidad derivada de [priority], según la tabla de correspondencia del
  /// contrato de datos. Es el valor que se escribe en el campo `severity` de
  /// la colección `/alerts`.
  String get severity => switch (priority) {
        5 => 'urgent',
        4 => 'high',
        3 => 'medium',
        _ => 'low',
      };

  /// Tiempo transcurrido desde que se creó la tarea
  Duration get elapsedTime => DateTime.now().difference(createdAt);

  /// Retorna true si la tarea está activa (pendiente o en progreso)
  bool get isActive => status == 'pending' || status == 'inProgress';

  /// Retorna true si la tarea es de alta prioridad
  bool get isHighPriority => priority >= 4;

  /// Retorna true si la tarea está asignada a un operario concreto.
  bool get isAssigned => assignedTo != null && assignedTo!.isNotEmpty;

  /// Crea una copia de la entidad con los campos modificados
  Task copyWith({
    String? id,
    String? roomId,
    int? roomNumber,
    String? taskType,
    String? status,
    String? description,
    String? guestName,
    String? assignedBy,
    String? assignedByName,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? completedAt,
    int? priority,
    String? notes,
  }) {
    return Task(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      description: description ?? this.description,
      guestName: guestName ?? this.guestName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedByName: assignedByName ?? this.assignedByName,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, roomNumber: $roomNumber, type: $taskTypeLabel, status: $statusLabel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Alias para mantener retrocompatibilidad con código existente
typedef HotelTask = Task;
