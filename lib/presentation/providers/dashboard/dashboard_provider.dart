import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';

// ───────────────────────────── Modelos ────────────────────────────────────────

/// Estadísticas de habitaciones para el Dashboard
class RoomStats {
  final int available;
  final int occupied;
  final int reserved;
  final int pendingCleaning;
  final int cleaned;
  final int maintenance;
  final int total;

  const RoomStats({
    this.available = 0,
    this.occupied = 0,
    this.reserved = 0,
    this.pendingCleaning = 0,
    this.cleaned = 0,
    this.maintenance = 0,
    this.total = 0,
  });

  int get cleaning => pendingCleaning;

  factory RoomStats.fromRooms(List<Room> rooms) {
    return RoomStats(
      available: rooms.where((r) => r.status == RoomStatus.available).length,
      occupied: rooms.where((r) => r.status == RoomStatus.occupied).length,
      reserved: rooms.where((r) => r.status == RoomStatus.reserved).length,
      pendingCleaning: rooms
          .where(
            (r) =>
                r.status == RoomStatus.pendingCleaning ||
                r.status == RoomStatus.cleaning,
          )
          .length,
      cleaned: rooms.where((r) => r.status == RoomStatus.cleaned).length,
      maintenance: rooms.where((r) => r.status == RoomStatus.outOfOrder).length,
      total: rooms.length,
    );
  }

