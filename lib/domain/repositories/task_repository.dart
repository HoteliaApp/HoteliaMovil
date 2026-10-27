import '../entities/entities.dart';

/// Contrato abstracto del repositorio de tareas.
/// La capa de presentación y providers solo conocen esta interfaz.
abstract class TaskRepository {
  /// Crea una nueva tarea de limpieza tras un check-out.
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  });

  /// Crea una alerta manual hacia el wearable.
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  });

  /// Obtiene el flujo en tiempo real de tareas activas.
  Stream<List<Task>> watchActiveTasks();

  /// Modifica el estado de una tarea.
  Future<void> updateTaskStatus(String taskId, String status);
}
