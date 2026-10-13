import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────── Modelo ──────────────────────────────────────────

/// Modelo de tarea para la app móvil — comparte esquema con WearTaskModel
class HotelTask {
  final String id;
  final String roomId;
  final int roomNumber;
  final String taskType;
  final String status;
  final String description;
  final String guestName;
  final String assignedBy;
  final DateTime createdAt;
  final int priority;

  const HotelTask({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.taskType,
    required this.status,
    required this.description,
    required this.guestName,
    required this.assignedBy,
    required this.createdAt,
    required this.priority,
  });

  factory HotelTask.fromFirestore(Map<String, dynamic> data) {
    return HotelTask(
      id: data['id'] as String? ?? '',
      roomId: data['roomId'] as String? ?? '',
      roomNumber: (data['roomNumber'] as num?)?.toInt() ?? 0,
      taskType: data['taskType'] as String? ?? 'cleaning',
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String? ?? '',
      guestName: data['guestName'] as String? ?? '',
      assignedBy: data['assignedBy'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      priority: (data['priority'] as num?)?.toInt() ?? 3,
    );
  }

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
}

// ─────────────────────────── Servicio ────────────────────────────────────────

/// Servicio Firebase para publicar y monitorear tareas del wearable.
/// 
/// La colección `tasks` en Firestore es el canal compartido entre la app móvil
/// (crea tareas tras check-out) y la app wearable (las recibe y completa).
/// 
/// Esquema del documento:
/// ```json
/// {
///   "id": "task-xxx",
///   "roomId": "2",
///   "roomNumber": 201,
///   "taskType": "cleaning",
///   "status": "pending",
///   "description": "Limpieza post check-out...",
///   "guestName": "Carlos Mendoza",
///   "createdAt": "2026-08-05T...",
///   "completedAt": null,
///   "priority": 4
/// }
/// ```
class FirebaseTaskService {
  final FirebaseFirestore _firestore;

  FirebaseTaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Crear ──────────────────────────────────────────────────────────────────

  /// Crea una nueva tarea de limpieza en Firestore tras un check-out.
  /// Retorna el ID de la tarea creada.
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  }) async {
    return _createTask(
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: 'cleaning',
      description:
          'Limpieza post check-out — Hab. $roomNumber. Huésped: $guestName',
      guestName: guestName,
      priority: 4,
    );
  }

  /// Método genérico para crear cualquier tipo de tarea.
  Future<String> _createTask({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
    int priority = 3,
  }) async {
    final taskId = 'task-${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? 'unknown_user';

    // Nombre legible: displayName → parte del email → UID truncado
    final assignedByName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : currentUser?.email?.split('@').first ?? 'Recepción';

    await _firestore.collection('tasks').doc(taskId).set({
      'id': taskId,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'taskType': taskType,
      'status': 'pending',
      'description': description,
      'guestName': guestName,
      'assignedBy': currentUserId,
      'assignedByName': assignedByName, // ← nombre legible para la Smart TV
      'createdAt': DateTime.now().toIso8601String(),
      'completedAt': null,
      'priority': priority,
    });
    return taskId;
  }

  /// Crea una alerta manual desde el Dashboard hacia el wearable.
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) async {
    // 1. Guardamos en la colección 'tasks' para que el Dashboard la siga mostrando en "Tareas Activas"
    final taskId = await _createTask(
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: taskType,
      description: description,
      guestName: guestName,
      priority: 5,
    );

    // 2. Guardamos en la colección 'alerts' para que el Wearable (reloj) la lea en su nueva estructura
    final alertId = 'alert-${DateTime.now().millisecondsSinceEpoch}';
    final message = 'Hab. $roomNumber: $description';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

    // Construir un título legible según el tipo de tarea
    final taskTypeLabel = switch (taskType) {
      'cleaning' => 'Limpieza',
      'maintenance' => 'Mantenimiento',
      'inspection' => 'Inspección',
      'delivery' => 'Entrega',
      'guest_request' => 'Solicitud de huésped',
      _ => taskType,
    };

    await _firestore.collection('alerts').doc(alertId).set({
      'id': alertId,
      'taskId': taskId, // Referencia opcional a la tarea original
      'title': '$taskTypeLabel — Hab. $roomNumber', // ← campo usado por hotel-smart-app
      'message': message,
      'severity': 'high',
      'roomId': roomId,
      'assignedBy': currentUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'isAcknowledged': false,
    });

    return alertId;
  }

  // ── Leer (Stream) ──────────────────────────────────────────────────────────

  /// Stream de tareas activas (pendientes + en progreso), ordenadas por prioridad.
  /// Se actualiza en tiempo real cuando el wearable cambia el estado de una tarea.
  Stream<List<HotelTask>> watchActiveTasks() {
    return _firestore.collection('tasks').snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => HotelTask.fromFirestore(doc.data()))
          .where((t) => t.isActive)
          .toList();
      // Ordenar: mayor prioridad primero, luego más recientes
      tasks.sort((a, b) {
        final priorityDiff = b.priority.compareTo(a.priority);
        if (priorityDiff != 0) return priorityDiff;
        return b.createdAt.compareTo(a.createdAt);
      });
      return tasks;
    });
  }

  // ── Actualizar ─────────────────────────────────────────────────────────────

  /// Actualiza el estado de una tarea (usado para cancelar desde el móvil).
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': status,
      if (status == 'completed')
        'completedAt': DateTime.now().toIso8601String(),
    });
  }
}

// ─────────────────────────── Provider ────────────────────────────────────────

/// Provider singleton del servicio Firebase de tareas
final firebaseTaskServiceProvider = Provider<FirebaseTaskService>((ref) {
  return FirebaseTaskService();
});
