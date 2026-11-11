import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/infraestructure.dart';



// ─────────────────────────── Infraestructura ────────────────────────────────

final roomsDataSourceProvider = Provider<RoomsDataSource>((ref) {
  final dataSource = RoomsDataSourceImpl(FirebaseFirestore.instance);
  // Se siembran los cuartos de manera asíncrona (fuego y olvido)
  dataSource.seedRoomsIfEmpty().catchError((_) {});
  return dataSource;
});

/// Provider del repositorio de habitaciones
final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepositoryImpl(ref.watch(roomsDataSourceProvider));
});

// ───────────────────────────── Estado ────────────────────────────────────────

/// Estado del listado de habitaciones
class RoomsState {
  final List<Room> rooms;
  final bool isLoading;
  final String? errorMessage;
  final RoomStatus? selectedStatus;
  final RoomType? selectedType;
  final int? selectedCapacity;

  const RoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatus,
    this.selectedType,
    this.selectedCapacity,
  });

  RoomsState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    String? errorMessage,
    RoomStatus? selectedStatus,
    RoomType? selectedType,
    int? selectedCapacity,
    bool clearError = false,
    bool clearStatus = false,
    bool clearType = false,
    bool clearCapacity = false,
  }) {
    return RoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedStatus:
          clearStatus ? null : selectedStatus ?? this.selectedStatus,
      selectedType: clearType ? null : selectedType ?? this.selectedType,
      selectedCapacity:
          clearCapacity ? null : selectedCapacity ?? this.selectedCapacity,
    );
  }
}

// ─────────────────────────── Notifier (Riverpod 3) ───────────────────────────

class RoomsNotifier extends Notifier<RoomsState> {
  @override
  RoomsState build() {
    // Suscribe al stream reactivo al construirse; cancela automáticamente
    // cuando el provider se descarte.
    _subscribeToStream();
    return const RoomsState(isLoading: true);
  }

  RoomsRepository get _repository => ref.read(roomsRepositoryProvider);

  /// Suscripción activa al stream de Firestore
  void _subscribeToStream() {
    final stream = _repository.watchRooms(
      status: state.selectedStatus,
      type: state.selectedType,
    );

    // ref.onDispose cancela la suscripción cuando el provider muere
    final subscription = stream.listen(
      (rooms) {
        final filtered = state.selectedCapacity != null
            ? rooms.where((r) => r.capacity >= state.selectedCapacity!).toList()
            : rooms;
        state = state.copyWith(rooms: filtered, isLoading: false, clearError: true);
      },
      onError: (Object e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      },
    );

    ref.onDispose(subscription.cancel);
  }

  /// Re-suscribe al stream aplicando los filtros activos del estado
  void _resubscribe() {
    // Reinicia la carga y vuelve a suscribirse con los nuevos filtros
    state = state.copyWith(isLoading: true, clearError: true);
    _subscribeToStream();
  }

  /// Refresco manual (Pull-to-refresh): fuerza re-suscripción
  Future<void> loadRooms() async {
    _resubscribe();
  }

  /// Cambia el filtro de estado y re-suscribe
  Future<void> filterByStatus(RoomStatus? status) async {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    _resubscribe();
  }

  /// Cambia el filtro de tipo y re-suscribe
  Future<void> filterByType(RoomType? type) async {
    state = state.copyWith(
      selectedType: type,
      clearType: type == null,
    );
    _resubscribe();
  }

  /// Limpia todos los filtros y re-suscribe
  Future<void> clearFilters() async {
    state = state.copyWith(clearStatus: true, clearType: true, clearCapacity: true);
    _resubscribe();
  }

  /// Cambia el filtro de capacidad mínima.
  /// El filtro de capacidad se aplica en cliente sobre el stream actual,
  /// por lo que no requiere re-suscripción, solo actualizar el estado.
  Future<void> filterByCapacity(int? capacity) async {
    state = state.copyWith(
      selectedCapacity: capacity,
      clearCapacity: capacity == null,
    );
    // Re-suscribimos para que el listener aplique el nuevo filtro de capacidad
    _resubscribe();
  }

  /// Actualiza el estado de una habitación directamente en Firestore.
  /// El stream se encargará de reflejar el cambio automáticamente.
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _repository.updateRoomStatus(roomId, status);
      // No necesitamos recargar manualmente: Firestore notificará al stream
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Provider del listado de habitaciones
final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(
  RoomsNotifier.new,
);
