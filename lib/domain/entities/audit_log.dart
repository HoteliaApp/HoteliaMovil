class AuditLog {
  final String id;
  final String action;
  final String description;
  final String performedBy;
  final String targetId;
  final DateTime timestamp;
  final String hotelId;

  const AuditLog({
    required this.id,
    required this.action,
    required this.description,
    required this.performedBy,
    required this.targetId,
    required this.timestamp,
    this.hotelId = 'hotel_101',
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'description': description,
      'performedBy': performedBy,
      'targetId': targetId,
      'timestamp': timestamp,
      'hotelId': hotelId,
    };
  }
}
