import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/mappers/reservation_mapper.dart';
import 'package:hotel_app/infrastructure/models/reservation/reservation_model.dart';

/// Implementación concreta de [ReservationsDataSource] usando Firebase Firestore.
class ReservationsDataSourceImpl implements ReservationsDataSource {
  final FirebaseFirestore _firestore;

  ReservationsDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _reservations =>
      _firestore.collection('reservations');

  @override
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _reservations;

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (guestId != null) {
        query = query.where('guestId', isEqualTo: guestId);
      }

      final snapshot = await query.get();
      final reservations = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReservationMapper.fromJson(data);
      }).toList();

      return reservations;
    } catch (e) {
      throw Exception('Error al obtener reservaciones de Firebase: $e');
    }
  }

  @override
  Future<Reservation> getReservationById(String id) async {
    try {
      final doc = await _reservations.doc(id).get();
      if (!doc.exists) throw Exception('Reservación no encontrada');
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return ReservationMapper.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener reservación: $e');
    }
  }

  @override
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final activeQuery = await _reservations
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['confirmed', 'checkedIn', 'newReservation'])
          .get();

      final newIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
      final newOut = DateTime(checkOut.year, checkOut.month, checkOut.day);

      for (final doc in activeQuery.docs) {
        final data = doc.data();
        final checkInRaw = data['checkIn'] ?? data['check_in'];
        final checkOutRaw = data['checkOut'] ?? data['check_out'];

        if (checkInRaw != null && checkOutRaw != null) {
          final existInRaw = checkInRaw is Timestamp
              ? checkInRaw.toDate()
              : DateTime.parse(checkInRaw.toString());
          final existOutRaw = checkOutRaw is Timestamp
              ? checkOutRaw.toDate()
              : DateTime.parse(checkOutRaw.toString());

          final existIn = DateTime(existInRaw.year, existInRaw.month, existInRaw.day);
          final existOut = DateTime(existOutRaw.year, existOutRaw.month, existOutRaw.day);

          // Fechas empalmadas: newIn < existOut && newOut > existIn
          if (newIn.isBefore(existOut) && newOut.isAfter(existIn)) {
            data['id'] = doc.id;
            return ReservationMapper.fromJson(data);
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Error al validar fechas de reservación: $e');
    }
  }

  @override
  Future<Reservation> createReservation(CreateReservationParams params) async {
    try {
      final newIn = DateTime(params.checkIn.year, params.checkIn.month, params.checkIn.day);
      final newOut = DateTime(params.checkOut.year, params.checkOut.month, params.checkOut.day);

      if (!newOut.isAfter(newIn)) {
        throw Exception('La fecha de check-out debe ser posterior a la fecha de check-in.');
      }

      // Validar contra la colección /reservations antes de escribir
      final conflict = await getOverlappingReservation(
        roomId: params.roomId,
        checkIn: params.checkIn,
        checkOut: params.checkOut,
      );

      if (conflict != null) {
        final inStr = '${conflict.checkIn.day.toString().padLeft(2, '0')}/${conflict.checkIn.month.toString().padLeft(2, '0')}';
        final outStr = '${conflict.checkOut.day.toString().padLeft(2, '0')}/${conflict.checkOut.month.toString().padLeft(2, '0')}';
        throw Exception('La habitación ya está reservada del $inStr al $outStr. Fechas empalmadas.');
      }

      final docRef = _reservations.doc();
      final reservation = ReservationModel(
        id: docRef.id,
        roomId: params.roomId,
        guestId: params.guestId,
        guestName: params.guestName,
        checkIn: params.checkIn,
        checkOut: params.checkOut,
        companions: 0, // Por defecto en la creación
        status: ReservationStatus.confirmed.name, // Confirmada directamente
        total: params.total,
        createdAt: DateTime.now(),
        notes: params.notes,
      );

      await docRef.set(reservation.toJson());
      return reservation.toEntity();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al crear reservación: $e');
    }
  }

  @override
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) async {
    try {
      await _reservations.doc(reservationId).update({
        'status': ReservationStatus.checkedIn.name,
        'guestName': guestName,
        'companions': companions,
        'checkOut': expectedCheckOut.toIso8601String(),
      });
      return await getReservationById(reservationId);
    } catch (e) {
      throw Exception('Error al realizar check-in: $e');
    }
  }

  @override
  Future<Reservation> checkOut(String reservationId) async {
    try {
      await _reservations.doc(reservationId).update({
        'status': ReservationStatus.completed.name,
      });
      return await getReservationById(reservationId);
    } catch (e) {
      throw Exception('Error al realizar check-out: $e');
    }
  }

  @override
  Future<Reservation> cancelReservation(String reservationId) async {
    try {
      await _reservations.doc(reservationId).update({
        'status': ReservationStatus.cancelled.name,
      });
      return await getReservationById(reservationId);
    } catch (e) {
      throw Exception('Error al cancelar reservación: $e');
    }
  }
}
