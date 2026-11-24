import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/dashboard/dashboard_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';
import 'package:hotel_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:hotel_app/presentation/widgets/dashboard/tasks_panel_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        isAuthenticated: true,
        email: 'recepcion@hotelia.com',
        name: 'Recepcionista',
        role: UserRole.receptionist,
        status: UserStatus.active,
        hotelId: 'hotel_101',
        isLoading: false,
      );
}

class _StreamRoomsRepository implements RoomsRepository {
  final StreamController<List<Room>> controller;
  List<Room> latestRooms;

  _StreamRoomsRepository({
    required this.controller,
    this.latestRooms = const [],
  });

  @override
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type}) async =>
      latestRooms;

  @override
  Future<Room> getRoomById(String id) async =>
      latestRooms.firstWhere((r) => r.id == id);

  @override
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus) async {
    final idx = latestRooms.indexWhere((r) => r.id == id);
    final updated = latestRooms[idx].copyWith(status: newStatus);
    latestRooms = [
      ...latestRooms.sublist(0, idx),
      updated,
      ...latestRooms.sublist(idx + 1),
    ];
    controller.add(latestRooms);
    return updated;
  }

  @override
  Stream<List<Room>> watchRooms({RoomStatus? status, RoomType? type}) =>
      controller.stream;

  @override
  Future<bool> markRoomCleanedIfPending(String roomId) async => false;

  @override
  Future<void> createRoom(Room room) async {
    latestRooms = [...latestRooms, room];
    controller.add(latestRooms);
  }

  // El dashboard ahora lee el agregado: se deriva del mismo stream de
  // habitaciones para que las pruebas sigan midiendo lo mismo.
  @override
  Stream<RoomMetrics> watchRoomMetrics() =>
      controller.stream.map(RoomMetrics.fromRooms);

  @override
  Future<RoomMetrics> recalculateRoomMetrics() async =>
      RoomMetrics.fromRooms(latestRooms);
}

class _StreamTaskRepository implements TaskRepository {
  final StreamController<List<Task>> controller;

  _StreamTaskRepository(this.controller);

  @override
  Stream<List<Task>> watchActiveTasks() => controller.stream;

  @override
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  }) async =>
      'task-new';

  @override
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) async =>
      'alert-new';

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {}

  @override
  Stream<List<Task>> watchRecentlyCompletedTasks({int limit = 20}) =>
      Stream.value(const []);
}

class _FakeReservationsRepository implements ReservationsRepository {
  @override
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  }) async =>
      const [];

  @override
  Future<Reservation> getReservationById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async =>
      null;

  @override
  Future<Reservation> createReservation(CreateReservationParams params) async =>
      throw UnimplementedError();

  @override
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Reservation> checkOut(String reservationId) async =>
      throw UnimplementedError();

  @override
  Future<Reservation> cancelReservation(String reservationId) async =>
      throw UnimplementedError();
}

