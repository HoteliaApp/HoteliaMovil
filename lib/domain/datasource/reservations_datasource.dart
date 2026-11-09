import 'package:hotel_app/domain/entities/entities.dart';

/// Parámetros para crear una nueva reservación
class CreateReservationParams {
  final String roomId;
  final String guestId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final double total;
  final String? notes;

  const CreateReservationParams({
    required this.roomId,
    required this.guestId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    this.total = 0.0,
    this.notes,
  });
}

/// Contrato abstracto para la fuente de datos de reservaciones.
/// Tanto el datasource remoto (API) como el local (Hive) deben implementar esta interfaz.
abstract class ReservationsDataSource {
  /// Obtiene la lista de reservaciones.
  /// Puede filtrar por [status] o por [guestId].
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  });

  /// Obtiene el detalle de una reservación por su [id].
  Future<Reservation> getReservationById(String id);

  /// Verifica si una habitación tiene alguna reservación activa empalmada con las fechas dadas.
  /// Retorna la primera [Reservation] que genera conflicto, o null si no hay empalme.
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Crea una nueva reservación con los [params] proporcionados.
  Future<Reservation> createReservation(CreateReservationParams params);

  /// Realiza el check-in de una reservación existente.
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  });

  /// Realiza el check-out de una reservación existente.
  Future<Reservation> checkOut(String reservationId);

  /// Cancela una reservación existente.
  Future<Reservation> cancelReservation(String reservationId);
}
