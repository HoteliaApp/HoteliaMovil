import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/domain.dart';

class AuditDatasourceImpl implements AuditDatasource {
  final FirebaseFirestore _firestore;
  final String hotelId;

  AuditDatasourceImpl({
    FirebaseFirestore? firestore,
    this.hotelId = 'hotel_101',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('audit_logs');

  @override
  Future<void> recordLog(AuditLog log) async {
    final docRef = log.id.isNotEmpty
        ? _auditLogs.doc(log.id)
        : _auditLogs.doc();

    final data = {
      'id': docRef.id,
      'action': log.action,
      'description': log.description,
      'performedBy': log.performedBy,
      if (log.performedByName != null) 'performedByName': log.performedByName,
      if (log.reason != null) 'reason': log.reason,
      'targetId': log.targetId,
      'hotelId': log.hotelId.isNotEmpty ? log.hotelId : hotelId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);
  }

  @override
  Stream<List<AuditLog>> watchAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
  }) {
    final effectiveHotelId = hotelId.isNotEmpty ? hotelId : this.hotelId;
    return _auditLogs
        .where('hotelId', isEqualTo: effectiveHotelId)
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs.map((doc) {
        return AuditLog.fromMap(doc.data(), doc.id);
      }).toList();

      // Orden cronológico inverso: los eventos más recientes primero
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (filterAction != null) {
        return logs.where((l) => l.actionType == filterAction).toList();
      }
      return logs;
    });
  }

  @override
  Future<List<AuditLog>> getAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final effectiveHotelId = hotelId.isNotEmpty ? hotelId : this.hotelId;
    final snapshot = await _auditLogs
        .where('hotelId', isEqualTo: effectiveHotelId)
        .get();

    var logs = snapshot.docs.map((doc) {
      return AuditLog.fromMap(doc.data(), doc.id);
    }).toList();

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (filterAction != null) {
      logs = logs.where((l) => l.actionType == filterAction).toList();
    }

    if (startDate != null) {
      logs = logs.where((l) => l.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      logs = logs.where((l) => l.timestamp.isBefore(endDate)).toList();
    }

    return logs;
  }
}