  /// Construye las estadísticas desde el documento agregado.
  /// `pendingCleaning` suma los dos estados de limpieza, igual que
  /// [RoomStats.fromRooms], para que la tarjeta no cambie de significado.
  factory RoomStats.fromMetrics(RoomMetrics m) {
    return RoomStats(
      available: m.available,
      occupied: m.occupied,
      reserved: m.reserved,
      pendingCleaning: m.pendingCleaning + m.cleaning,
      cleaned: m.cleaned,
      maintenance: m.outOfOrder,
      total: m.total,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomStats &&
        other.available == available &&
        other.occupied == occupied &&
        other.reserved == reserved &&
        other.pendingCleaning == pendingCleaning &&
        other.cleaned == cleaned &&
        other.maintenance == maintenance &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(
        available,
        occupied,
        reserved,
        pendingCleaning,
        cleaned,
        maintenance,
        total,
      );
}

/// Alerta de actividad próxima (check-in o check-out)
class DashboardAlert {
  final String id;
  final String type; // 'checkIn' | 'checkOut'
  final String guestName;
  final String roomNumber;
  final DateTime scheduledAt;

  const DashboardAlert({
    required this.id,
    required this.type,
    required this.guestName,
    required this.roomNumber,
    required this.scheduledAt,
  });

  String get label => type == 'checkIn' ? 'Check-in' : 'Check-out';

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}

// ───────────────────────────── Estado ────────────────────────────────────────

class DashboardState {
  final RoomStats roomStats;
  final List<Task> activeTasks;
  final List<DashboardAlert> alerts;
  final List<Reservation> upcomingReservations;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.roomStats = const RoomStats(),
    this.activeTasks = const [],
    this.alerts = const [],
    this.upcomingReservations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get activeTasksCount => activeTasks.length;

  DashboardState copyWith({
    RoomStats? roomStats,
    List<Task>? activeTasks,
    List<DashboardAlert>? alerts,
    List<Reservation>? upcomingReservations,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      roomStats: roomStats ?? this.roomStats,
      activeTasks: activeTasks ?? this.activeTasks,
      alerts: alerts ?? this.alerts,
      upcomingReservations: upcomingReservations ?? this.upcomingReservations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────── Notifier ────────────────────────────────────────

class DashboardNotifier extends Notifier<DashboardState> {
  StreamSubscription<RoomMetrics>? _roomsSub;
  StreamSubscription<List<Task>>? _tasksSub;
  bool _disposed = false;
  bool _metricsRepaired = false;

  @override
  DashboardState build() {
    _disposed = false;
    _metricsRepaired = false;
    ref.onDispose(() {
      _disposed = true;
      _roomsSub?.cancel();
      _tasksSub?.cancel();
    });
    Future.microtask(_initDashboard);
    return const DashboardState(isLoading: true);
  }

  RoomsRepository get _roomsRepo => ref.read(roomsRepositoryProvider);
  ReservationsRepository get _reservationsRepo =>
      ref.read(reservationsRepositoryProvider);
  TaskRepository get _taskRepo => ref.read(taskRepositoryProvider);

  void _initDashboard() {
    if (_disposed) return;
    _subscribeToStreams();
    _loadReservationsAndAlerts();
  }

  void _subscribeToStreams() {
    _roomsSub?.cancel();
    _roomsSub = _roomsRepo.watchRoomMetrics().listen(
      (metrics) async {
        if (_disposed) return;

        // El agregado aún no existe (hotel recién dado de alta, o primera
        // ejecución). Se reconstruye una vez y el stream recoge el resultado.
        if (metrics.total == 0 && !_metricsRepaired) {
          _metricsRepaired = true;
          try {
            await _roomsRepo.recalculateRoomMetrics();
          } catch (_) {
            // Si falla, el dashboard queda en ceros y se reintenta al recargar.
          }
          return;
        }

        state = state.copyWith(
          roomStats: RoomStats.fromMetrics(metrics),
          isLoading: false,
          clearError: true,
        );
        _loadReservationsAndAlerts();
      },
      onError: (Object e) {
        if (_disposed) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      },
    );

    try {
      _tasksSub?.cancel();
      _tasksSub = _taskRepo.watchActiveTasks().listen(
        (tasks) {
          if (_disposed) return;
          state = state.copyWith(
            activeTasks: tasks,
            isLoading: false,
          );
        },
        onError: (_) {
          // Errores de stream de tareas se reflejan en el panel dedicado
        },
      );
    } catch (_) {
      // Tolerar entornos de prueba donde taskRepositoryProvider no esté disponible
    }
  }

  Future<void> _loadReservationsAndAlerts() async {
    try {
      final reservations = await _reservationsRepo.getReservations();
      if (_disposed) return;

      // Reservaciones próximas (activas en los próximos 2 días)
      final now = DateTime.now();
      final upcoming = reservations.where((r) {
        final isActive =
            r.status == ReservationStatus.confirmed ||
            r.status == ReservationStatus.checkedIn;
        final isNear =
            r.checkIn.isBefore(now.add(const Duration(days: 2))) ||
            r.checkOut.isBefore(now.add(const Duration(days: 2)));
        return isActive && isNear;
      }).toList()..sort((a, b) => a.checkIn.compareTo(b.checkIn));

      // Genera alertas a partir de reservaciones próximas
      final alerts = <DashboardAlert>[];
      for (final res in reservations) {
        // Alerta de check-in próximo (confirmadas)
        if (res.status == ReservationStatus.confirmed) {
          final diff = res.checkIn.difference(now);
          if (diff.inDays <= 1 && diff.inDays >= 0) {
            alerts.add(
              DashboardAlert(
                id: 'ci-${res.id}',
                type: 'checkIn',
                guestName: res.guestName,
                roomNumber: res.roomNumber.toString(),
                scheduledAt: res.checkIn,
              ),
            );
          }
        }
        // Alerta de check-out próximo (huéspedes adentro)
        if (res.status == ReservationStatus.checkedIn) {
          final diff = res.checkOut.difference(now);
          if (diff.inDays <= 1 && diff.inDays >= 0) {
            alerts.add(
              DashboardAlert(
                id: 'co-${res.id}',
                type: 'checkOut',
                guestName: res.guestName,
                roomNumber: res.roomNumber.toString(),
                scheduledAt: res.checkOut,
              ),
            );
          }
        }
      }

      if (_disposed) return;
      state = state.copyWith(
        upcomingReservations: upcoming,
        alerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      if (_disposed) return;
      if (state.roomStats.total == 0) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Carga/refresca todas las estadísticas y alertas del dashboard
  Future<void> loadDashboard() async {
    if (_disposed) return;
    final hasExistingData =
        state.roomStats.total > 0 || state.activeTasks.isNotEmpty;
    if (!hasExistingData) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }
    _subscribeToStreams();
    await _loadReservationsAndAlerts();
  }
}

/// Provider del Dashboard
final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
