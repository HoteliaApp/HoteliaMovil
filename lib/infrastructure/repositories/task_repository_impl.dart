import 'package:hotel_app/domain/domain.dart';

/// Implementación concreta de [TaskRepository].
/// Delega las operaciones al [TaskDataSource].
class TaskRepositoryImpl implements TaskRepository {
  final TaskDataSource _dataSource;

  const TaskRepositoryImpl(this._dataSource);

  @override
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  }) {
    return _dataSource.createCleaningTask(
      roomId: roomId,
      roomNumber: roomNumber,
      guestName: guestName,
    );
  }

  @override
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) {
    return _dataSource.createManualAlert(
      roomId: roomId,
      roomNumber: roomNumber,
      taskType: taskType,
      description: description,
      guestName: guestName,
    );
  }

  @override
  Stream<List<Task>> watchActiveTasks() {
    return _dataSource.watchActiveTasks();
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) {
    return _dataSource.updateTaskStatus(taskId, status);
  }
}
