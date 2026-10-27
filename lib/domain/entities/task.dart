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
  final String id;
  final String roomId;
  final int roomNumber;
  final String taskType;
  final String status;
  final String description;
  final String guestName;
  final String assignedBy;
  final String? assignedByName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority;

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
    required this.createdAt,
    this.completedAt,
    this.priority = 3,
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

  /// Tiempo transcurrido desde que se creó la tarea
  Duration get elapsedTime => DateTime.now().difference(createdAt);

  /// Retorna true si la tarea está activa (pendiente o en progreso)
  bool get isActive => status == 'pending' || status == 'inProgress';

  /// Retorna true si la tarea es de alta prioridad
  bool get isHighPriority => priority >= 4;

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
    DateTime? createdAt,
    DateTime? completedAt,
    int? priority,
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
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
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
