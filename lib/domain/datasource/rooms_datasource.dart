import '../entities/entities.dart';

/// Contrato abstracto para la fuente de datos de habitaciones.
/// Tanto el datasource remoto (API) como el local (Hive) deben implementar esta interfaz.
abstract class RoomsDataSource {
  /// Obtiene la lista completa de habitaciones.
  /// Puede recibir filtros opcionales de [status] y [type].
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type});

  /// Obtiene el detalle de una habitación por su [id].
  /// Lanza excepción si no se encuentra.
  Future<Room> getRoomById(String id);

  /// Actualiza el estado de una habitación.
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus);

  /// Emite la lista de habitaciones en tiempo real cada vez que Firestore
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
