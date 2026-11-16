import 'package:hotel_app/domain/domain.dart';

/// Modelo de datos de Habitación para la capa de infraestructura.
/// Maneja la serialización/deserialización JSON del API.
class RoomModel {
  final String id;
  final int roomNumber;
  final String roomType;
  final String status;
  final double pricePerNight;
  final String description;
  final List<String> images;
  final int capacity;
  final List<String> amenities;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.status,
    required this.pricePerNight,
    required this.description,
    required this.images,
    required this.capacity,
    required this.amenities,
  });

  /// Formatea o sanitiza URLs de ImageKit para asegurar que no fallen
  /// por límites de resolución (ej. imágenes > 25MP como la 402 que de otro modo devuelven 400 Bad Request).
  static String formatImageUrl(String url) {
    if (url.contains('ik.imagekit.io') && !url.contains('tr=')) {
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}tr=orig-true';
    }
    return url;
  }

  /// Genera la URL de la imagen en ImageKit según el número de habitación.
  /// Mapea habitaciones (ej. 1 -> 101, 101 -> 101, 102 -> 102, etc.)
  static String defaultRoomImageUrl(int roomNumber) {
    final num = roomNumber < 100 ? (100 + roomNumber) : roomNumber;
    return 'https://ik.imagekit.io/d83oh5gvmn/Hotel%20App/$num.jpg?tr=orig-true';
  }

  /// Construye un [RoomModel] desde un mapa JSON del API
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final roomNum = (json['roomNumber'] ?? json['room_number'] ?? 0) as int;
    final rawImages = List<String>.from(json['images'] ?? []);
    final images = rawImages.isNotEmpty
        ? rawImages.map(formatImageUrl).toList()
        : [defaultRoomImageUrl(roomNum)];

    return RoomModel(
      id: json['id']?.toString() ?? '',
      roomNumber: roomNum,
      roomType: json['roomType'] ?? json['room_type'] ?? 'single',
      status: json['status'] ?? 'available',
      pricePerNight: (json['pricePerNight'] ?? json['price_per_night'] ?? 0)
          .toDouble(),
      description: json['description'] ?? '',
      images: images,
      capacity: (json['capacity'] ?? 1) as int,
      amenities: List<String>.from(json['amenities'] ?? []),
    );
  }

  /// Serializa el modelo a un mapa JSON para enviar al API
  Map<String, dynamic> toJson() => {
    'id': id,
    'roomNumber': roomNumber,
    'roomType': roomType,
    'status': status,
    'pricePerNight': pricePerNight,
    'description': description,
    'images': images,
    'capacity': capacity,
    'amenities': amenities,
  };

  /// Convierte el [RoomModel] a la entidad de dominio [Room]
  Room toEntity() {
    return Room(
      id: id,
      roomNumber: roomNumber,
      roomType: _parseRoomType(roomType),
      status: _parseRoomStatus(status),
      pricePerNight: pricePerNight,
      description: description,
      images: images,
      capacity: capacity,
      amenities: amenities,
    );
  }

  /// Construye un [RoomModel] desde una entidad de dominio [Room]
  factory RoomModel.fromEntity(Room room) {
    return RoomModel(
      id: room.id,
      roomNumber: room.roomNumber,
      roomType: room.roomType.name,
      status: room.status.name,
      pricePerNight: room.pricePerNight,
      description: room.description,
      images: room.images,
      capacity: room.capacity,
      amenities: room.amenities,
    );
  }

  static RoomType _parseRoomType(String value) {
    return RoomType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoomType.single,
    );
  }

  static RoomStatus _parseRoomStatus(String value) {
    return RoomStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoomStatus.available,
    );
  }
}
