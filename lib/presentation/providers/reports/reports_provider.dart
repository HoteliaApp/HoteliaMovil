import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';

// ───────────────────────────── Modelos de Métricas ───────────────────────────

/// Punto diario de tiempo medio de respuesta entre Check-Out y Limpieza completada.
class DailyCleaningPoint {
  final DateTime date;
  final double averageMinutes;
  final int completedCount;

  const DailyCleaningPoint({
    required this.date,
    required this.averageMinutes,
    required this.completedCount,
  });
}

/// Conteo de incidencias o tareas resueltas agrupadas por categoría.
class IncidentCategoryCount {
  final String taskType;
  final String label;
  final int count;

  const IncidentCategoryCount({
    required this.taskType,
    required this.label,
    required this.count,
  });
}

/// Punto diario de tasa de ocupación semanal del hotel.
class DailyOccupancyPoint {
  final DateTime date;
  final double occupancyPercentage;
  final int occupiedRooms;
  final int totalRooms;

  const DailyOccupancyPoint({
    required this.date,
    required this.occupancyPercentage,
    required this.occupiedRooms,
    required this.totalRooms,
  });
}

// ───────────────────────────── Estado ────────────────────────────────────────

class ReportsState {
  final DateTimeRange selectedDateRange;
  final List<Task> completedTasks;
  final List<Task> activeTasks;
  final List<Room> rooms;
  final List<Reservation> reservations;
  final bool isLoading;
  final String? errorMessage;

