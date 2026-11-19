import 'package:hotel_app/domain/entities/audit_log.dart';

abstract class AuditDatasource {
  /// Registra una nueva entrada en la bitácora de auditoría
  Future<void> recordLog(AuditLog log);

  /// Emite en tiempo real las entradas de auditoría del hotel ordenadas descendentemente por fecha
  Stream<List<AuditLog>> watchAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
  });

  /// Obtiene la lista histórica de auditoría con filtros opcionales
  Future<List<AuditLog>> getAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
    DateTime? startDate,
    DateTime? endDate,
  });
}
