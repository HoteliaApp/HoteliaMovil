import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/datasource/subscription_datasource_impl.dart';
import 'package:hotel_app/infrastructure/repositories/subscription_repository_impl.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';

// ─────────────────────────── Inyección de dependencias ────────────────────────

final subscriptionDataSourceProvider = Provider<SubscriptionDataSource>((ref) {
  return SubscriptionDataSourceImpl();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final dataSource = ref.watch(subscriptionDataSourceProvider);
  return SubscriptionRepositoryImpl(dataSource);
});

// ─────────────────────────── Stream del Hotel Activo ──────────────────────────

final currentHotelStreamProvider = StreamProvider.autoDispose<Hotel>((ref) {
  final hotelId = ref.watch(currentHotelIdProvider);
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchHotelSubscription(hotelId);
});

// ─────────────────────────── Estado de la Suscripción ─────────────────────────

/// Provider computado que combina en tiempo real:
/// 1. El documento del hotel (plan contratado y límites)
/// 2. El conteo reactivo de habitaciones activas del hotel
/// 3. El conteo reactivo de usuarios/empleados del hotel
final hotelSubscriptionProvider = Provider<HotelSubscription>((ref) {
  final hotelAsync = ref.watch(currentHotelStreamProvider);
  final roomsState = ref.watch(roomsProvider);
  final employeesAsync = ref.watch(employeesStreamProvider);
  final hotelId = ref.watch(currentHotelIdProvider);

  final hotel = hotelAsync.asData?.value ??
      Hotel(
        id: hotelId,
        name: 'Hotel Hotelia',
        floors: 3,
        address: '',
        createdAt: DateTime.now(),
        plan: 'basic',
      );

  final currentRooms = roomsState.rooms.length;
  final currentUsers = employeesAsync.asData?.value.length ?? 1;

  return HotelSubscription(
    hotelId: hotel.id,
    plan: hotel.plan,
    maxRooms: hotel.maxRooms,
    maxUsers: hotel.maxUsers,
    currentRooms: currentRooms,
    currentUsers: currentUsers,
    requestedPlan: hotel.requestedPlan,
    planChangeRequestedAt: hotel.planChangeRequestedAt,
  );
});

// ─────────────────────────── Notifier de Acciones ─────────────────────────────

class SubscriptionActionState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SubscriptionActionState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SubscriptionActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SubscriptionActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SubscriptionActionNotifier extends Notifier<SubscriptionActionState> {
  @override
  SubscriptionActionState build() => const SubscriptionActionState();

  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  Future<void> requestPlanChange(String newPlan, {String? notes}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final hotelId = ref.read(currentHotelIdProvider);
      await _repository.requestPlanChange(hotelId, newPlan, notes: notes);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final subscriptionActionProvider =
    NotifierProvider<SubscriptionActionNotifier, SubscriptionActionState>(
  SubscriptionActionNotifier.new,
);
