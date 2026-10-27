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
    // 1. Guardar en la colección 'tasks'
    final taskId = await _createTask(
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: taskType,
      description: description,
      guestName: guestName,
      priority: 5,
    );

    // 2. Guardar en la colección 'alerts' para wearable
    final alertId = 'alert-${DateTime.now().millisecondsSinceEpoch}';
    final message = 'Hab. $roomNumber: $description';
    final currentUserId = _firebaseAuth.currentUser?.uid ?? 'unknown_user';

    final taskTypeLabel = switch (taskType) {
      'cleaning' => 'Limpieza',
      'maintenance' => 'Mantenimiento',
      'inspection' => 'Inspección',
      'delivery' => 'Entrega',
      'guest_request' => 'Solicitud de huésped',
      _ => taskType,
    };

    await _alerts.doc(alertId).set({
      'id': alertId,
      'taskId': taskId,
      'title': '$taskTypeLabel — Hab. $roomNumber',
      'message': message,
      'severity': 'high',
      'roomId': roomId,
      'assignedBy': currentUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'isAcknowledged': false,
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
    final currentUserId = currentUser?.uid ?? 'unknown_user';

    final assignedByName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : currentUser?.email?.split('@').first ?? 'Recepción';

    await _tasks.doc(taskId).set({
      'id': taskId,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'taskType': taskType,
      'status': 'pending',
      'description': description,
      'guestName': guestName,
      'assignedBy': currentUserId,
      'assignedByName': assignedByName,
      'createdAt': DateTime.now().toIso8601String(),
      'completedAt': null,
      'priority': priority,
    });

    return taskId;
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
