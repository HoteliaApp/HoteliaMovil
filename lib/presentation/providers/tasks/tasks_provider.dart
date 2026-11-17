import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/infraestructure.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/infrastructure/services/task_room_sync_service.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';

// ─────────────────────────── Inyección de dependencias ────────────────────────

/// Provider del datasource de tareas
final taskDataSourceProvider = Provider<TaskDataSource>((ref) {
  final hotelId = ref.watch(currentHotelIdProvider);
  return TaskDataSourceImpl(hotelId: hotelId);
});

/// Provider del repositorio de tareas
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dataSource = ref.watch(taskDataSourceProvider);
  return TaskRepositoryImpl(dataSource);
});

// ─────────────────────────── Providers de tareas activas ─────────────────────

/// Stream de tareas activas desde el repositorio (pendientes + en progreso).
/// Se actualiza automáticamente cuando el wearable cambia el estado.
final activeTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchActiveTasks();
});

/// Número de tareas activas — útil para badges en navegación.
final activeTaskCountProvider = Provider<int>((ref) {
  return ref.watch(activeTasksProvider).when(
        data: (tasks) => tasks.length,
        loading: () => 0,
        error: (e, st) => 0,
      );
});

/// Tareas activas solo pendientes (aún no aceptadas por el wearable).
final pendingTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(activeTasksProvider).when(
        data: (tasks) => tasks.where((t) => t.status == 'pending').toList(),
        loading: () => [],
        error: (e, st) => [],
      );
});

/// Tareas activas en progreso (aceptadas y siendo trabajadas en el wearable).
final inProgressTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(activeTasksProvider).when(
        data: (tasks) => tasks.where((t) => t.status == 'inProgress').toList(),
        loading: () => [],
        error: (e, st) => [],
      );
});

// Servicio que cierra el ciclo tarea-habitación.
///
/// Se mantiene activo mientras haya una sesión iniciada. Al cerrar sesión el
/// provider se reconstruye, lo que cancela la suscripción anterior.
final taskRoomSyncServiceProvider = Provider<TaskRoomSyncService>((ref) {
  final isAuthenticated =
      ref.watch(authProvider.select((s) => s.isAuthenticated));

  final service = TaskRoomSyncService(
    taskRepository: ref.watch(taskRepositoryProvider),
    roomsRepository: ref.watch(roomsRepositoryProvider),
  );

  if (isAuthenticated) {
    service.start();
  }

  ref.onDispose(service.stop);

  return service;
});
