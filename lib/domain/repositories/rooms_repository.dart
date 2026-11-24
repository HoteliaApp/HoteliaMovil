import '../entities/entities.dart';

/// Contrato abstracto del repositorio de habitaciones.
/// La capa de presentación solo conoce esta interfaz, nunca la implementación concreta.
abstract class RoomsRepository {
  /// Obtiene la lista de habitaciones con filtros opcionales.
  /// El repositorio decide si consulta la red o el cache local.
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type});

  /// Obtiene el detalle de una habitación por su [id].
  Future<Room> getRoomById(String id);

  /// Actualiza el estado de una habitación.
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus);

  /// Emite en tiempo real la lista de habitaciones cada vez que Firestore
  /// notifica un cambio. Puede recibir filtros opcionales de [status] y [type].
  Stream<List<Room>> watchRooms({RoomStatus? status, RoomType? type});

  /// Marca la habitación como limpia **solo si** sigue pendiente de limpieza
  /// o en limpieza. Se resuelve en una transacción de Firestore, por lo que es
  /// seguro ante escrituras concurrentes desde varios dispositivos.
  ///
  /// Devuelve `true` si la transacción efectuó el cambio, `false` si la
  /// habitación ya estaba en otro estado y no se tocó.
  Future<bool> markRoomCleanedIfPending(String roomId);

  /// Da de alta una nueva habitación para este hotel.
  Future<void> createRoom(Room room);

  /// Emite los contadores agregados de habitaciones del hotel actual.
  /// Lee un único documento en lugar de la colección completa.
  Stream<RoomMetrics> watchRoomMetrics();

  /// Reconstruye el documento agregado recontando `/rooms`.
  /// Operación costosa: alta inicial de un hotel o reparación de una desviación.
  Future<RoomMetrics> recalculateRoomMetrics();
}
