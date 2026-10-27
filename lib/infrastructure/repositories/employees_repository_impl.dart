import 'package:hotel_app/domain/domain.dart';

/// Implementación concreta de [EmployeesRepository].
/// Delega las operaciones al [EmployeesDataSource].
class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesDataSource _dataSource;

  const EmployeesRepositoryImpl(this._dataSource);

  @override
  Stream<List<User>> watchEmployees() {
    return _dataSource.watchEmployees();
  }

  @override
  Future<void> updateEmployeeRoleAndStatus(
    String userId,
    UserRole newRole,
    UserStatus newStatus,
  ) {
    return _dataSource.updateEmployeeRoleAndStatus(userId, newRole, newStatus);
  }

  @override
  Future<User?> getEmployeeById(String userId) {
    return _dataSource.getEmployeeById(userId);
  }

  @override
  Future<void> linkWearablePin(String userId, String pin) {
    return _dataSource.linkWearablePin(userId, pin);
  }
}
