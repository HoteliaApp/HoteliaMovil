import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/repositories/task_repository_impl.dart';

/// Mock manual de TaskDataSource para pruebas unitarias sin dependencias de Firestore.
class MockTaskDataSource implements TaskDataSource {
  final List<Task> mockTasks = [];
  String? lastUpdatedTaskId;
  String? lastUpdatedStatus;

  @override
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  }) async {
    final id = 'cleaning-task-$roomNumber';
    mockTasks.add(Task(
      id: id,
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: 'cleaning',
      status: 'pending',
      description: 'Limpieza post check-out — Hab. $roomNumber',
      guestName: guestName,
      assignedBy: 'user-test-123',
      createdAt: DateTime.now(),
      priority: 4,
    ));
    return id;
  }

  @override
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) async {
    final alertId = 'alert-$roomNumber';
    mockTasks.add(Task(
      id: alertId,
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: taskType,
      status: 'pending',
      description: description,
      guestName: guestName,
      assignedBy: 'user-test-123',
      createdAt: DateTime.now(),
      priority: 5,
    ));
    return alertId;
  }

  @override
  Stream<List<Task>> watchActiveTasks() {
    return Stream.value(mockTasks.where((t) => t.isActive).toList());
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {
    lastUpdatedTaskId = taskId;
    lastUpdatedStatus = status;
    final index = mockTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      mockTasks[index] = mockTasks[index].copyWith(status: status);
    }
  }
}

void main() {
  group('TaskRepositoryImpl Unit Tests con Mocks', () {
    late MockTaskDataSource mockDataSource;
    late TaskRepository repository;

    setUp(() {
      mockDataSource = MockTaskDataSource();
      repository = TaskRepositoryImpl(mockDataSource);
    });

    test('createCleaningTask delega al datasource y retorna el taskId generado', () async {
      final taskId = await repository.createCleaningTask(
        roomId: 'room-101',
        roomNumber: 101,
        guestName: 'Carlos Mendoza',
      );

      expect(taskId, equals('cleaning-task-101'));
      expect(mockDataSource.mockTasks.length, 1);
      final task = mockDataSource.mockTasks.first;
      expect(task.roomNumber, 101);
      expect(task.taskType, 'cleaning');
      expect(task.taskTypeLabel, 'Limpieza');
      expect(task.isActive, isTrue);
    });

    test('createManualAlert delega al datasource con prioridad alta', () async {
      final alertId = await repository.createManualAlert(
        roomId: 'room-202',
        roomNumber: 202,
        taskType: 'maintenance',
        description: 'Fuga de agua en el baño',
        guestName: 'Ana Gomez',
      );

      expect(alertId, equals('alert-202'));
      expect(mockDataSource.mockTasks.length, 1);
      final task = mockDataSource.mockTasks.first;
      expect(task.isHighPriority, isTrue);
      expect(task.taskTypeLabel, 'Mantenimiento');
    });

    test('watchActiveTasks emite solo tareas pendientes o en progreso', () async {
      await repository.createCleaningTask(
        roomId: 'r1',
        roomNumber: 101,
        guestName: 'Huésped 1',
      );
      await repository.createManualAlert(
        roomId: 'r2',
        roomNumber: 102,
        taskType: 'delivery',
        description: 'Toallas extra',
        guestName: 'Huésped 2',
      );

      final stream = repository.watchActiveTasks();
      final activeTasks = await stream.first;

      expect(activeTasks.length, 2);
      expect(activeTasks.every((t) => t.isActive), isTrue);
    });

    test('updateTaskStatus actualiza el estado de la tarea en el datasource', () async {
      final taskId = await repository.createCleaningTask(
        roomId: 'r1',
        roomNumber: 101,
        guestName: 'Huésped 1',
      );

      await repository.updateTaskStatus(taskId, 'completed');

      expect(mockDataSource.lastUpdatedTaskId, taskId);
      expect(mockDataSource.lastUpdatedStatus, 'completed');
      final updatedTask = mockDataSource.mockTasks.first;
      expect(updatedTask.status, 'completed');
      expect(updatedTask.statusLabel, 'Completada');
      expect(updatedTask.isActive, isFalse);
    });
  });
}
