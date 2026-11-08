import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/repositories/reservations_repository_impl.dart';

/// Mock manual de ReservationsDataSource para pruebas unitarias sin conexión a Firestore.
class MockReservationsDataSource implements ReservationsDataSource {
  final List<Reservation> mockReservations = [];

  @override
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  }) async {
    return mockReservations.where((r) {
      if (status != null && r.status != status) return false;
      if (guestId != null && r.guestId != guestId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Reservation> getReservationById(String id) async {
    return mockReservations.firstWhere((r) => r.id == id);
  }

  @override
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final newIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final newOut = DateTime(checkOut.year, checkOut.month, checkOut.day);

    for (final r in mockReservations) {
      if (r.roomId == roomId &&
          r.status != ReservationStatus.cancelled &&
          r.status != ReservationStatus.completed) {
        final existIn = DateTime(r.checkIn.year, r.checkIn.month, r.checkIn.day);
        final existOut = DateTime(r.checkOut.year, r.checkOut.month, r.checkOut.day);

        // Empalme: newIn < existOut && newOut > existIn
        if (newIn.isBefore(existOut) && newOut.isAfter(existIn)) {
          return r;
        }
      }
    }
    return null;
  }

  @override
  Future<Reservation> createReservation(CreateReservationParams params) async {
    final newIn = DateTime(params.checkIn.year, params.checkIn.month, params.checkIn.day);
    final newOut = DateTime(params.checkOut.year, params.checkOut.month, params.checkOut.day);

    if (!newOut.isAfter(newIn)) {
      throw Exception('La fecha de check-out debe ser posterior a la fecha de check-in.');
    }

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

    final newReservation = Reservation(
      id: 'res-${mockReservations.length + 1}',
      roomId: params.roomId,
      guestId: params.guestId,
      guestName: params.guestName,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      companions: 0,
      status: ReservationStatus.confirmed,
      total: params.total,
      createdAt: DateTime.now(),
      notes: params.notes,
    );

    mockReservations.add(newReservation);
    return newReservation;
  }

  @override
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) async {
    final index = mockReservations.indexWhere((r) => r.id == reservationId);
    final updated = mockReservations[index].copyWith(
      status: ReservationStatus.checkedIn,
      guestName: guestName,
      companions: companions,
      checkOut: expectedCheckOut,
    );
    mockReservations[index] = updated;
    return updated;
  }

  @override
  Future<Reservation> checkOut(String reservationId) async {
    final index = mockReservations.indexWhere((r) => r.id == reservationId);
    final updated = mockReservations[index].copyWith(
      status: ReservationStatus.completed,
    );
    mockReservations[index] = updated;
    return updated;
  }

  @override
  Future<Reservation> cancelReservation(String reservationId) async {
    final index = mockReservations.indexWhere((r) => r.id == reservationId);
    final updated = mockReservations[index].copyWith(
      status: ReservationStatus.cancelled,
    );
    mockReservations[index] = updated;
    return updated;
  }
}

void main() {
  group('Issue H-17 - ReservationsRepository Unit Tests', () {
    late MockReservationsDataSource mockDataSource;
    late ReservationsRepository repository;

    setUp(() {
      mockDataSource = MockReservationsDataSource();
      repository = ReservationsRepositoryImpl(mockDataSource);

      // Dado que la habitación 101 ya está reservada del 20 al 25 de octubre
      mockDataSource.mockReservations.add(
        Reservation(
          id: 'res-101-oct',
          roomId: 'room-101',
          guestId: 'guest-1',
          guestName: 'Carlos Gómez',
          checkIn: DateTime(2026, 10, 20),
          checkOut: DateTime(2026, 10, 25),
          companions: 1,
          status: ReservationStatus.confirmed,
          total: 250.0,
          createdAt: DateTime(2026, 10, 1),
        ),
      );
    });

    group('Criterio de Aceptación - Escenario 1: Fechas empalmadas', () {
      test(
          'Dado que la habitación 101 ya está reservada del 20 al 25 de octubre, '
          'cuando se intenta registrar una nueva reserva para la habitación 101 del 22 al 24 de octubre, '
          'entonces el sistema detecta el empalme y bloquea el guardado arrojando excepción',
          () async {
        // Cuando se consulta si hay empalme
        final conflict = await repository.getOverlappingReservation(
          roomId: 'room-101',
          checkIn: DateTime(2026, 10, 22),
          checkOut: DateTime(2026, 10, 24),
        );

        // Entonces se detecta la reservación existente
        expect(conflict, isNotNull);
        expect(conflict!.id, 'res-101-oct');
        expect(conflict.roomId, 'room-101');

        // Y al intentar crear la reservación, se bloquea el guardado
        expect(
          () => repository.createReservation(
            CreateReservationParams(
              roomId: 'room-101',
              guestId: 'guest-2',
              guestName: 'Ana Ruiz',
              checkIn: DateTime(2026, 10, 22),
              checkOut: DateTime(2026, 10, 24),
              total: 100.0,
            ),
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('Fechas empalmadas'),
          )),
        );
      });

      test('Permite reservar en fechas no empalmadas para la misma habitación (ej. 25 al 30 de octubre)', () async {
        final conflict = await repository.getOverlappingReservation(
          roomId: 'room-101',
          checkIn: DateTime(2026, 10, 25),
          checkOut: DateTime(2026, 10, 30),
        );

        expect(conflict, isNull);

        final newRes = await repository.createReservation(
          CreateReservationParams(
            roomId: 'room-101',
            guestId: 'guest-3',
            guestName: 'Luis Morales',
            checkIn: DateTime(2026, 10, 25),
            checkOut: DateTime(2026, 10, 30),
            total: 250.0,
          ),
        );

        expect(newRes.id, isNotNull);
        expect(mockDataSource.mockReservations.length, 2);
      });

      test('Permite reservar las mismas fechas en una habitación diferente (ej. room-102)', () async {
        final conflict = await repository.getOverlappingReservation(
          roomId: 'room-102',
          checkIn: DateTime(2026, 10, 22),
          checkOut: DateTime(2026, 10, 24),
        );

        expect(conflict, isNull);
      });

      test('Ignora reservaciones canceladas en la validación de empalme', () async {
        // Cancelamos la reservación de la habitación 101
        await repository.cancelReservation('res-101-oct');

        final conflict = await repository.getOverlappingReservation(
          roomId: 'room-101',
          checkIn: DateTime(2026, 10, 22),
          checkOut: DateTime(2026, 10, 24),
        );

        expect(conflict, isNull);
      });
    });

    group('Criterio de Aceptación - Escenario 2: Cálculo dinámico de costo', () {
      test(
          'Dado que se seleccionan 3 noches en una habitación de \$80/noche, '
          'cuando se eligen las fechas, '
          'entonces el cálculo estimado es de \$240.00', () {
        const double pricePerNight = 80.0;
        final checkIn = DateTime(2026, 11, 1);
        final checkOut = DateTime(2026, 11, 4);

        final nights = checkOut.difference(checkIn).inDays;
        expect(nights, 3);

        final totalEstimated = nights * pricePerNight;
        expect(totalEstimated, 240.00);
        expect(totalEstimated.toStringAsFixed(2), '240.00');
      });

      test('Guarda el total calculado correctamente en la entidad de reservación', () async {
        const double calculatedTotal = 240.00;

        final reservation = await repository.createReservation(
          CreateReservationParams(
            roomId: 'room-103',
            guestId: 'guest-4',
            guestName: 'María Torres',
            checkIn: DateTime(2026, 11, 1),
            checkOut: DateTime(2026, 11, 4),
            total: calculatedTotal,
          ),
        );

        expect(reservation.total, 240.00);
        expect(reservation.nights, 3);
      });
    });
  });
}

