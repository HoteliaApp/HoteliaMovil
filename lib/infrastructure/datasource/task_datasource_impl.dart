import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/mappers/task_mapper.dart';

/// Implementación concreta de [TaskDataSource] usando Firebase Firestore.
class TaskDataSourceImpl implements TaskDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  TaskDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _firestore.collection('alerts');

  // ── Etiquetas y severidad ──────────────────────────────────────────────────
 
  /// Etiqueta legible del tipo de tarea.
  static String _taskTypeLabel(String taskType) => switch (taskType) {
        'cleaning' => 'Limpieza',
        'maintenance' => 'Mantenimiento',
        'inspection' => 'Inspección',
        'delivery' => 'Entrega',
        'guest_request' => 'Solicitud de huésped',
        _ => taskType,
      };
 
  /// Severidad derivada de la prioridad, según la tabla de correspondencia
  /// del contrato de datos: 1-2 low, 3 medium, 4 high, 5 urgent.
  static String _severityFromPriority(int priority) => switch (priority) {
        5 => 'urgent',
        4 => 'high',
        3 => 'medium',
        _ => 'low',
      };

  @override
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

  @override
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) async {
    const priority = 5;
    // 1. Guardar en la colección 'tasks'
    final taskId = await _createTask(
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: taskType,
      description: description,
      guestName: guestName,
      priority: priority,
    );

    // 2. Guardar en la colección 'alerts' para wearable
    final alertId = 'alert-${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = _firebaseAuth.currentUser;
 
    await _alerts.doc(alertId).set({
      'id': alertId,
      'taskId': taskId,
      'title': '${_taskTypeLabel(taskType)} — Hab. $roomNumber',
      'message': 'Hab. $roomNumber: $description',
      'severity': _severityFromPriority(priority),
      'priority': priority,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'assignedBy': currentUser?.uid ?? 'unknown_user',
      'assignedByName': _displayNameOf(currentUser?.displayName, currentUser?.email),
      'createdAt': DateTime.now().toIso8601String(),
      'isAcknowledged': false,
      'acknowledgedAt': null,
      'schemaVersion': Task.schemaVersion,
    });


    return alertId;
  }

  Future<String> _createTask({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
    int priority = 3,
  }) async {
    final taskId = 'task-${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = _firebaseAuth.currentUser;
 
    final task = Task(
      id: taskId,
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: taskType,
      status: 'pending',
      description: description,
      guestName: guestName,
      assignedBy: currentUser?.uid ?? 'unknown_user',
      assignedByName: _displayNameOf(currentUser?.displayName, currentUser?.email),
      assignedTo: null,
      createdAt: DateTime.now(),
      completedAt: null,
      priority: priority,
      notes: null,
    );
 
    await _tasks.doc(taskId).set(TaskMapper.toFirestore(task));
 
    return taskId;

  }

  /// Nombre legible del usuario autenticado, para no obligar a las apps
  /// consumidoras a resolver el UID contra `/users`.
  static String _displayNameOf(String? displayName, String? email) {
  if (displayName?.isNotEmpty == true) return displayName!;
  final local = email?.split('@').first;
  return local?.isNotEmpty == true ? local! : 'Recepción';
}

  @override
  Stream<List<Task>> watchActiveTasks() {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskMapper.fromFirestore(doc.data(), doc.id))
          .where((t) => t.isActive)
          .toList();

      tasks.sort((a, b) {
        final priorityDiff = b.priority.compareTo(a.priority);
        if (priorityDiff != 0) return priorityDiff;
        return b.createdAt.compareTo(a.createdAt);
      });

      return tasks;
    });
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _tasks.doc(taskId).update({
      'status': status,
      if (status == 'completed')
        'completedAt': DateTime.now().toIso8601String(),
    });
  }
}
