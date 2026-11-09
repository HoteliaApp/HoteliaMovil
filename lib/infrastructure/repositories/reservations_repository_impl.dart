import 'package:hotel_app/domain/domain.dart';

/// Implementación concreta de [ReservationsRepository].
/// Delega las operaciones al [ReservationsDataSource] (API remota).
class ReservationsRepositoryImpl implements ReservationsRepository {
  final ReservationsDataSource _dataSource;

  const ReservationsRepositoryImpl(this._dataSource);

  @override
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  }) {
    return _dataSource.getReservations(status: status, guestId: guestId);
  }

  @override
  Future<Reservation> getReservationById(String id) {
    return _dataSource.getReservationById(id);
  }

  @override
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return _dataSource.getOverlappingReservation(
      roomId: roomId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  @override
  Future<Reservation> createReservation(CreateReservationParams params) {
    return _dataSource.createReservation(params);
  }

  @override
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) {
    return _dataSource.checkIn(
      reservationId: reservationId,
      guestName: guestName,
      companions: companions,
      expectedCheckOut: expectedCheckOut,
    );
  }

  @override
  Future<Reservation> checkOut(String reservationId) {
    return _dataSource.checkOut(reservationId);
  }

  @override
  Future<Reservation> cancelReservation(String reservationId) {
    return _dataSource.cancelReservation(reservationId);
  }
}
