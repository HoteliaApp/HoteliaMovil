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

  /// Emite las tareas completadas más recientes, de la más nueva a la más
  /// antigua. Alimenta el cierre automático del ciclo tarea-habitación.
  ///
  /// La ventana es acotada a propósito: al abrir la app recupera lo que haya
  /// ocurrido mientras estuvo cerrada, sin descargar el historial completo.
  Stream<List<Task>> watchRecentlyCompletedTasks({int limit = 20});
}
