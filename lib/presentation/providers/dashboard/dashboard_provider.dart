import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';

// ───────────────────────────── Modelos ────────────────────────────────────────

/// Estadísticas de habitaciones para el Dashboard
class RoomStats {
  final int available;
  final int occupied;
  final int reserved;
  final int maintenance;
  final int total;

  const RoomStats({
    this.available = 0,
    this.occupied = 0,
    this.reserved = 0,
    this.maintenance = 0,
    this.total = 0,
  });
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
  final List<DashboardAlert> alerts;
  final List<Reservation> upcomingReservations;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.roomStats = const RoomStats(),
    this.alerts = const [],
    this.upcomingReservations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    RoomStats? roomStats,
    List<DashboardAlert>? alerts,
    List<Reservation>? upcomingReservations,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      roomStats: roomStats ?? this.roomStats,
      alerts: alerts ?? this.alerts,
      upcomingReservations: upcomingReservations ?? this.upcomingReservations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────── Notifier ────────────────────────────────────────

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(loadDashboard);
    return const DashboardState();
  }

  RoomsRepository get _roomsRepo => ref.read(roomsRepositoryProvider);
  ReservationsRepository get _reservationsRepo =>
      ref.read(reservationsRepositoryProvider);

  /// Carga todas las estadísticas y alertas del dashboard
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _roomsRepo.getRooms(),
        _reservationsRepo.getReservations(),
      ]);

      final rooms = results[0] as List<Room>;
      final reservations = results[1] as List<Reservation>;

      // Estadísticas de habitaciones
      final stats = RoomStats(
        available: rooms.where((r) => r.status == RoomStatus.available).length,
        occupied: rooms.where((r) => r.status == RoomStatus.occupied).length,
        reserved: rooms.where((r) => r.status == RoomStatus.reserved).length,
        maintenance:
            rooms.where((r) => r.status == RoomStatus.outOfOrder).length,
        total: rooms.length,
      );

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

      state = state.copyWith(
        roomStats: stats,
        upcomingReservations: upcoming,
        alerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Provider del Dashboard
final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
