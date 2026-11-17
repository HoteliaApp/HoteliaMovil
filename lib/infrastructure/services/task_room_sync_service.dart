import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hotel_app/domain/domain.dart';

/// Cierra automáticamente el ciclo operativo de Hotelia.
///
/// Observa las tareas de limpieza que el wearable marca como completadas y
/// devuelve la habitación asociada al estado `cleaned`, sin intervención
/// manual de recepción.
class TaskRoomSyncService {
  final TaskRepository _taskRepository;
  final RoomsRepository _roomsRepository;

  StreamSubscription<List<Task>>? _subscription;

  /// Tareas ya atendidas en esta sesión, para no reprocesar en cada emisión
  /// del stream. La corrección no depende de este conjunto —la transacción ya
  /// es idempotente— pero evita escrituras y lecturas innecesarias.
  final Set<String> _handled = <String>{};

  TaskRoomSyncService({
    required TaskRepository taskRepository,
    required RoomsRepository roomsRepository,
  })  : _taskRepository = taskRepository,
        _roomsRepository = roomsRepository;

  bool get isRunning => _subscription != null;

  /// Comienza a observar las tareas completadas.
  void start() {
    if (_subscription != null) return;

    _subscription = _taskRepository.watchRecentlyCompletedTasks().listen(
      _onCompletedTasks,
      onError: (Object error) {
        debugPrint('[TaskRoomSync] Error en el stream de tareas: $error');
      },
    );

    debugPrint('[TaskRoomSync] Servicio iniciado');
  }

  /// Detiene la observación y limpia el estado de la sesión.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _handled.clear();
    debugPrint('[TaskRoomSync] Servicio detenido');
  }

  Future<void> _onCompletedTasks(List<Task> tasks) async {
    for (final task in tasks) {
      if (task.taskType != 'cleaning') continue;
      if (task.roomId.isEmpty) continue;
      if (_handled.contains(task.id)) continue;

      _handled.add(task.id);

      try {
        final changed =
            await _roomsRepository.markRoomCleanedIfPending(task.roomId);

        if (changed) {
          debugPrint(
            '[TaskRoomSync] Hab. ${task.roomNumber} → limpia '
            '(tarea ${task.id})',
          );
        }
      } catch (e) {
        // Se reintentará en la siguiente emisión del stream.
        _handled.remove(task.id);
        debugPrint(
          '[TaskRoomSync] No se pudo cerrar el ciclo de la tarea '
          '${task.id}: $e',
        );
      }
    }
  }
}