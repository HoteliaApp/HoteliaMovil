import '../datasource/datasource.dart';
import '../entities/entities.dart';

/// Contrato abstracto del repositorio de reservaciones.
/// La capa de presentación solo conoce esta interfaz, nunca la implementación concreta.
abstract class ReservationsRepository {
  /// Obtiene la lista de reservaciones con filtros opcionales.
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  });

  /// Obtiene el detalle de una reservación por su [id].
  Future<Reservation> getReservationById(String id);

  /// Verifica si una habitación tiene alguna reservación activa empalmada con las fechas dadas.
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Crea una nueva reservación.
  Future<Reservation> createReservation(CreateReservationParams params);

  /// Realiza el check-in de una reservación.
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  });

  /// Realiza el check-out de una reservación.
  Future<Reservation> checkOut(String reservationId);

  /// Cancela una reservación.
  Future<Reservation> cancelReservation(String reservationId);
}
