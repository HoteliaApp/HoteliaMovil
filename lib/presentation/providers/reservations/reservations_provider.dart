import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';

// ───────────────────────────── Estado ────────────────────────────────────────

class ReservationsState {
  final List<Reservation> reservations;
  final bool isLoading;
  final String? errorMessage;
  final ReservationStatus? selectedStatus;

  const ReservationsState({
    this.reservations = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatus,
  });

  ReservationsState copyWith({
    List<Reservation>? reservations,
    bool? isLoading,
    String? errorMessage,
    ReservationStatus? selectedStatus,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return ReservationsState(
      reservations: reservations ?? this.reservations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedStatus:
          clearStatus ? null : selectedStatus ?? this.selectedStatus,
    );
  }
}

// ─────────────────────────── Notifier (Riverpod 3) ───────────────────────────

class ReservationsNotifier extends Notifier<ReservationsState> {
  @override
  ReservationsState build() {
    Future.microtask(loadReservations);
    return const ReservationsState();
  }

  ReservationsRepository get _repository =>
      ref.read(reservationsRepositoryProvider);

  /// Carga la lista de reservaciones con filtro de estado opcional
  Future<void> loadReservations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reservations = await _repository.getReservations(
        status: state.selectedStatus,
      );
      state = state.copyWith(reservations: reservations, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Filtra por estado de reservación y recarga
  Future<void> filterByStatus(ReservationStatus? status) async {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    await loadReservations();
  }

  /// Verifica si una habitación tiene conflicto de fechas en el listado cargado en memoria.
  Reservation? findOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    final start = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final end = DateTime(checkOut.year, checkOut.month, checkOut.day);

    for (final r in state.reservations) {
      if (r.roomId == roomId &&
          r.status != ReservationStatus.cancelled &&
          r.status != ReservationStatus.completed) {
        final rStart = DateTime(r.checkIn.year, r.checkIn.month, r.checkIn.day);
        final rEnd = DateTime(r.checkOut.year, r.checkOut.month, r.checkOut.day);

        if (start.isBefore(rEnd) && end.isAfter(rStart)) {
          return r;
        }
      }
    }
    return null;
  }

  /// Consulta al repositorio si existe alguna reservación empalmada en la base de datos.
  Future<Reservation?> checkOverlappingInRepository({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    return _repository.getOverlappingReservation(
      roomId: roomId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  /// Crea una nueva reservación
  Future<bool> createReservation(CreateReservationParams params) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reservation = await _repository.createReservation(params);
      
      // Actualizar estado de la habitación
      await ref.read(roomsProvider.notifier).updateRoomStatus(params.roomId, RoomStatus.reserved);
      
      state = state.copyWith(
        reservations: [...state.reservations, reservation],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Cancela una reservación existente
  Future<bool> cancelReservation(String reservationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.cancelReservation(reservationId);
      final updatedList = state.reservations.map((r) {
        return r.id == reservationId ? updated : r;
      }).toList();
      state = state.copyWith(reservations: updatedList, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Provider del listado de reservaciones
final reservationsProvider =
    NotifierProvider<ReservationsNotifier, ReservationsState>(
  ReservationsNotifier.new,
);
