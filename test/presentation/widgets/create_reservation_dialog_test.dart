import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/widgets/reservations/create_reservation_dialog.dart';

class FakeRoomsRepository implements RoomsRepository {
  final List<Room> rooms;
  FakeRoomsRepository(this.rooms);

  @override
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type}) async => rooms;

  @override
  Future<Room> getRoomById(String id) async => rooms.firstWhere((r) => r.id == id);

  @override
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus) async =>
      rooms.firstWhere((r) => r.id == id);
}

class FakeReservationsRepository implements ReservationsRepository {
  final List<Reservation> reservations;
  FakeReservationsRepository(this.reservations);

  @override
  Future<List<Reservation>> getReservations({ReservationStatus? status, String? guestId}) async =>
      reservations;

  @override
  Future<Reservation> getReservationById(String id) async =>
      reservations.firstWhere((r) => r.id == id);

  @override
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final newIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final newOut = DateTime(checkOut.year, checkOut.month, checkOut.day);

    for (final r in reservations) {
      if (r.roomId == roomId &&
          r.status != ReservationStatus.cancelled &&
          r.status != ReservationStatus.completed) {
        final existIn = DateTime(r.checkIn.year, r.checkIn.month, r.checkIn.day);
        final existOut = DateTime(r.checkOut.year, r.checkOut.month, r.checkOut.day);
        if (newIn.isBefore(existOut) && newOut.isAfter(existIn)) {
          return r;
        }
      }
    }
    return null;
  }

  @override
  Future<Reservation> createReservation(CreateReservationParams params) async {
    final conflict = await getOverlappingReservation(
      roomId: params.roomId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
    );
    if (conflict != null) {
      throw Exception('Fechas empalmadas');
    }
    final r = Reservation(
      id: 'res-${reservations.length + 1}',
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
    reservations.add(r);
    return r;
  }

  @override
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) async => reservations.first;

  @override
  Future<Reservation> checkOut(String reservationId) async => reservations.first;

  @override
  Future<Reservation> cancelReservation(String reservationId) async => reservations.first;
}

void main() {
  final room101 = const Room(
    id: 'room-101',
    roomNumber: 101,
    roomType: RoomType.single,
    status: RoomStatus.available,
    pricePerNight: 50.0,
    description: 'Habitación 101',
    images: [],
    capacity: 1,
    amenities: [],
  );

  final room103 = const Room(
    id: 'room-103',
    roomNumber: 103,
    roomType: RoomType.double,
    status: RoomStatus.available,
    pricePerNight: 80.0,
    description: 'Habitación 103',
    images: [],
    capacity: 2,
    amenities: [],
  );

  final existingReservation101 = Reservation(
    id: 'res-existing-101',
    roomId: 'room-101',
    guestId: 'guest-1',
    guestName: 'Huésped Existente',
    checkIn: DateTime(2026, 10, 20),
    checkOut: DateTime(2026, 10, 25),
    companions: 1,
    status: ReservationStatus.confirmed,
    total: 250.0,
    createdAt: DateTime(2026, 10, 1),
  );

  Widget createWidgetUnderTest({
    required FakeRoomsRepository roomsRepo,
    required FakeReservationsRepository resRepo,
    DateTime? initialCheckIn,
    DateTime? initialCheckOut,
    String? initialRoomId,
    bool isDarkMode = false,
  }) {
    return ProviderScope(
      overrides: [
        roomsRepositoryProvider.overrideWithValue(roomsRepo),
        reservationsRepositoryProvider.overrideWithValue(resRepo),
      ],
      child: MaterialApp(
        theme: const AppTheme(isDarkMode: false).getTheme(),
        darkTheme: const AppTheme(isDarkMode: true).getTheme(),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CreateReservationDialog(
              initialCheckIn: initialCheckIn,
              initialCheckOut: initialCheckOut,
              initialRoomId: initialRoomId,
            ),
          ),
        ),
      ),
    );
  }

  group('CreateReservationDialog Widget Tests - Issue H-17', () {
    testWidgets(
        'Escenario 1: Muestra mensaje de advertencia y bloquea guardado cuando hay fechas empalmadas',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final roomsRepo = FakeRoomsRepository([room101, room103]);
      final resRepo = FakeReservationsRepository([existingReservation101]);

      // Dado que la habitación 101 ya está reservada del 20 al 25 de octubre
      // Cuando se intenta registrar una nueva reserva para la habitación 101 del 22 al 24 de octubre
      await tester.pumpWidget(createWidgetUnderTest(
        roomsRepo: roomsRepo,
        resRepo: resRepo,
        initialRoomId: 'room-101',
        initialCheckIn: DateTime(2026, 10, 22),
        initialCheckOut: DateTime(2026, 10, 24),
      ));
      await tester.pumpAndSettle();

      // Entonces el sistema muestra un mensaje de advertencia
      expect(find.textContaining('Advertencia: Fechas empalmadas'), findsOneWidget);
      expect(find.textContaining('La habitación ya está reservada del 20/10 al 25/10'), findsOneWidget);

      // Y bloquea el guardado
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Guardado bloqueado (Fechas empalmadas)');
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull); // Botón deshabilitado
    });

    testWidgets(
        'Escenario 2: Cálculo dinámico de costo (3 noches en habitación de \$80/noche = \$240.00)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final roomsRepo = FakeRoomsRepository([room101, room103]);
      final resRepo = FakeReservationsRepository([existingReservation101]);

      // Dado que se seleccionan 3 noches en una habitación de $80/noche (room-103)
      // Cuando se eligen las fechas (ej. del 1 al 4 de noviembre)
      await tester.pumpWidget(createWidgetUnderTest(
        roomsRepo: roomsRepo,
        resRepo: resRepo,
        initialRoomId: 'room-103',
        initialCheckIn: DateTime(2026, 11, 1),
        initialCheckOut: DateTime(2026, 11, 4),
      ));
      await tester.pumpAndSettle();

      // Entonces se muestra en pantalla el total estimado de $240.00 y el desglose de 3 noches
      expect(find.textContaining('3 noches x \$80.00'), findsOneWidget);
      expect(find.textContaining('Total estimado: \$240.00'), findsOneWidget);

      // Y el botón de creación permanece habilitado para guardar
      final createButtonFinder = find.widgetWithText(ElevatedButton, 'Crear Reservación');
      expect(createButtonFinder, findsOneWidget);

      final createButton = tester.widget<ElevatedButton>(createButtonFinder);
      expect(createButton.onPressed, isNotNull);
    });

    testWidgets('Modo oscuro: Renderiza la advertencia de empalme adaptando colores de tema oscuro',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final roomsRepo = FakeRoomsRepository([room101, room103]);
      final resRepo = FakeReservationsRepository([existingReservation101]);

      await tester.pumpWidget(createWidgetUnderTest(
        roomsRepo: roomsRepo,
        resRepo: resRepo,
        initialRoomId: 'room-101',
        initialCheckIn: DateTime(2026, 10, 22),
        initialCheckOut: DateTime(2026, 10, 24),
        isDarkMode: true,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Advertencia: Fechas empalmadas'), findsOneWidget);
      expect(find.textContaining('La habitación ya está reservada del 20/10 al 25/10'), findsOneWidget);

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Guardado bloqueado (Fechas empalmadas)');
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });
}
