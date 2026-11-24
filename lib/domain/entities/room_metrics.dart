import 'room.dart';

/// Contadores agregados de habitaciones por estado.
///
/// Se persiste en `/hotels/{hotelId}/metrics/today` y permite que el dashboard
/// lea un único documento en lugar de la colección completa de habitaciones.
///
/// Los nombres de los campos coinciden con `RoomStatus.name`, de modo que el
/// incremento se arma directamente a partir del estado.
class RoomMetrics {
  final int available;
  final int reserved;
  final int occupied;
  final int pendingCleaning;
  final int cleaning;
  final int cleaned;
  final int outOfOrder;
  final int total;
  final DateTime? updatedAt;

  const RoomMetrics({
    this.available = 0,
    this.reserved = 0,
    this.occupied = 0,
    this.pendingCleaning = 0,
    this.cleaning = 0,
    this.cleaned = 0,
    this.outOfOrder = 0,
    this.total = 0,
    this.updatedAt,
  });

  static const RoomMetrics empty = RoomMetrics();

  /// Recuento desde la colección completa. Solo se usa para reconstruir el
  /// documento agregado, nunca en la lectura normal del dashboard.
  factory RoomMetrics.fromRooms(List<Room> rooms) {
    int count(RoomStatus s) => rooms.where((r) => r.status == s).length;

    return RoomMetrics(
      available: count(RoomStatus.available),
      reserved: count(RoomStatus.reserved),
      occupied: count(RoomStatus.occupied),
      pendingCleaning: count(RoomStatus.pendingCleaning),
      cleaning: count(RoomStatus.cleaning),
      cleaned: count(RoomStatus.cleaned),
      outOfOrder: count(RoomStatus.outOfOrder),
      total: rooms.length,
      updatedAt: DateTime.now(),
    );
  }

  factory RoomMetrics.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    final rawDate = json['updatedAt'];

    return RoomMetrics(
      available: read('available'),
      reserved: read('reserved'),
      occupied: read('occupied'),
      pendingCleaning: read('pendingCleaning'),
      cleaning: read('cleaning'),
      cleaned: read('cleaned'),
      outOfOrder: read('outOfOrder'),
      total: read('total'),
      updatedAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'available': available,
        'reserved': reserved,
        'occupied': occupied,
        'pendingCleaning': pendingCleaning,
        'cleaning': cleaning,
        'cleaned': cleaned,
        'outOfOrder': outOfOrder,
        'total': total,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  int get sumByStatus =>
      available +
      reserved +
      occupied +
      pendingCleaning +
      cleaning +
      cleaned +
      outOfOrder;

  /// `false` indica que el agregado se desvió y conviene reconstruirlo.
  bool get isConsistent => sumByStatus == total;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomMetrics &&
        other.available == available &&
        other.reserved == reserved &&
        other.occupied == occupied &&
        other.pendingCleaning == pendingCleaning &&
        other.cleaning == cleaning &&
        other.cleaned == cleaned &&
        other.outOfOrder == outOfOrder &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(
        available,
        reserved,
        occupied,
        pendingCleaning,
        cleaning,
        cleaned,
        outOfOrder,
        total,
      );
}
