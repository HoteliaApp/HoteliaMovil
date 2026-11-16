/// Tipos de habitación disponibles en el hotel
enum RoomType {
  single,
  double,
  suite,
  deluxe,
  penthouse;

  String get label => switch (this) {
        RoomType.single => 'Sencilla',
        RoomType.double => 'Doble',
        RoomType.suite => 'Suite',
        RoomType.deluxe => 'Deluxe',
        RoomType.penthouse => 'Penthouse',
      };
}

/// Estados posibles de una habitación
enum RoomStatus {
  available,
  reserved,
  occupied,
  pendingCleaning,
  cleaning,
  cleaned,
  outOfOrder;

  String get label => switch (this) {
        RoomStatus.available => 'Disponible',
        RoomStatus.reserved => 'Reservada',
        RoomStatus.occupied => 'Ocupada',
        RoomStatus.pendingCleaning => 'Pendiente Limpieza',
        RoomStatus.cleaning => 'En Limpieza',
        RoomStatus.cleaned => 'Limpia',
        RoomStatus.outOfOrder => 'Fuera de Servicio',
      };
}

/// Entidad Room — representa una habitación del hotel en la capa de dominio.
/// Es independiente de la fuente de datos (API o local).
class Room {
  final String id;
  final int roomNumber;
  final RoomType roomType;
  final RoomStatus status;
  final double pricePerNight;
  final String description;
  final List<String> images;
  final int capacity;
  final List<String> amenities;
  final String hotelId;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.status,
    required this.pricePerNight,
    required this.description,
    required this.images,
    required this.capacity,
    required this.amenities,
    this.hotelId = 'hotel_101',
  });

  /// Retorna true si la habitación está disponible para reservar
  bool get isAvailable => status == RoomStatus.available;

  /// Crea una copia de la entidad con los campos modificados
  Room copyWith({
    String? id,
    int? roomNumber,
    RoomType? roomType,
    RoomStatus? status,
    double? pricePerNight,
    String? description,
    List<String>? images,
    int? capacity,
    List<String>? amenities,
    String? hotelId,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      status: status ?? this.status,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      description: description ?? this.description,
      images: images ?? this.images,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      hotelId: hotelId ?? this.hotelId,
    );
  }

  @override
  String toString() =>
      'Room(id: $id, number: $roomNumber, hotelId: $hotelId, type: ${roomType.label}, status: ${status.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Room && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
