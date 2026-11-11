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
}
