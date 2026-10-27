import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/repositories/employees_repository_impl.dart';

/// Mock manual de EmployeesDataSource para pruebas unitarias sin conexión a Firestore.
class MockEmployeesDataSource implements EmployeesDataSource {
  final List<User> mockUsers = [];
  String? lastLinkedUserId;
  String? lastLinkedPin;

  @override
  Stream<List<User>> watchEmployees() {
    return Stream.value(mockUsers);
  }

  @override
  Future<void> updateEmployeeRoleAndStatus(
    String userId,
    UserRole newRole,
    UserStatus newStatus,
  ) async {
    final index = mockUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      mockUsers[index] = mockUsers[index].copyWith(
        role: newRole,
        status: newStatus,
      );
    }
  }

  @override
  Future<User?> getEmployeeById(String userId) async {
    try {
      return mockUsers.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> linkWearablePin(String userId, String pin) async {
    lastLinkedUserId = userId;
    lastLinkedPin = pin;
  }
}

void main() {
  group('EmployeesRepositoryImpl Unit Tests con Mocks', () {
    late MockEmployeesDataSource mockDataSource;
    late EmployeesRepository repository;

    setUp(() {
      mockDataSource = MockEmployeesDataSource();
      repository = EmployeesRepositoryImpl(mockDataSource);

      mockDataSource.mockUsers.addAll([
        User(
          id: 'user-1',
          name: 'Juan Perez',
          email: 'juan@hotel.com',
          role: UserRole.housekeeper,
          status: UserStatus.active,
          createdAt: DateTime(2026, 1, 1),
        ),
        User(
          id: 'user-2',
          name: 'Maria Lopez',
          email: 'maria@hotel.com',
          role: UserRole.unassigned,
          status: UserStatus.pending,
          createdAt: DateTime(2026, 2, 1),
        ),
      ]);
    });

    test('watchEmployees emite el listado de empleados', () async {
      final employees = await repository.watchEmployees().first;
      expect(employees.length, 2);
      expect(employees.first.name, 'Juan Perez');
      expect(employees.first.role, UserRole.housekeeper);
    });

    test('updateEmployeeRoleAndStatus actualiza correctamente rol y status', () async {
      await repository.updateEmployeeRoleAndStatus(
        'user-2',
        UserRole.receptionist,
        UserStatus.active,
      );

      final updatedUser = await repository.getEmployeeById('user-2');
      expect(updatedUser, isNotNull);
      expect(updatedUser!.role, UserRole.receptionist);
      expect(updatedUser.status, UserStatus.active);
      expect(updatedUser.isReceptionist, isTrue);
    });

    test('getEmployeeById retorna null cuando el empleado no existe', () async {
      final user = await repository.getEmployeeById('non-existent');
      expect(user, isNull);
    });

    test('linkWearablePin delega al datasource guardando el PIN del reloj', () async {
      await repository.linkWearablePin('user-1', '4821');

      expect(mockDataSource.lastLinkedUserId, equals('user-1'));
      expect(mockDataSource.lastLinkedPin, equals('4821'));
    });
  });
}