  const ReportsState({
    required this.selectedDateRange,
    this.completedTasks = const [],
    this.activeTasks = const [],
    this.rooms = const [],
    this.reservations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DateTime get _rangeStart => DateTime(
        selectedDateRange.start.year,
        selectedDateRange.start.month,
        selectedDateRange.start.day,
      );

  DateTime get _rangeEnd => DateTime(
        selectedDateRange.end.year,
        selectedDateRange.end.month,
        selectedDateRange.end.day,
        23,
        59,
        59,
        999,
      );

  /// Tareas completadas cuya fecha efectiva cae dentro de [selectedDateRange].
  List<Task> get filteredCompletedTasks {
    return completedTasks.where((task) {
      if (task.status != 'completed') return false;
      final refDate = task.completedAt ?? task.createdAt;
      return !refDate.isBefore(_rangeStart) && !refDate.isAfter(_rangeEnd);
    }).toList();
  }

  /// Tareas de limpieza completadas dentro del rango con duración medible.
  List<Task> get filteredCleaningTasks {
    return filteredCompletedTasks
        .where((t) => t.taskType == 'cleaning' && t.responseMinutes != null)
        .toList();
  }

  /// Tiempo promedio en minutos entre Check-Out (createdAt) y Habitación Limpia (completedAt).
  double get averageCleaningMinutes {
    final cleaning = filteredCleaningTasks;
    if (cleaning.isEmpty) return 0.0;
    final totalMinutes = cleaning.fold<double>(
      0.0,
      (sum, task) => sum + (task.responseMinutes ?? 0.0),
    );
    return totalMinutes / cleaning.length;
  }

  /// Serie diaria de tiempos promedio de limpieza ordenados cronológicamente.
  List<DailyCleaningPoint> get cleaningResponseSeries {
    final grouped = <DateTime, List<double>>{};
    for (final task in filteredCleaningTasks) {
      final refDate = task.completedAt ?? task.createdAt;
      final dayKey = DateTime(refDate.year, refDate.month, refDate.day);
      grouped.putIfAbsent(dayKey, () => []).add(task.responseMinutes!);
    }

    final sortedDays = grouped.keys.toList()..sort();
    return sortedDays.map((day) {
      final durations = grouped[day]!;
      final avg = durations.reduce((a, b) => a + b) / durations.length;
      return DailyCleaningPoint(
        date: day,
        averageMinutes: avg,
        completedCount: durations.length,
      );
    }).toList();
  }

  /// Total de incidencias y tareas operativas resueltas en el rango.
  int get resolvedIncidentsCount => filteredCompletedTasks.length;

  /// Conteo de incidencias/tareas resueltas por categoría operativa.
  List<IncidentCategoryCount> get incidentsByCategory {
    const categories = [
      ('cleaning', 'Limpieza'),
      ('maintenance', 'Mantenimiento'),
      ('inspection', 'Inspección'),
      ('delivery', 'Entrega'),
      ('guest_request', 'Huésped'),
    ];

    final completed = filteredCompletedTasks;
    return categories.map((entry) {
      final (type, label) = entry;
      final count = completed.where((t) => t.taskType == type).length;
      return IncidentCategoryCount(
        taskType: type,
        label: label,
        count: count,
      );
    }).toList();
  }

  /// Serie de tasa de ocupación para los últimos 7 días hasta el fin del rango.
  List<DailyOccupancyPoint> get weeklyOccupancySeries {
    final endDay = DateTime(
      selectedDateRange.end.year,
      selectedDateRange.end.month,
      selectedDateRange.end.day,
    );
    final totalRooms = rooms.length;

    return List.generate(7, (index) {
      final day = endDay.subtract(Duration(days: 6 - index));
      if (totalRooms == 0) {
        return DailyOccupancyPoint(
          date: day,
          occupancyPercentage: 0.0,
          occupiedRooms: 0,
          totalRooms: 0,
        );
      }

      final occupiedRoomIds = <String>{};
      for (final r in reservations) {
        if (r.status == ReservationStatus.cancelled) continue;
        final checkInDay = DateTime(r.checkIn.year, r.checkIn.month, r.checkIn.day);
        final checkOutDay =
            DateTime(r.checkOut.year, r.checkOut.month, r.checkOut.day);

        if (!day.isBefore(checkInDay) && day.isBefore(checkOutDay)) {
          occupiedRoomIds.add(r.roomId);
        }
      }

      final occupiedCount = occupiedRoomIds.length.clamp(0, totalRooms);
      final percentage = (occupiedCount / totalRooms) * 100.0;

      return DailyOccupancyPoint(
        date: day,
        occupancyPercentage: percentage,
        occupiedRooms: occupiedCount,
        totalRooms: totalRooms,
      );
    });
  }

  /// Porcentaje promedio de ocupación semanal.
  double get averageOccupancyPercentage {
    final series = weeklyOccupancySeries;
    if (series.isEmpty) return 0.0;
    final sum = series.fold<double>(
      0.0,
      (acc, point) => acc + point.occupancyPercentage,
    );
    return sum / series.length;
  }

  ReportsState copyWith({
    DateTimeRange? selectedDateRange,
    List<Task>? completedTasks,
    List<Task>? activeTasks,
    List<Room>? rooms,
    List<Reservation>? reservations,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsState(
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      completedTasks: completedTasks ?? this.completedTasks,
      activeTasks: activeTasks ?? this.activeTasks,
      rooms: rooms ?? this.rooms,
      reservations: reservations ?? this.reservations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────── Notifier (Riverpod 3) ───────────────────────────

class ReportsNotifier extends Notifier<ReportsState> {
  StreamSubscription<List<Task>>? _completedSub;
  StreamSubscription<List<Task>>? _activeSub;
  bool _disposed = false;

  @override
  ReportsState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _completedSub?.cancel();
      _activeSub?.cancel();
    });

    final now = DateTime.now();
    final endDay = DateTime(now.year, now.month, now.day);
    final startDay = endDay.subtract(const Duration(days: 6));

    Future.microtask(_init);

    return ReportsState(
      selectedDateRange: DateTimeRange(start: startDay, end: endDay),
      isLoading: true,
    );
  }

  TaskRepository get _taskRepo => ref.read(taskRepositoryProvider);
  RoomsRepository get _roomsRepo => ref.read(roomsRepositoryProvider);
  ReservationsRepository get _reservationsRepo =>
      ref.read(reservationsRepositoryProvider);

  Future<void> _init() async {
    if (_disposed) return;
    _subscribeToTasks();
    await _loadRoomsAndReservations();
  }

  void _subscribeToTasks() {
    try {
      _completedSub?.cancel();
      _completedSub = _taskRepo.watchRecentlyCompletedTasks(limit: 100).listen(
        (tasks) {
          if (_disposed) return;
          state = state.copyWith(
            completedTasks: tasks,
            isLoading: false,
            clearError: true,
          );
        },
        onError: (Object e) {
          if (_disposed) return;
          state = state.copyWith(
            isLoading: false,
            errorMessage: e.toString().replaceFirst('Exception: ', ''),
          );
        },
      );

      _activeSub?.cancel();
      _activeSub = _taskRepo.watchActiveTasks().listen(
        (tasks) {
          if (_disposed) return;
          state = state.copyWith(activeTasks: tasks);
        },
        onError: (_) {},
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _loadRoomsAndReservations() async {
    try {
      final results = await Future.wait([
        _roomsRepo.getRooms(),
        _reservationsRepo.getReservations(),
      ]);
      if (_disposed) return;
      state = state.copyWith(
        rooms: results[0] as List<Room>,
        reservations: results[1] as List<Reservation>,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.completedTasks.isEmpty
            ? e.toString().replaceFirst('Exception: ', '')
            : null,
      );
    }
  }

  /// Actualiza el rango de fechas y recalcula automáticamente las métricas.
  void setDateRange(DateTimeRange range) {
    final normalizedStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final normalizedEnd = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    );
    state = state.copyWith(
      selectedDateRange: DateTimeRange(
        start: normalizedStart,
        end: normalizedEnd,
      ),
    );
  }

  /// Define un rango rápido de los últimos [days] días.
  void setPresetDays(int days, {DateTime? referenceDate}) {
    final refDate = referenceDate ?? DateTime.now();
    final end = DateTime(refDate.year, refDate.month, refDate.day);
    final start = end.subtract(Duration(days: days - 1));
    setDateRange(DateTimeRange(start: start, end: end));
  }

  /// Recarga habitaciones y reservaciones manualmente.
  Future<void> refresh() async {
    if (_disposed) return;
    final hasData = state.completedTasks.isNotEmpty || state.rooms.isNotEmpty;
    if (!hasData) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    await _loadRoomsAndReservations();
  }
}

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(
  ReportsNotifier.new,
);
