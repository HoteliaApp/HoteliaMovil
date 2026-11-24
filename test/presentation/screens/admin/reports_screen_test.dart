import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/reports/reports_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';
import 'package:hotel_app/presentation/screens/admin/reports_screen.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<Task> completedTasks;

  _FakeTaskRepository({
    required this.completedTasks,
  });

  @override
  Future<String> createCleaningTask({
    required String roomId,
    required int roomNumber,
    required String guestName,
  }) async =>
      'task-id';

  @override
  Future<String> createManualAlert({
    required String roomId,
    required int roomNumber,
    required String taskType,
    required String description,
    required String guestName,
  }) async =>
      'alert-id';

  @override
  Stream<List<Task>> watchActiveTasks() => Stream.value(const []);

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {}

  @override
  Stream<List<Task>> watchRecentlyCompletedTasks({int limit = 20}) =>
      Stream.value(completedTasks);
}

class _FakeRoomsRepository implements RoomsRepository {
  final List<Room> rooms;
  _FakeRoomsRepository(this.rooms);

  @override
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type}) async =>
      rooms;

  @override
  Future<Room> getRoomById(String id) async =>
      rooms.firstWhere((r) => r.id == id);

  @override
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus) async =>
      rooms.firstWhere((r) => r.id == id);

  @override
  Stream<List<Room>> watchRooms({RoomStatus? status, RoomType? type}) =>
      Stream.value(rooms);

  @override
  Future<bool> markRoomCleanedIfPending(String roomId) async => false;

  @override
  Future<void> createRoom(Room room) async {}

  @override
  Stream<RoomMetrics> watchRoomMetrics() =>
      Stream.value(RoomMetrics.fromRooms(rooms));

  @override
  Future<RoomMetrics> recalculateRoomMetrics() async =>
      RoomMetrics.fromRooms(rooms);
}

class _FakeReservationsRepository implements ReservationsRepository {
  final List<Reservation> reservations;
  _FakeReservationsRepository(this.reservations);

  @override
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    String? guestId,
  }) async =>
      reservations;

  @override
  Future<Reservation> getReservationById(String id) async =>
      reservations.firstWhere((r) => r.id == id);

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

Room _makeRoom(String id, int number) => Room(
      id: id,
      roomNumber: number,
      roomType: RoomType.double,
      status: RoomStatus.available,
      pricePerNight: 100.0,
      description: 'Habitación $number',
      images: const [],
      capacity: 2,
      amenities: const ['WiFi'],
    );

Task _makeCompletedTask({
  required String id,
  required int roomNumber,
  required String taskType,
  required DateTime completedAt,
  required int durationMinutes,
}) {
  return Task(
    id: id,
    roomId: 'room-$roomNumber',
    roomNumber: roomNumber,
    taskType: taskType,
    status: 'completed',
    description: 'Tarea $id',
    guestName: 'Huésped $roomNumber',
    assignedBy: 'admin-1',
    createdAt: completedAt.subtract(Duration(minutes: durationMinutes)),
    completedAt: completedAt,
    priority: 4,
  );
}

