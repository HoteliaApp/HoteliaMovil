import 'package:hotel_app/domain/domain.dart';

/// Modelo de datos de Reservación para la capa de infraestructura.
/// Maneja la serialización/deserialización JSON del API.
class ReservationModel {
  final String id;
  final String roomId;
  final int roomNumber;
  final String guestId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int companions;
  final String status;
  final double total;
  final DateTime createdAt;
  final String? notes;

  const ReservationModel({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.guestId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.companions,
    required this.status,
    required this.total,
    required this.createdAt,
    this.notes,
  });

  /// Construye un [ReservationModel] desde un mapa JSON del API
  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id']?.toString() ?? '',
      roomId: (json['roomId'] ?? json['room_id'] ?? '').toString(),
      roomNumber: _parseRoomNumber(json['roomNumber'] ?? json['room_number']),
      guestId: (json['guestId'] ?? json['guest_id'] ?? '').toString(),
      guestName: json['guestName'] ?? json['guest_name'] ?? '',
      checkIn: DateTime.parse(json['checkIn'] ?? json['check_in']),
      checkOut: DateTime.parse(json['checkOut'] ?? json['check_out']),
      companions: json['companions'] ?? 0,
      status: json['status'] ?? 'pending',
      total: (json['total'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
          json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }

  /// Serializa el modelo a un mapa JSON para enviar al API
  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'guestId': guestId,
        'guestName': guestName,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'companions': companions,
        'status': status,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  /// Convierte el [ReservationModel] a la entidad de dominio [Reservation]
  Reservation toEntity() {
    return Reservation(
      id: id,
      roomId: roomId,
      roomNumber: roomNumber,
      guestId: guestId,
      guestName: guestName,
      checkIn: checkIn,
      checkOut: checkOut,
      companions: companions,
      status: _parseStatus(status),
      total: total,
      createdAt: createdAt,
      notes: notes,
    );
  }

  /// Construye un [ReservationModel] desde una entidad de dominio [Reservation]
  factory ReservationModel.fromEntity(Reservation reservation) {
    return ReservationModel(
      id: reservation.id,
      roomId: reservation.roomId,
      roomNumber: reservation.roomNumber,
      guestId: reservation.guestId,
      guestName: reservation.guestName,
      checkIn: reservation.checkIn,
      checkOut: reservation.checkOut,
      companions: reservation.companions,
      status: reservation.status.name,
      total: reservation.total,
      createdAt: reservation.createdAt,
      notes: reservation.notes,
    );
  }

  static ReservationStatus _parseStatus(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReservationStatus.newReservation,
    );
  }

  /// Tolera reservaciones creadas antes de la issue #14, que no traen
  /// roomNumber, y documentos donde se guardó como cadena.
  static int _parseRoomNumber(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
