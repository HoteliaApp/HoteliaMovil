import 'package:flutter/foundation.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/datasource/audit_datasource_impl.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AuditDatasource _datasource;
  final String hotelId;

  AuditRepositoryImpl([
    AuditDatasource? datasource,
    this.hotelId = 'hotel_101',
  ]) : _datasource = datasource ?? AuditDatasourceImpl(hotelId: hotelId);

  @override
  Future<void> recordLog(AuditLog log) async {
    try {
      await _datasource.recordLog(log);
    } catch (e) {
      debugPrint('Error guardando registro de auditoría: $e');
    }
  }

  @override
  Future<void> logAction({
    required String action,
    required String description,
    required String performedBy,
    String? performedByName,
    String? reason,
    required String targetId,
    String? hotelId,
  }) async {
    try {
      final log = AuditLog(
        id: '',
        action: action,
        description: description,
        performedBy: performedBy,
        performedByName: performedByName,
        reason: reason,
        targetId: targetId,
        timestamp: DateTime.now(),
        hotelId: hotelId ?? this.hotelId,
      );
      await recordLog(log);
    } catch (e) {
      debugPrint('Error al registrar acción de auditoría: $e');
    }
  }

  @override
  Stream<List<AuditLog>> watchAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
  }) {
    return _datasource.watchAuditLogs(
      hotelId: hotelId.isNotEmpty ? hotelId : this.hotelId,
      filterAction: filterAction,
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _datasource.getAuditLogs(
      hotelId: hotelId.isNotEmpty ? hotelId : this.hotelId,
      filterAction: filterAction,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
