import 'package:hotel_app/domain/domain.dart';

/// Mapper para convertir entre datos crudos de Firestore y la entidad de dominio [Task].
class TaskMapper {
  TaskMapper._();

  /// Convierte un Map proveniente de Firestore en una entidad [Task].
  static Task fromFirestore(Map<String, dynamic> data, [String? docId]) {
    return Task(
      id: (data['id'] as String?)?.isNotEmpty == true
          ? data['id'] as String
          : docId ?? '',
      roomId: data['roomId'] as String? ?? '',
      roomNumber: (data['roomNumber'] as num?)?.toInt() ?? 0,
      taskType: data['taskType'] as String? ?? 'cleaning',
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String? ?? '',
      guestName: data['guestName'] as String? ?? '',
      assignedBy: data['assignedBy'] as String? ?? '',
      assignedByName: data['assignedByName'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? DateTime.tryParse(data['completedAt'] as String)
          : null,
      priority: (data['priority'] as num?)?.toInt() ?? 3,
    );
  }

  /// Convierte una entidad [Task] a un mapa para persistir en Firestore.
  static Map<String, dynamic> toFirestore(Task task) {
    return {
      'id': task.id,
      'roomId': task.roomId,
      'roomNumber': task.roomNumber,
      'taskType': task.taskType,
      'status': task.status,
      'description': task.description,
      'guestName': task.guestName,
      'assignedBy': task.assignedBy,
      if (task.assignedByName != null) 'assignedByName': task.assignedByName,
      'createdAt': task.createdAt.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
      'priority': task.priority,
    };
  }
}
