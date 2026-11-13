/// Estados posibles de una reservación
enum ReservationStatus {
  newReservation,
  confirmed,
  checkedIn,
  completed,
  cancelled;

  String get label => switch (this) {
        ReservationStatus.newReservation => 'Nueva',
        ReservationStatus.confirmed => 'Confirmada',
        ReservationStatus.checkedIn => 'Hospedado',
        ReservationStatus.completed => 'Finalizada',
        ReservationStatus.cancelled => 'Cancelada',
      };
}

/// Entidad Reservation — representa una reservación en la capa de dominio.
/// Es independiente de la fuente de datos (API o local).
class Reservation {
  final String id;
  final String roomId;
  final int roomNumber;
  final String guestId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int companions;
  final ReservationStatus status;
  final double total;
  final DateTime createdAt;
  final String? notes;

  const Reservation({
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

  /// Número de noches de la reservación
  int get nights => checkOut.difference(checkIn).inDays;

  /// Retorna true si la reservación está activa (nueva o confirmada)
  bool get isActive =>
      status == ReservationStatus.newReservation ||
      status == ReservationStatus.confirmed;

  /// Retorna true si ya se realizó check-in
  bool get hasCheckedIn => status == ReservationStatus.checkedIn;

  /// Crea una copia de la entidad con los campos modificados
  Reservation copyWith({
    String? id,
    String? roomId,
    int? roomNumber,
    String? guestId,
    String? guestName,
    DateTime? checkIn,
    DateTime? checkOut,
    int? companions,
    ReservationStatus? status,
    double? total,
    DateTime? createdAt,
    String? notes,
  }) {
    return Reservation(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      companions: companions ?? this.companions,
      status: status ?? this.status,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'Reservation(id: $id, guest: $guestName, status: ${status.label}, nights: $nights)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reservation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