void main() {
  group('H-28 Reportes de Productividad y Tiempos de Respuesta (Unit)', () {
    test('Task.responseDuration y responseMinutes calculan correctamente el tiempo de respuesta', () {
      final created = DateTime(2026, 11, 19, 10, 0);
      final completed = DateTime(2026, 11, 19, 10, 25);

      final task = Task(
        id: 't-1',
        roomId: 'room-101',
        roomNumber: 101,
        taskType: 'cleaning',
        status: 'completed',
        description: 'Limpieza post check-out',
        guestName: 'Juan Pérez',
        assignedBy: 'recep-1',
        createdAt: created,
        completedAt: completed,
      );

      expect(task.responseDuration, const Duration(minutes: 25));
      expect(task.responseMinutes, closeTo(25.0, 0.001));

      final pendingTask = task.copyWith(status: 'pending');
      final uncompleted = Task(
        id: pendingTask.id,
        roomId: pendingTask.roomId,
        roomNumber: pendingTask.roomNumber,
        taskType: pendingTask.taskType,
        status: 'pending',
        description: pendingTask.description,
        guestName: pendingTask.guestName,
        assignedBy: pendingTask.assignedBy,
        createdAt: created,
      );
      expect(uncompleted.responseDuration, isNull);
      expect(uncompleted.responseMinutes, isNull);
    });

    test(
      'ReportsNotifier calcula promedio de limpieza, incidencias y ocupación al filtrar rango de fechas',
      () async {
        final now = DateTime.now();
        final todayMid = DateTime(now.year, now.month, now.day, 12, 0);

        final tasks = [
          _makeCompletedTask(
            id: 'c-1',
            roomNumber: 101,
            taskType: 'cleaning',
            completedAt: todayMid,
            durationMinutes: 20,
          ),
          _makeCompletedTask(
            id: 'c-2',
            roomNumber: 102,
            taskType: 'cleaning',
            completedAt: todayMid.subtract(const Duration(days: 2)),
            durationMinutes: 30,
          ),
          _makeCompletedTask(
            id: 'm-1',
            roomNumber: 103,
            taskType: 'maintenance',
            completedAt: todayMid.subtract(const Duration(days: 1)),
            durationMinutes: 45,
          ),
          _makeCompletedTask(
            id: 'c-old',
            roomNumber: 104,
            taskType: 'cleaning',
            completedAt: todayMid.subtract(const Duration(days: 10)),
            durationMinutes: 40,
          ),
        ];

        final rooms = [
          _makeRoom('room-101', 101),
          _makeRoom('room-102', 102),
          _makeRoom('room-103', 103),
          _makeRoom('room-104', 104),
        ];

        final todayDay = DateTime(now.year, now.month, now.day);
        final reservations = [
          Reservation(
            id: 'res-1',
            roomId: 'room-101',
            roomNumber: 101,
            guestId: 'g-1',
            guestName: 'Huésped 1',
            checkIn: todayDay.subtract(const Duration(days: 1)),
            checkOut: todayDay.add(const Duration(days: 2)),
            companions: 1,
            status: ReservationStatus.checkedIn,
            total: 300,
            createdAt: todayDay.subtract(const Duration(days: 2)),
          ),
          Reservation(
            id: 'res-2',
            roomId: 'room-102',
            roomNumber: 102,
            guestId: 'g-2',
            guestName: 'Huésped 2',
            checkIn: todayDay,
            checkOut: todayDay.add(const Duration(days: 1)),
            companions: 0,
            status: ReservationStatus.confirmed,
            total: 100,
            createdAt: todayDay.subtract(const Duration(days: 1)),
          ),
          Reservation(
            id: 'res-cancelled',
            roomId: 'room-103',
            roomNumber: 103,
            guestId: 'g-3',
            guestName: 'Cancelado',
            checkIn: todayDay,
            checkOut: todayDay.add(const Duration(days: 2)),
            companions: 0,
            status: ReservationStatus.cancelled,
            total: 200,
            createdAt: todayDay.subtract(const Duration(days: 1)),
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWithValue(
              _FakeTaskRepository(completedTasks: tasks),
            ),
            roomsRepositoryProvider.overrideWithValue(
              _FakeRoomsRepository(rooms),
            ),
            reservationsRepositoryProvider.overrideWithValue(
              _FakeReservationsRepository(reservations),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(reportsProvider, (_, _) {});
        addTearDown(sub.close);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // Rango inicial: últimos 7 días -> 2 limpiezas (20 y 30 min = 25.0 min), 3 tareas totales
        var state = container.read(reportsProvider);
        expect(state.averageCleaningMinutes, closeTo(25.0, 0.01));
        expect(state.resolvedIncidentsCount, 3);
        expect(state.cleaningResponseSeries.length, 2);
        expect(state.weeklyOccupancySeries.length, 7);
        expect(
          state.weeklyOccupancySeries.last.occupancyPercentage,
          closeTo(50.0, 0.01), // 2 ocupadas de 4 (res-cancelled excluida)
        );

        // Ampliar rango a 14 días -> incluye limpieza de hace 10 días (40 min) -> promedio 30.0 min
        container.read(reportsProvider.notifier).setPresetDays(14);
        state = container.read(reportsProvider);
        expect(state.averageCleaningMinutes, closeTo(30.0, 0.01));
        expect(state.resolvedIncidentsCount, 4);
        expect(state.cleaningResponseSeries.length, 3);

        // Filtrar rango exacto solo a los últimos 2 días -> excluye la de hace 2 días
        container.read(reportsProvider.notifier).setDateRange(
              DateTimeRange(
                start: todayDay.subtract(const Duration(days: 1)),
                end: todayDay,
              ),
            );
        state = container.read(reportsProvider);
        expect(state.averageCleaningMinutes, closeTo(20.0, 0.01));
        expect(state.resolvedIncidentsCount, 2);
      },
    );
  });

  group('H-28 Criterio de Aceptación Gherkin (Widget)', () {
    testWidgets(
      'Escenario 1: Gerente filtra por rango de fechas y visualiza gráfica de tiempo medio Check-Out → Habitación Limpia',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final todayMid = DateTime(now.year, now.month, now.day, 12, 0);
        final todayDay = DateTime(now.year, now.month, now.day);

        final tasks = [
          _makeCompletedTask(
            id: 'c-1',
            roomNumber: 101,
            taskType: 'cleaning',
            completedAt: todayMid,
            durationMinutes: 20,
          ),
          _makeCompletedTask(
            id: 'c-2',
            roomNumber: 102,
            taskType: 'cleaning',
            completedAt: todayMid.subtract(const Duration(days: 1)),
            durationMinutes: 30,
          ),
          _makeCompletedTask(
            id: 'm-1',
            roomNumber: 103,
            taskType: 'maintenance',
            completedAt: todayMid.subtract(const Duration(days: 1)),
            durationMinutes: 15,
          ),
          _makeCompletedTask(
            id: 'c-old',
            roomNumber: 104,
            taskType: 'cleaning',
            completedAt: todayMid.subtract(const Duration(days: 10)),
            durationMinutes: 40,
          ),
        ];

        final rooms = [
          _makeRoom('room-101', 101),
          _makeRoom('room-102', 102),
          _makeRoom('room-103', 103),
          _makeRoom('room-104', 104),
        ];

        final reservations = [
          Reservation(
            id: 'res-1',
            roomId: 'room-101',
            roomNumber: 101,
            guestId: 'g-1',
            guestName: 'Laura Díaz',
            checkIn: todayDay.subtract(const Duration(days: 2)),
            checkOut: todayDay.add(const Duration(days: 2)),
            companions: 1,
            status: ReservationStatus.checkedIn,
            total: 400,
            createdAt: todayDay.subtract(const Duration(days: 3)),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskRepositoryProvider.overrideWithValue(
                _FakeTaskRepository(completedTasks: tasks),
              ),
              roomsRepositoryProvider.overrideWithValue(
                _FakeRoomsRepository(rooms),
              ),
              reservationsRepositoryProvider.overrideWithValue(
                _FakeReservationsRepository(reservations),
              ),
            ],
            child: MaterialApp(
              theme: const AppTheme(isDarkMode: false).getTheme(),
              home: const ReportsScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Dado que el gerente entra a la sección de Reportes (por defecto últimos 7 días)
        expect(find.text('Reportes de Productividad'), findsOneWidget);
        expect(
          find.byKey(const Key('reports_date_range_picker_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('cleaning_response_time_chart')),
          findsOneWidget,
        );
        expect(
          find.text('Tiempo Medio entre Check-Out y Habitación Limpia'),
          findsOneWidget,
        );

        // Verifica que la gráfica LineChart de fl_chart está renderizada y muestra 25.0 min
        expect(
          find.descendant(
            of: find.byKey(const Key('cleaning_response_time_chart')),
            matching: find.byType(LineChart),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('kpi_avg_cleaning_time')),
            matching: find.text('25.0 min'),
          ),
          findsOneWidget,
        );

        // También están presentes las gráficas de incidencias resueltas y ocupación semanal
        expect(
          find.descendant(
            of: find.byKey(const Key('resolved_incidents_chart')),
            matching: find.byType(BarChart),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('weekly_occupancy_chart')),
            matching: find.byType(BarChart),
          ),
          findsOneWidget,
        );

        // Cuando filtra por rango de fechas (Últimos 14 días)
        await tester.tap(find.byKey(const Key('reports_preset_14d')));
        await tester.pumpAndSettle();

        // Entonces el promedio se actualiza a 30.0 min al incluir la limpieza de hace 10 días
        expect(
          find.descendant(
            of: find.byKey(const Key('kpi_avg_cleaning_time')),
            matching: find.text('30.0 min'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('cleaning_response_time_chart')),
            matching: find.byType(LineChart),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
