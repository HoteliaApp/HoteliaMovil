import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    // Carga inicial al construirse
    Future.microtask(loadRooms);
    return const RoomsState();
  }

  RoomsRepository get _repository => ref.read(roomsRepositoryProvider);

  /// Carga la lista de habitaciones aplicando filtros activos
  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var rooms = await _repository.getRooms(
        status: state.selectedStatus,
        type: state.selectedType,
      );
      // Filtro de capacidad aplicado en cliente
      if (state.selectedCapacity != null) {
        rooms = rooms
            .where((r) => r.capacity >= state.selectedCapacity!)
            .toList();
      }
      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cambia el filtro de estado y recarga
  Future<void> filterByStatus(RoomStatus? status) async {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    await loadRooms();
  }

  /// Cambia el filtro de tipo y recarga
  Future<void> filterByType(RoomType? type) async {
    state = state.copyWith(
      selectedType: type,
      clearType: type == null,
    );
    await loadRooms();
  }

  /// Limpia todos los filtros y recarga
  Future<void> clearFilters() async {
    state = state.copyWith(
        clearStatus: true, clearType: true, clearCapacity: true);
    await loadRooms();
  }

  /// Cambia el filtro de capacidad mínima y recarga
  Future<void> filterByCapacity(int? capacity) async {
    state = state.copyWith(
      selectedCapacity: capacity,
      clearCapacity: capacity == null,
    );
    await loadRooms();
  }

  /// Actualiza el estado de una habitación
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.updateRoomStatus(roomId, status);
      await loadRooms();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Provider del listado de habitaciones
final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(
  RoomsNotifier.new,
);