Room _makeRoom(String id, int number, RoomStatus status) {
  return Room(
    id: id,
    roomNumber: number,
    roomType: RoomType.double,
    status: status,
    pricePerNight: 100.0,
    description: 'Habitación $number',
    images: const [],
    capacity: 2,
    amenities: const ['WiFi', 'TV'],
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('Issue H-16 - Sincronización Reactiva del Dashboard', () {
    test(
      'Escenario 1 (Provider): Check-out actualiza contadores y tareas activas al instante',
      () async {
        final roomsController = StreamController<List<Room>>.broadcast();
        final tasksController = StreamController<List<Task>>.broadcast();
        addTearDown(() async {
          await roomsController.close();
          await tasksController.close();
        });

        final initialRooms = [
          _makeRoom('room-101', 101, RoomStatus.available),
          _makeRoom('room-102', 102, RoomStatus.occupied),
          _makeRoom('room-103', 103, RoomStatus.occupied),
          _makeRoom('room-104', 104, RoomStatus.reserved),
        ];

        final roomsRepo = _StreamRoomsRepository(
          controller: roomsController,
          latestRooms: initialRooms,
        );
        final taskRepo = _StreamTaskRepository(tasksController);

        final container = ProviderContainer(
          overrides: [
            roomsRepositoryProvider.overrideWithValue(roomsRepo),
            taskRepositoryProvider.overrideWithValue(taskRepo),
            reservationsRepositoryProvider
                .overrideWithValue(_FakeReservationsRepository()),
          ],
        );
        addTearDown(container.dispose);

        // Mantener escuchado el provider para activar su ciclo de vida
        final sub = container.listen(dashboardProvider, (_, _) {});
        addTearDown(sub.close);

        // Esperar microtask de inicialización
        await Future<void>.delayed(Duration.zero);

        // Emitir estado inicial en los streams
        roomsController.add(initialRooms);
        tasksController.add(const []);
        await Future<void>.delayed(Duration.zero);

        var state = container.read(dashboardProvider);
        expect(state.isLoading, isFalse);
        expect(state.roomStats.available, 1);
        expect(state.roomStats.occupied, 2);
        expect(state.roomStats.pendingCleaning, 0);
        expect(state.roomStats.reserved, 1);
        expect(state.activeTasksCount, 0);

        // Cuando ocurre un check-out en el hotel (hab. 102 pasa a pendingCleaning
        // y se crea una nueva tarea de limpieza)
        final roomsAfterCheckOut = [
          _makeRoom('room-101', 101, RoomStatus.available),
          _makeRoom('room-102', 102, RoomStatus.pendingCleaning),
          _makeRoom('room-103', 103, RoomStatus.occupied),
          _makeRoom('room-104', 104, RoomStatus.reserved),
        ];
        final cleaningTask = Task(
          id: 'task-checkout-102',
          roomId: 'room-102',
          roomNumber: 102,
          taskType: 'cleaning',
          status: 'pending',
          description: 'Limpieza post check-out — Hab. 102. Huésped: Carlos Méndez',
          guestName: 'Carlos Méndez',
          assignedBy: 'user-recep',
          createdAt: DateTime.now(),
          priority: 4,
        );

        roomsController.add(roomsAfterCheckOut);
        tasksController.add([cleaningTask]);
        await Future<void>.delayed(Duration.zero);

        // Entonces ocupadas disminuye en 1, pendientes de limpieza aumenta en 1
        // y activeTasks contiene la nueva tarea de limpieza
        state = container.read(dashboardProvider);
        expect(state.roomStats.occupied, 1);
        expect(state.roomStats.pendingCleaning, 1);
        expect(state.activeTasksCount, 1);
        expect(state.activeTasks.first.roomNumber, 102);
        expect(state.activeTasks.first.taskType, 'cleaning');
      },
    );

    testWidgets(
      'Escenario 1 (UI): DashboardScreen actualiza tarjetas con AnimatedSwitcher y muestra la tarea de limpieza',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final roomsController = StreamController<List<Room>>.broadcast();
        final tasksController = StreamController<List<Task>>.broadcast();
        addTearDown(() async {
          await roomsController.close();
          await tasksController.close();
        });

        final initialRooms = [
          _makeRoom('room-101', 101, RoomStatus.available),
          _makeRoom('room-102', 102, RoomStatus.occupied),
          _makeRoom('room-103', 103, RoomStatus.occupied),
          _makeRoom('room-104', 104, RoomStatus.occupied),
        ];

        final roomsRepo = _StreamRoomsRepository(
          controller: roomsController,
          latestRooms: initialRooms,
        );
        final taskRepo = _StreamTaskRepository(tasksController);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(_FakeAuthNotifier.new),
              roomsRepositoryProvider.overrideWithValue(roomsRepo),
              taskRepositoryProvider.overrideWithValue(taskRepo),
              reservationsRepositoryProvider
                  .overrideWithValue(_FakeReservationsRepository()),
            ],
            child: MaterialApp(
              theme: const AppTheme(isDarkMode: false).getTheme(),
              home: const DashboardScreen(),
            ),
          ),
        );

        // Permitir que build() ejecute su microtask y se suscriba a los streams
        await tester.pump();
        await tester.pump();

        // Dado que el usuario está en el dashboard con 3 ocupadas y 0 en limpieza
        roomsController.add(initialRooms);
        tasksController.add(const []);
        await tester.pumpAndSettle();

        Finder cardFor(String label) => find.ancestor(
              of: find.text(label),
              matching: find.byType(InkWell),
            );

        expect(find.byType(AnimatedSwitcher), findsWidgets);
        expect(find.text('Ocupadas'), findsOneWidget);
        expect(find.text('Pendientes de limpieza'), findsOneWidget);
        expect(find.text('Tareas activas'), findsOneWidget);
        expect(
          find.descendant(of: cardFor('Ocupadas'), matching: find.text('3')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardFor('Pendientes de limpieza'),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardFor('Tareas activas'),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
        expect(find.text('Hab. 102'), findsNothing); // Sin tarea aún

        // Cuando ocurre un check-out en el hotel
        final roomsAfterCheckOut = [
          _makeRoom('room-101', 101, RoomStatus.available),
          _makeRoom('room-102', 102, RoomStatus.pendingCleaning),
          _makeRoom('room-103', 103, RoomStatus.occupied),
          _makeRoom('room-104', 104, RoomStatus.occupied),
        ];
        final cleaningTask = Task(
          id: 'task-checkout-102',
          roomId: 'room-102',
          roomNumber: 102,
          taskType: 'cleaning',
          status: 'pending',
          description: 'Limpieza post check-out — Hab. 102',
          guestName: 'Carlos Méndez',
          assignedBy: 'user-recep',
          createdAt: DateTime.now(),
          priority: 4,
        );

        roomsController.add(roomsAfterCheckOut);
        tasksController.add([cleaningTask]);

        // Avanzar animación del AnimatedSwitcher (300ms)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Entonces ocupadas bajó de 3 a 2, pendientes de limpieza subió de 0 a 1,
        // tareas activas subió de 0 a 1, y el panel muestra la nueva tarea de limpieza
        expect(
          find.descendant(of: cardFor('Ocupadas'), matching: find.text('2')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardFor('Pendientes de limpieza'),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardFor('Tareas activas'),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(find.byType(TasksPanelWidget), findsOneWidget);
        expect(find.text('Hab. 102'), findsOneWidget);
        expect(find.text('Limpieza'), findsOneWidget);
        expect(find.text('Carlos Méndez'), findsOneWidget);
        expect(find.text('1 activa'), findsOneWidget);
      },
    );
  });
}
