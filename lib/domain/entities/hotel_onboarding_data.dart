import 'package:hotel_app/domain/entities/hotel.dart';
import 'package:hotel_app/domain/entities/room.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';

/// Configuración de habitaciones para un piso específico dentro del wizard.
class FloorConfig {
  final int floorNumber;
  final int roomCount;
  final RoomType roomType;
  final double pricePerNight;
  final int capacity;
  final List<String> amenities;

  const FloorConfig({
    required this.floorNumber,
    this.roomCount = 4,
    this.roomType = RoomType.single,
    this.pricePerNight = 50.0,
    this.capacity = 2,
    this.amenities = const ['WiFi', 'TV', 'AC'],
  });

  FloorConfig copyWith({
    int? floorNumber,
    int? roomCount,
    RoomType? roomType,
    double? pricePerNight,
    int? capacity,
    List<String>? amenities,
  }) {
    return FloorConfig(
      floorNumber: floorNumber ?? this.floorNumber,
      roomCount: roomCount ?? this.roomCount,
      roomType: roomType ?? this.roomType,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
    );
  }

  /// Genera las habitaciones concretas para este piso con la numeración estándar
  /// (ej. Piso 1: 101, 102... Piso 2: 201, 202...).
  List<Room> generateRooms(String hotelId) {
    final rooms = <Room>[];
    for (int i = 1; i <= roomCount; i++) {
      final roomNumber = (floorNumber * 100) + i;
      final roomId = 'room-$roomNumber-$hotelId';
      rooms.add(
        Room(
          id: roomId,
          roomNumber: roomNumber,
          roomType: roomType,
          status: RoomStatus.available,
          pricePerNight: pricePerNight,
          description: 'Habitación ${roomType.label} - Piso $floorNumber',
          images: [RoomModel.defaultRoomImageUrl(roomNumber)],
          capacity: capacity,
          amenities: List.from(amenities),
          hotelId: hotelId,
        ),
      );
    }
    return rooms;
  }
}

/// Usuario inicial que el dueño da de alta en el paso 3 del wizard.
class InitialStaffUser {
  final String name;
  final String email;
  final UserRole role;

  const InitialStaffUser({
    required this.name,
    required this.email,
    required this.role,
  });

  InitialStaffUser copyWith({
    String? name,
    String? email,
    UserRole? role,
  }) {
    return InitialStaffUser(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

/// Paquete completo de datos recolectados por el Wizard de Onboarding.
class HotelOnboardingData {
  final Hotel hotel;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final List<FloorConfig> floors;
  final List<InitialStaffUser> initialStaff;

  const HotelOnboardingData({
    required this.hotel,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.floors,
    this.initialStaff = const [],
  });

  /// Todas las habitaciones generadas para el hotel agregando todos los pisos.
  List<Room> get allRooms {
    final list = <Room>[];
    for (final floor in floors) {
      list.addAll(floor.generateRooms(hotel.id));
    }
    return list;
  }
}
