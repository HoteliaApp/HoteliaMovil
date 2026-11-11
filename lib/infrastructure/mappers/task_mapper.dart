import 'package:cloud_firestore/cloud_firestore.dart';
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
      assignedTo: data['assignedTo'] as String?,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      completedAt: _parseDate(data['completedAt']),
      priority: _parseInt(data['priority'], fallback: 3),
      notes: data['notes'] as String?,
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
      'assignedTo': task.assignedTo,
      'priority': task.priority,
      'createdAt': task.createdAt.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
      'notes': task.notes,
      'schemaVersion': Task.schemaVersion,
    };
  }

  // ── Helpers de parseo tolerante ────────────────────────────────────────────
 
  /// Acepta texto ISO 8601, `Timestamp` de Firestore o `null`.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
 
  /// Acepta `int`, `double` o texto numérico. Protege contra documentos
  /// antiguos en los que `roomNumber` se guardó como cadena.
  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
