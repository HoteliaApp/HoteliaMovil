import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/connectivity/connectivity_provider.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/screens/reservations/reservations_screen.dart';
import 'package:hotel_app/presentation/screens/rooms/rooms_screen.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_card.dart';
import 'package:hotel_app/presentation/widgets/shared/offline_banner.dart';

class _FakeRoomsNotifier extends RoomsNotifier {
  final RoomsState _initial;
  _FakeRoomsNotifier(this._initial);

  @override
  RoomsState build() => _initial;
}

class _FakeReservationsNotifier extends ReservationsNotifier {
  final ReservationsState _initial;
  _FakeReservationsNotifier(this._initial);

  @override
  ReservationsState build() => _initial;
}

class _MockSyncNotifier extends SyncNotifier {
  final SyncState _initial;
  _MockSyncNotifier(this._initial);

  @override
  SyncState build() => _initial;
}

void main() {
  group('H-31 Modo Fuera de Línea, Caché y Persistencia en Mostrador', () {
    final List<Room> cachedRooms = [
      const Room(
        id: 'room-101',
        roomNumber: 101,
        roomType: RoomType.single,
        status: RoomStatus.available,
        pricePerNight: 50.0,
        description: 'Habitación Sencilla Estándar',
        images: ['https://example.com/room101.jpg'],
        capacity: 1,
        amenities: ['WiFi', 'TV'],
      ),
      const Room(
        id: 'room-102',
        roomNumber: 102,
        roomType: RoomType.double,
        status: RoomStatus.occupied,
        pricePerNight: 80.0,
        description: 'Habitación Doble Estándar',
        images: ['https://example.com/room102.jpg'],
        capacity: 2,
        amenities: ['WiFi', 'TV', 'AC'],
      ),
    ];

    testWidgets(
      'Escenario 1 (Gherkin): Dado que el dispositivo pierde la conexión a internet, '
      'cuando el usuario abre la lista de habitaciones, '
      'entonces la app muestra los últimos datos cacheados con un banner indicador de "Modo fuera de línea"',
      (tester) async {
        // GIVEN: El dispositivo no tiene conexión a internet (modo fuera de línea)
        const offlineSyncState = SyncState(
          isOnline: false,
          hasPendingWrites: false,
          isFromCache: true,
        );

        // AND: Se tienen habitaciones cacheadas localmente
        final roomsState = RoomsState(
          rooms: cachedRooms,
          isLoading: false,
        );

        // WHEN: El usuario abre la lista de habitaciones (RoomsScreen)
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomsProvider.overrideWith(() => _FakeRoomsNotifier(roomsState)),
              syncProvider.overrideWith(() => _MockSyncNotifier(offlineSyncState)),
              currentHotelIdProvider.overrideWithValue('hotel_101'),
              authProvider.overrideWith(() => _MockAuthNotifier()),
            ],
            child: const MaterialApp(
              home: RoomsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: La app muestra el banner indicador de "Modo fuera de línea"
        expect(find.byKey(const Key('offline_banner')), findsOneWidget);
        expect(find.text('Modo fuera de línea'), findsOneWidget);
        expect(
          find.text('Mostrando datos guardados en caché local. Los cambios se enviarán al reconectar.'),
          findsOneWidget,
        );

        // AND: Muestra los últimos datos cacheados sin bloquear la pantalla
        expect(find.byType(RoomCard), findsNWidgets(2));
        expect(find.text('Habitación 101'), findsOneWidget);
        expect(find.text('Habitación 102'), findsOneWidget);
        expect(find.text('2 habitaciones encontradas'), findsOneWidget);
      },
    );

    testWidgets(
      'OfflineBanner muestra badge de "Sincronización pendiente" cuando existen escrituras locales en búfer',
      (tester) async {
        const pendingSyncState = SyncState(
          isOnline: false,
          hasPendingWrites: true,
          isFromCache: true,
        );

        final roomsState = RoomsState(
          rooms: cachedRooms,
          isLoading: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomsProvider.overrideWith(() => _FakeRoomsNotifier(roomsState)),
              syncProvider.overrideWith(() => _MockSyncNotifier(pendingSyncState)),
              currentHotelIdProvider.overrideWithValue('hotel_101'),
              authProvider.overrideWith(() => _MockAuthNotifier()),
            ],
            child: const MaterialApp(
              home: RoomsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('offline_banner')), findsOneWidget);
        expect(find.text('Modo fuera de línea'), findsOneWidget);
        expect(find.text('Sincronización pendiente'), findsOneWidget);
      },
    );

    testWidgets(
      'OfflineBanner desaparece automáticamente cuando el dispositivo recupera la conexión (en línea)',
      (tester) async {
        const onlineSyncState = SyncState(
          isOnline: true,
          hasPendingWrites: false,
          isFromCache: false,
        );

        final roomsState = RoomsState(
          rooms: cachedRooms,
          isLoading: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomsProvider.overrideWith(() => _FakeRoomsNotifier(roomsState)),
              syncProvider.overrideWith(() => _MockSyncNotifier(onlineSyncState)),
              currentHotelIdProvider.overrideWithValue('hotel_101'),
              authProvider.overrideWith(() => _MockAuthNotifier()),
            ],
            child: const MaterialApp(
              home: RoomsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // El banner NO debe mostrarse cuando hay internet
        expect(find.byKey(const Key('offline_banner')), findsNothing);
        expect(find.text('Modo fuera de línea'), findsNothing);

        // Las habitaciones siguen mostrándose normalmente
        expect(find.byType(RoomCard), findsNWidgets(2));
      },
    );

    testWidgets(
      'ReservationsScreen muestra el banner de "Modo fuera de línea" y datos cacheados cuando se desconecta',
      (tester) async {
        const offlineSyncState = SyncState(
          isOnline: false,
          hasPendingWrites: false,
          isFromCache: true,
        );

        final cachedReservations = [
          Reservation(
            id: 'res-offline-1',
            roomId: 'room-101',
            roomNumber: 101,
            guestId: 'guest-1',
            guestName: 'Laura Méndez',
            checkIn: DateTime.now(),
            checkOut: DateTime.now().add(const Duration(days: 2)),
            companions: 1,
            status: ReservationStatus.confirmed,
            total: 100.0,
            createdAt: DateTime.now(),
          ),
        ];

        final reservationsState = ReservationsState(
          reservations: cachedReservations,
          isLoading: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              reservationsProvider.overrideWith(() => _FakeReservationsNotifier(reservationsState)),
              syncProvider.overrideWith(() => _MockSyncNotifier(offlineSyncState)),
              currentHotelIdProvider.overrideWithValue('hotel_101'),
              authProvider.overrideWith(() => _MockAuthNotifier()),
            ],
            child: const MaterialApp(
              home: ReservationsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('offline_banner')), findsOneWidget);
        expect(find.text('Modo fuera de línea'), findsOneWidget);
        expect(find.text('Laura Méndez'), findsOneWidget);
      },
    );
  });
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      isAuthenticated: true,
      role: UserRole.receptionist,
      email: 'recepcionista@hotel.com',
      name: 'Recepcionista Turno',
      hotelId: 'hotel_101',
    );
  }
}
