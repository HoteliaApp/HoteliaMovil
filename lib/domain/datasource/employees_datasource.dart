import '../entities/entities.dart';

/// Contrato abstracto para la fuente de datos de empleados y usuarios.
abstract class EmployeesDataSource {
  /// Stream en tiempo real de todos los usuarios/empleados.
  Stream<List<User>> watchEmployees();

  /// Actualiza el rol y el estado de un empleado.
  Future<void> updateEmployeeRoleAndStatus(
    String userId,
    UserRole newRole,
    UserStatus newStatus,
  );

  /// Obtiene los datos de un empleado por su ID.
  Future<User?> getEmployeeById(String userId);

  /// Vincula un PIN de reloj inteligente (wearable) al usuario.
  Future<void> linkWearablePin(String userId, String pin);
}
