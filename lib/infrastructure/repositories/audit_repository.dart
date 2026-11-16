import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/entities/audit_log.dart';

class AuditRepository {
  final FirebaseFirestore _firestore;
  final String hotelId;

  AuditRepository({
    FirebaseFirestore? firestore,
    this.hotelId = 'hotel_101',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logAction({
    required String action,
    required String description,
    required String performedBy,
    required String targetId,
    String? hotelId,
  }) async {
    try {
      final docRef = _firestore.collection('audit_logs').doc();
      final log = AuditLog(
        id: docRef.id,
        action: action,
        description: description,
        performedBy: performedBy,
        targetId: targetId,
        timestamp: DateTime.now(),
        hotelId: hotelId ?? this.hotelId,
      );
      await docRef.set(log.toMap());
    } catch (e) {
      debugPrint('Error guardando log de auditoría: $e');
    }
  }
}
