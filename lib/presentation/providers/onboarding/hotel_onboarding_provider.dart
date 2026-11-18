import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/datasource/hotel_onboarding_datasource_impl.dart';
import 'package:hotel_app/infrastructure/repositories/hotel_onboarding_repository_impl.dart';

// ─────────────────────────── Inyección de dependencias ────────────────────────

final hotelOnboardingDataSourceProvider =
    Provider<HotelOnboardingDataSource>((ref) {
  return HotelOnboardingDataSourceImpl();
});

final hotelOnboardingRepositoryProvider =
    Provider<HotelOnboardingRepository>((ref) {
  final dataSource = ref.watch(hotelOnboardingDataSourceProvider);
  return HotelOnboardingRepositoryImpl(dataSource);
});

// ─────────────────────────── Estado del Wizard ────────────────────────────────

class HotelOnboardingState {
  final int currentStep;
  final String hotelName;
  final String hotelAddress;
  final int floorsCount;
  final String plan; // 'basic' | 'standard' | 'premium'
  final String hotelId;
  final bool isCustomHotelId;
  final List<FloorConfig> floorsConfig;
  final List<InitialStaffUser> staffList;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const HotelOnboardingState({
    this.currentStep = 0,
    this.hotelName = '',
    this.hotelAddress = '',
    this.floorsCount = 3,
    this.plan = 'standard',
    this.hotelId = '',
    this.isCustomHotelId = false,
    this.floorsConfig = const [],
    this.staffList = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  HotelOnboardingState copyWith({
    int? currentStep,
    String? hotelName,
    String? hotelAddress,
    int? floorsCount,
    String? plan,
    String? hotelId,
    bool? isCustomHotelId,
    List<FloorConfig>? floorsConfig,
    List<InitialStaffUser>? staffList,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return HotelOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      hotelName: hotelName ?? this.hotelName,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      floorsCount: floorsCount ?? this.floorsCount,
      plan: plan ?? this.plan,
      hotelId: hotelId ?? this.hotelId,
      isCustomHotelId: isCustomHotelId ?? this.isCustomHotelId,
      floorsConfig: floorsConfig ?? this.floorsConfig,
      staffList: staffList ?? this.staffList,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  int get totalRoomsCount =>
      floorsConfig.fold(0, (prev, floor) => prev + floor.roomCount);
}

// ─────────────────────────── Notifier del Wizard ─────────────────────────────

class HotelOnboardingNotifier extends Notifier<HotelOnboardingState> {
  @override
  HotelOnboardingState build() {
    final initialFloors = _generateInitialFloors(3);
    return HotelOnboardingState(
      floorsCount: 3,
      floorsConfig: initialFloors,
      staffList: const [
        InitialStaffUser(
          name: 'Recepción Central',
          email: 'recepcion@hotel.com',
          role: UserRole.receptionist,
        ),
      ],
    );
  }

  HotelOnboardingRepository get _repository =>
      ref.read(hotelOnboardingRepositoryProvider);

  static List<FloorConfig> _generateInitialFloors(int count) {
    return List.generate(count, (index) {
      final floorNum = index + 1;
      final type = switch (floorNum) {
        1 => RoomType.single,
        2 => RoomType.double,
        3 => RoomType.suite,
        _ => RoomType.deluxe,
      };
      final price = switch (type) {
        RoomType.single => 50.0,
        RoomType.double => 80.0,
        RoomType.suite => 150.0,
        RoomType.deluxe => 120.0,
        RoomType.penthouse => 300.0,
      };
      final capacity = switch (type) {
        RoomType.single => 1,
        RoomType.double => 2,
        RoomType.suite => 4,
        RoomType.deluxe => 3,
        RoomType.penthouse => 6,
      };
      final amenities = switch (type) {
        RoomType.single => ['WiFi', 'TV'],
        RoomType.double => ['WiFi', 'TV', 'AC'],
        RoomType.suite => ['WiFi', 'TV', 'AC', 'Minibar', 'Jacuzzi'],
        RoomType.deluxe => ['WiFi', 'TV', 'AC', 'Minibar'],
        RoomType.penthouse => ['WiFi', 'TV', 'AC', 'Minibar', 'Jacuzzi', 'Terraza'],
      };

      return FloorConfig(
        floorNumber: floorNum,
        roomCount: 4,
        roomType: type,
        pricePerNight: price,
        capacity: capacity,
        amenities: amenities,
      );
    });
  }

  /// Genera un identificador canónico slug multi-tenant a partir del nombre comercial.
  static String generateHotelIdSlug(String name) {
    if (name.trim().isEmpty) return '';
    var slug = name.trim().toLowerCase();
    slug = slug.replaceAll(RegExp(r'[áàäâ]'), 'a');
    slug = slug.replaceAll(RegExp(r'[éèëê]'), 'e');
    slug = slug.replaceAll(RegExp(r'[íìïî]'), 'i');
    slug = slug.replaceAll(RegExp(r'[óòöô]'), 'o');
    slug = slug.replaceAll(RegExp(r'[úùüû]'), 'u');
    slug = slug.replaceAll(RegExp(r'[ñ]'), 'n');
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    slug = slug.replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty) return 'hotel_${DateTime.now().millisecondsSinceEpoch}';
    return slug.startsWith('hotel_') ? slug : 'hotel_$slug';
  }

  void setHotelName(String name) {
    final nextState = state.copyWith(
      hotelName: name,
      hotelId: state.isCustomHotelId
          ? state.hotelId
          : generateHotelIdSlug(name),
      errorMessage: null,
    );
    state = nextState;
  }

  void setHotelAddress(String address) {
    state = state.copyWith(hotelAddress: address, errorMessage: null);
  }

  void setPlan(String plan) {
    state = state.copyWith(plan: plan, errorMessage: null);
  }

  void setCustomHotelId(String id) {
    state = state.copyWith(
      hotelId: id.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_'),
      isCustomHotelId: true,
      errorMessage: null,
    );
  }

  void setFloorsCount(int count) {
    if (count < 1) return;
    final current = List<FloorConfig>.from(state.floorsConfig);
    if (count > current.length) {
      for (int i = current.length + 1; i <= count; i++) {
        current.add(
          FloorConfig(
            floorNumber: i,
            roomCount: 4,
            roomType: RoomType.double,
            pricePerNight: 80.0,
            capacity: 2,
            amenities: const ['WiFi', 'TV', 'AC'],
          ),
        );
      }
    } else if (count < current.length) {
      current.removeRange(count, current.length);
    }

    state = state.copyWith(
      floorsCount: count,
      floorsConfig: current,
      errorMessage: null,
    );
  }

  void updateFloorConfig(int floorIndex, FloorConfig config) {
    if (floorIndex < 0 || floorIndex >= state.floorsConfig.length) return;
    final updated = List<FloorConfig>.from(state.floorsConfig);
    updated[floorIndex] = config;
    state = state.copyWith(floorsConfig: updated, errorMessage: null);
  }

  void applyQuickPreset() {
    state = state.copyWith(
      floorsConfig: _generateInitialFloors(state.floorsCount),
      errorMessage: null,
    );
  }

  void addStaff(InitialStaffUser staff) {
    final updated = List<InitialStaffUser>.from(state.staffList)..add(staff);
    state = state.copyWith(staffList: updated, errorMessage: null);
  }

  void removeStaff(int index) {
    if (index < 0 || index >= state.staffList.length) return;
    final updated = List<InitialStaffUser>.from(state.staffList)..removeAt(index);
    state = state.copyWith(staffList: updated, errorMessage: null);
  }

  bool validateCurrentStep() {
    if (state.currentStep == 0) {
      if (state.hotelName.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'Ingresa el nombre del hotel.');
        return false;
      }
      if (state.hotelAddress.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'Ingresa la dirección del hotel.');
        return false;
      }
      if (state.floorsCount < 1) {
        state = state.copyWith(errorMessage: 'El hotel debe tener al menos 1 piso.');
        return false;
      }
      if (state.hotelId.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'El identificador del hotel es obligatorio.');
        return false;
      }
    } else if (state.currentStep == 1) {
      if (state.floorsConfig.isEmpty) {
        state = state.copyWith(errorMessage: 'Configura al menos un piso.');
        return false;
      }
      for (final floor in state.floorsConfig) {
        if (floor.roomCount < 1) {
          state = state.copyWith(
            errorMessage: 'El piso ${floor.floorNumber} debe tener al menos 1 habitación.',
          );
          return false;
        }
        if (floor.pricePerNight <= 0) {
          state = state.copyWith(
            errorMessage: 'El precio por noche del piso ${floor.floorNumber} debe ser mayor a 0.',
          );
          return false;
        }
      }
    }
    state = state.copyWith(errorMessage: null);
    return true;
  }

  void nextStep() {
    if (!validateCurrentStep()) return;
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1, errorMessage: null);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, errorMessage: null);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      if (step > state.currentStep && !validateCurrentStep()) return;
      state = state.copyWith(currentStep: step, errorMessage: null);
    }
  }

  Future<void> submitOnboarding({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    if (!validateCurrentStep()) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final hotel = Hotel(
        id: state.hotelId.trim(),
        name: state.hotelName.trim(),
        floors: state.floorsCount,
        address: state.hotelAddress.trim(),
        createdAt: DateTime.now(),
        plan: state.plan,
        schemaVersion: Hotel.currentSchemaVersion,
      );

      final onboardingData = HotelOnboardingData(
        hotel: hotel,
        ownerId: ownerId,
        ownerName: ownerName.isEmpty ? 'Propietario Hotel' : ownerName,
        ownerEmail: ownerEmail,
        floors: state.floorsConfig,
        initialStaff: state.staffList,
      );

      await _repository.submitOnboarding(onboardingData);

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final hotelOnboardingProvider =
    NotifierProvider<HotelOnboardingNotifier, HotelOnboardingState>(
  HotelOnboardingNotifier.new,
);
