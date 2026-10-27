import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/infraestructure.dart';
import 'package:hotel_app/infrastructure/services/email_service.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';

// ─────────────────────────── Inyección de dependencias ────────────────────────

/// Provider del datasource de empleados
final employeesDataSourceProvider = Provider<EmployeesDataSource>((ref) {
  return EmployeesDataSourceImpl();
});

/// Provider del repositorio de empleados
final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  final dataSource = ref.watch(employeesDataSourceProvider);
  return EmployeesRepositoryImpl(dataSource);
});

// ─────────────────────────── Streams y Notifiers ──────────────────────────────

final employeesStreamProvider = StreamProvider.autoDispose<List<User>>((ref) {
  final repository = ref.watch(employeesRepositoryProvider);
  return repository.watchEmployees();
});

class EmployeesNotifier extends Notifier<bool> {
  @override
  bool build() => false; // isLoading

  EmployeesRepository get _employeesRepo =>
      ref.read(employeesRepositoryProvider);

  Future<void> updateEmployeeRoleAndStatus(
      String userId, UserRole newRole, UserStatus newStatus) async {
    state = true;
    try {
      await _employeesRepo.updateEmployeeRoleAndStatus(
        userId,
        newRole,
        newStatus,
      );

      // Si el estado es activo, mandar correo de aprobación
      if (newStatus == UserStatus.active) {
        final employee = await _employeesRepo.getEmployeeById(userId);
        if (employee != null) {
          await EmailService.sendApprovalEmail(employee);
        }
      }

      // Registrar en Auditoría
      final managerEmail =
          ref.read(authProvider).email ?? 'gerente@desconocido.com';
      final auditRepo = AuditRepository();
      await auditRepo.logAction(
        action: 'UPDATE_EMPLOYEE',
        description:
            'Se cambió el estado a ${newStatus.label} y rol a ${newRole.label} del usuario $userId',
        performedBy: managerEmail,
        targetId: userId,
      );
    } finally {
      state = false;
    }
  }
}

final employeesProvider =
    NotifierProvider<EmployeesNotifier, bool>(EmployeesNotifier.new);
