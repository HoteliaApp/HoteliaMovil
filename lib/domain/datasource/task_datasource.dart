import '../entities/entities.dart';

/// Contrato abstracto para la fuente de datos de tareas y alertas del hotel.
abstract class TaskDataSource {
  /// Crea una nueva tarea de limpieza en Firestore tras un check-out.
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  });

  /// Crea una alerta manual desde el Dashboard hacia el wearable.
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  });

  /// Emite un stream de tareas activas (pendientes y en progreso).
  Stream<List<Task>> watchActiveTasks();

  /// Actualiza el estado de una tarea específica.
  Future<void> updateTaskStatus(String taskId, String status);

  /// Emite las tareas completadas más recientes, de la más nueva a la más
  /// antigua. Alimenta el cierre automático del ciclo tarea-habitación.
  ///
  /// La ventana es acotada a propósito: al abrir la app recupera lo que haya
  /// ocurrido mientras estuvo cerrada, sin descargar el historial completo.
  Stream<List<Task>> watchRecentlyCompletedTasks({int limit = 20});
}
