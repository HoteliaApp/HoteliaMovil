import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/datasource/task_datasource_impl.dart';

/// Servicio heredado para compatibilidad.
/// Delega directamente a la nueva arquitectura limpia a través de [TaskDataSource].
@Deprecated('Usar TaskRepository o TaskDataSource inyectado por Riverpod')
class FirebaseTaskService {
  final TaskDataSource _dataSource;

  FirebaseTaskService({TaskDataSource? dataSource})
      : _dataSource = dataSource ?? TaskDataSourceImpl();

  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  }) =>
      _dataSource.createCleaningTask(
        roomId: roomId,
        roomNumber: roomNumber,
        guestName: guestName,
      );

  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) =>
      _dataSource.createManualAlert(
        roomId: roomId,
        roomNumber: roomNumber,
        taskType: taskType,
        description: description,
        guestName: guestName,
      );

  Stream<List<Task>> watchActiveTasks() => _dataSource.watchActiveTasks();

  Future<void> updateTaskStatus(String taskId, String status) =>
      _dataSource.updateTaskStatus(taskId, status);
}

/// Provider singleton heredado para retrocompatibilidad
@Deprecated('Usar taskRepositoryProvider')
final firebaseTaskServiceProvider = Provider<FirebaseTaskService>((ref) {
  return FirebaseTaskService();
});
