import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/config/router/app_router.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/screens/auth/pending_approval_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  FakeAuthNotifier(this._initial);

  @override
  AuthState build() => _initial;

  void updateState(AuthState newState) {
    state = newState;
  }
}

class FakeRoomsRepository implements RoomsRepository {
  @override
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type}) async => [];

  @override
  Future<Room> getRoomById(String id) async => throw UnimplementedError();

  @override
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus) async => throw UnimplementedError();
}

class FakeEmployeesRepository implements EmployeesRepository {
  @override
  Stream<List<User>> watchEmployees() => Stream.value([]);

  @override
  Future<User?> getEmployeeById(String userId) async => null;

  @override
  Future<void> linkWearablePin(String userId, String pin) async {}

  @override
  Future<void> updateEmployeeRoleAndStatus(String userId, UserRole newRole, UserStatus newStatus) async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('Issue H-18 - GoRouter Auth Guards & Approval Tests', () {
    testWidgets(
        'Escenario 1: Usuario pendiente de aprobación es redirigido forzosamente a /pending-approval',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Dado que un nuevo empleado se registra desde la app y su estado es pending
      final fakeAuth = FakeAuthNotifier(
        const AuthState(
          isAuthenticated: true,
          email: 'nuevo.empleado@hotel.com',
          name: 'Empleado Nuevo',
          role: UserRole.unassigned,
          status: UserStatus.pending,
          isLoading: false,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => fakeAuth),
          roomsRepositoryProvider.overrideWithValue(FakeRoomsRepository()),
          employeesRepositoryProvider.overrideWithValue(FakeEmployeesRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cuando inicia sesión, GoRouter lo redirige forzosamente a /pending-approval
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.pending);
      expect(find.byType(PendingApprovalScreen), findsOneWidget);
      expect(find.text('Cuenta Pendiente'), findsOneWidget);

      // Entonces no permite navegación a otras pantallas (ej. intentar ir a dashboard o rooms)
      router.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.pending);
      expect(find.byType(PendingApprovalScreen), findsOneWidget);

      router.go(AppRoutes.rooms);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.pending);
      expect(find.byType(PendingApprovalScreen), findsOneWidget);

      router.go(AppRoutes.reservations);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.pending);
      expect(find.byType(PendingApprovalScreen), findsOneWidget);
    });

    testWidgets(
        'Escenario 2: Activación por administrador permite acceso directo al dashboard y rutas permitidas',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Dado que el usuario inicia como pendiente
      final fakeAuth = FakeAuthNotifier(
        const AuthState(
          isAuthenticated: true,
          email: 'empleado.recepcion@hotel.com',
          name: 'Recepcionista Monse',
          role: UserRole.unassigned,
          status: UserStatus.pending,
          isLoading: false,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => fakeAuth),
          roomsRepositoryProvider.overrideWithValue(FakeRoomsRepository()),
          employeesRepositoryProvider.overrideWithValue(FakeEmployeesRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.pending);

      // Cuando el administrador aprueba al usuario asignándole rol y status active en tiempo real
      fakeAuth.updateState(
        const AuthState(
          isAuthenticated: true,
          email: 'empleado.recepcion@hotel.com',
          name: 'Recepcionista Monse',
          role: UserRole.receptionist,
          status: UserStatus.active,
          isLoading: false,
        ),
      );
      await tester.pumpAndSettle();

      // Entonces GoRouter reacciona al listener de cambio de estado y redirige al dashboard
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.dashboard);

      // Y puede navegar a las pantallas autorizadas para su rol (ej. rooms)
      router.go(AppRoutes.rooms);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.rooms);

      // Pero las guardas de rol bloquean acceso a /admin/employees para no-administradores
      router.go(AppRoutes.employees);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.dashboard);

      // Si el rol es admin, sí permite acceder a /admin/employees
      fakeAuth.updateState(
        const AuthState(
          isAuthenticated: true,
          email: 'admin@hotel.com',
          name: 'Gerente Hotel',
          role: UserRole.admin,
          status: UserStatus.active,
          isLoading: false,
        ),
      );
      router.go(AppRoutes.employees);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.employees);

      // Esperar a que se completen timers internos de reintento de proveedores
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Usuario rechazado ve la pantalla de cuenta rechazada', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = FakeAuthNotifier(
        const AuthState(
          isAuthenticated: true,
          email: 'rechazado@hotel.com',
          name: 'Usuario Rechazado',
          role: UserRole.unassigned,
          status: UserStatus.rejected,
          isLoading: false,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => fakeAuth),
          roomsRepositoryProvider.overrideWithValue(FakeRoomsRepository()),
          employeesRepositoryProvider.overrideWithValue(FakeEmployeesRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.pending);
      expect(find.text('Cuenta Rechazada'), findsOneWidget);
    });
  });
}
