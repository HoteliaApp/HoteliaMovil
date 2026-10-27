import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/infraestructure.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/dashboard/dashboard_provider.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';

// ─────────────────────────── Infraestructura ────────────────────────────────

final reservationsDataSourceProvider = Provider<ReservationsDataSource>((ref) {
  return ReservationsDataSourceImpl(FirebaseFirestore.instance);
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepositoryImpl(ref.watch(reservationsDataSourceProvider));
});

// ───────────────────────────── Estado ────────────────────────────────────────

class CheckInOutState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Reservation? updatedReservation;

  const CheckInOutState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.updatedReservation,
  });

  CheckInOutState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Reservation? updatedReservation,
    bool clearMessages = false,
  }) {
    return CheckInOutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessages ? null : successMessage ?? this.successMessage,
      updatedReservation: updatedReservation ?? this.updatedReservation,
    );
  }
}

// ─────────────────────────── Notifier (Riverpod 3) ───────────────────────────

class CheckInOutNotifier extends Notifier<CheckInOutState> {
  @override
  CheckInOutState build() => const CheckInOutState();

  ReservationsRepository get _reservationsRepo =>
      ref.read(reservationsRepositoryProvider);

  RoomsRepository get _roomsRepo => ref.read(roomsRepositoryProvider);

  TaskRepository get _taskRepo => ref.read(taskRepositoryProvider);

  /// Invalida todos los providers afectados por un cambio de estado.
  void _invalidateAll() {
    ref.invalidate(roomsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(activeTasksProvider);
  }

  // ── Check-in ──────────────────────────────────────────────────────────────

  /// Realiza el check-in de una reservación.
  /// 
  /// [reservationId] — ID de la reservación a actualizar.
  /// [roomId]        — ID de la habitación (para actualizar su estado a "ocupada").
  Future<bool> performCheckIn(
    String reservationId,
    String roomId, {
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      // Obtener reservacion y habitacion actual
      final currentReservation = await _reservationsRepo.getReservationById(reservationId);
      final room = await _roomsRepo.getRoomById(roomId);

      if (currentReservation.status == ReservationStatus.cancelled) {
        throw Exception('No se puede realizar check-in de una reservación cancelada.');
      }
      if (room.status == RoomStatus.pendingCleaning || room.status == RoomStatus.cleaning) {
        throw Exception('No se puede asignar una habitación que requiere limpieza.');
      }
      if (room.status != RoomStatus.available && room.status != RoomStatus.reserved) {
        throw Exception('No se puede realizar check-in en una habitación no disponible u ocupada.');
      }

      // 1. Actualiza el estado de la reservación
      final reservation = await _reservationsRepo.checkIn(
        reservationId: reservationId,
        guestName: guestName,
        companions: companions,
        expectedCheckOut: expectedCheckOut,
      );

      // 2. Actualiza el estado de la habitación a "Ocupada"
      await _roomsRepo.updateRoomStatus(roomId, RoomStatus.occupied);

      // 3. Refresca habitaciones, dashboard y tareas en toda la app
      _invalidateAll();

      state = state.copyWith(
        isLoading: false,
        updatedReservation: reservation,
        successMessage: 'Check-in realizado. Habitación marcada como ocupada.',
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

  // ── Check-out ─────────────────────────────────────────────────────────────

  /// Realiza el check-out de una reservación y genera automáticamente
  /// una tarea de limpieza en Firestore para el wearable.
  /// 
  /// [reservationId] — ID de la reservación a cerrar.
  /// [roomId]        — ID de la habitación (para actualizar su estado a "disponible").
  /// [guestName]     — Nombre del huésped (incluido en la descripción de la tarea).
  Future<bool> performCheckOut(
    String reservationId,
    String roomId,
    String guestName,
  ) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      // Validar que se haya hecho check-in primero
      final currentReservation = await _reservationsRepo.getReservationById(reservationId);
      if (currentReservation.status != ReservationStatus.checkedIn) {
        throw Exception('No se puede realizar check-out de una reservación que no tiene check-in.');
      }

      // 1. Actualiza el estado de la reservación
      final reservation = await _reservationsRepo.checkOut(reservationId);

      // 2. Obtiene los datos completos de la habitación (necesita roomNumber real)
      final room = await _roomsRepo.getRoomById(roomId);

      // 3. Actualiza el estado de la habitación a "Pendiente Limpieza"
      await _roomsRepo.updateRoomStatus(roomId, RoomStatus.pendingCleaning);

      // 4. Publica tarea de limpieza en el repositorio → el wearable la recibe
      await _taskRepo.createCleaningTask(
        roomId: roomId,
        roomNumber: room.roomNumber,
        guestName: guestName,
      );

      // 5. Refresca habitaciones, dashboard y tareas en toda la app
      _invalidateAll();

      state = state.copyWith(
        isLoading: false,
        updatedReservation: reservation,
        successMessage:
            'Check-out realizado. Tarea de limpieza enviada al wearable.',
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

  void clearMessages() => state = state.copyWith(clearMessages: true);
}

/// Provider del manejo de check-in y check-out
final checkInOutProvider =
    NotifierProvider<CheckInOutNotifier, CheckInOutState>(
  CheckInOutNotifier.new,
);
