import 'package:hotel_app/domain/entities/audit_log.dart';

abstract class AuditRepository {
  /// Registra una nueva entrada en la bitácora de auditoría
  Future<void> recordLog(AuditLog log);

  /// Registra una acción de auditoría con los datos mínimos requeridos
  Future<void> logAction({
    required String action,
    required String description,
    required String performedBy,
    String? performedByName,
    String? reason,
    required String targetId,
    String? hotelId,
  });

  /// Emite en tiempo real las entradas de auditoría del hotel
  Stream<List<AuditLog>> watchAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
  });

  /// Consulta la lista de registros de auditoría
  Future<List<AuditLog>> getAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
    DateTime? startDate,
    DateTime? endDate,
  });
}
