import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/audit/audit_provider.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/screens/admin/audit_screen.dart';
import 'package:hotel_app/presentation/widgets/reservations/cancel_reservation_dialog.dart';
import 'package:hotel_app/presentation/widgets/audit/audit_log_card.dart';

class _FakeAuditRepository implements AuditRepository {
  final List<AuditLog> logs;
  final StreamController<List<AuditLog>> controller;

  _FakeAuditRepository({List<AuditLog>? initialLogs})
      : logs = initialLogs ?? [],
        controller = StreamController<List<AuditLog>>.broadcast();

  @override
  Future<void> recordLog(AuditLog log) async {
    logs.insert(0, log);
    controller.add(List.from(logs));
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
    final log = AuditLog(
      id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      description: description,
      performedBy: performedBy,
      performedByName: performedByName,
      reason: reason,
      targetId: targetId,
      timestamp: DateTime.now(),
      hotelId: hotelId ?? 'hotel_101',
    );
    await recordLog(log);
  }

  @override
  Stream<List<AuditLog>> watchAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
  }) {
    // Retorna stream con los logs actuales
    return Stream.value(
      filterAction != null
          ? logs.where((l) => l.actionType == filterAction).toList()
          : List.from(logs),
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogs({
    required String hotelId,
    AuditActionType? filterAction,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var result = List<AuditLog>.from(logs);
    if (filterAction != null) {
      result = result.where((l) => l.actionType == filterAction).toList();
    }
    return result;
  }
}

class _FakeReservationsRepository implements ReservationsRepository {
  List<Reservation> reservations;

  _FakeReservationsRepository(this.reservations);

  @override
  Future<List<Reservation>> getReservations({ReservationStatus? status, String? guestId}) async => reservations;

  @override
  Future<Reservation> getReservationById(String id) async =>
      reservations.firstWhere((r) => r.id == id);

  @override
  Future<Reservation?> getOverlappingReservation({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async => null;

  @override
  Future<Reservation> createReservation(CreateReservationParams params) async => throw UnimplementedError();

  @override
  Future<Reservation> checkIn({
    required String reservationId,
    required String guestName,
    required int companions,
    required DateTime expectedCheckOut,
  }) async => throw UnimplementedError();

  @override
  Future<Reservation> checkOut(String reservationId) async => throw UnimplementedError();

  @override
  Future<Reservation> cancelReservation(String reservationId) async {
    final idx = reservations.indexWhere((r) => r.id == reservationId);
    final updated = reservations[idx].copyWith(status: ReservationStatus.cancelled);
    reservations[idx] = updated;
    return updated;
  }
}

class _MockRoomsNotifier extends RoomsNotifier {
  final RoomsState _initial;
  _MockRoomsNotifier(this._initial);

  @override
  RoomsState build() => _initial;
}

void main() {
  group('H-30 Entidades y Modelado de Auditoría (AuditLog)', () {
    test('AuditLog clasifica correctamente los tipos de acción y formatea el operador', () {
      final logCancel = AuditLog(
        id: 'log-1',
        action: 'CANCEL_RESERVATION',
        description: 'Cancelación de reservación #101',
        performedBy: 'recepcion@hotel.com',
        performedByName: 'Carlos Recepcionista',
        reason: 'Cliente canceló por vuelo retrasado',
        targetId: 'res-101',
        timestamp: DateTime(2026, 11, 19, 10, 30),
      );

      expect(logCancel.actionType, AuditActionType.cancellation);
      expect(logCancel.isCritical, isTrue);
      expect(logCancel.operatorDisplayName, 'Carlos Recepcionista');
      expect(logCancel.reason, 'Cliente canceló por vuelo retrasado');

      final logCheckIn = AuditLog(
        id: 'log-2',
        action: 'CHECK_IN',
        description: 'Check-in Hab. 102',
        performedBy: 'ana@hotel.com',
        targetId: 'res-102',
        timestamp: DateTime(2026, 11, 19, 11, 00),
      );

      expect(logCheckIn.actionType, AuditActionType.checkIn);
      expect(logCheckIn.isCritical, isFalse);
      expect(logCheckIn.operatorDisplayName, 'ana@hotel.com');
    });

    test('AuditLog.fromMap deserializa correctamente con fecha y motivo', () {
      final map = {
        'id': 'log-map-1',
        'action': 'UPDATE_EMPLOYEE',
        'description': 'Cambio de rol a recepcionista',
        'performedBy': 'gerente@hotel.com',
        'performedByName': 'Monserrath Castañón',
        'reason': 'Promoción interna',
        'targetId': 'usr-3',
        'hotelId': 'hotel_101',
        'timestamp': DateTime(2026, 11, 19, 8, 15),
      };

      final log = AuditLog.fromMap(map, 'log-map-1');
      expect(log.id, 'log-map-1');
      expect(log.actionType, AuditActionType.roleChange);
      expect(log.operatorDisplayName, 'Monserrath Castañón');
      expect(log.reason, 'Promoción interna');
    });
  });

  group('H-30 CancelReservationDialog (Captura del motivo de cancelación)', () {
    testWidgets('Requiere obligatoriamente un motivo antes de confirmar cancelación', (tester) async {
      final reservation = Reservation(
        id: 'res-test',
        roomId: 'room-1',
        guestId: 'guest-1',
        guestName: 'Juan Pérez',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 2)),
        companions: 1,
        roomNumber: 101,
        total: 1500,
        status: ReservationStatus.confirmed,
        createdAt: DateTime.now(),
      );

      String? resultReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultReason = await CancelReservationDialog.show(
                    context,
                    reservation: reservation,
                  );
                },
                child: const Text('Abrir Diálogo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      // Verificar que el diálogo está visible
      expect(find.text('Cancelar reservación'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsOneWidget);

      // Intentar confirmar sin escribir motivo
      await tester.tap(find.byKey(const Key('confirm_cancel_reservation_button')));
      await tester.pumpAndSettle();

      // Debe mostrar error de validación
      expect(find.text('El motivo de cancelación es obligatorio'), findsOneWidget);
      expect(resultReason, isNull);

      // Escribir motivo descriptivo válido
      await tester.enterText(
        find.byKey(const Key('cancel_reservation_reason_field')),
        'Cliente solicitó cancelación por emergencia médica',
      );
      await tester.pumpAndSettle();

      // Confirmar
      await tester.tap(find.byKey(const Key('confirm_cancel_reservation_button')));
      await tester.pumpAndSettle();

      // El diálogo se cierra y retorna el motivo
      expect(find.text('Cancelar reservación'), findsNothing);
      expect(resultReason, 'Cliente solicitó cancelación por emergencia médica');
    });
  });

  group('H-30 Criterio de Aceptación Gherkin: Trazabilidad de evento crítico', () {
    testWidgets(
      'Escenario 1 (Gherkin): Dado que un recepcionista cancela una reservación confirmada, '
      'cuando el gerente consulta la pantalla de Auditoría, '
      'entonces aparece el registro con fecha, hora, nombre del recepcionista y motivo de la cancelación',
      (tester) async {
        // GIVEN: Un recepcionista realiza la cancelación de una reservación confirmada
        final fixedTimestamp = DateTime(2026, 11, 19, 14, 45);
        final fakeAuditRepo = _FakeAuditRepository();

        final cancellationLog = AuditLog(
          id: 'audit-cancel-1',
          action: 'CANCEL_RESERVATION',
          description: 'Cancelación de la reservación #res-999 (Elena Morales, Hab. 204). Motivo: Cambio de vuelo y fuerza mayor',
          performedBy: 'carlos.recepcion@hotel.com',
          performedByName: 'Carlos Recepcionista',
          reason: 'Cambio de vuelo y fuerza mayor',
          targetId: 'res-999',
          timestamp: fixedTimestamp,
          hotelId: 'hotel_101',
        );

        await fakeAuditRepo.recordLog(cancellationLog);

        // WHEN: El gerente consulta la pantalla de Auditoría
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentHotelIdProvider.overrideWithValue('hotel_101'),
              auditRepositoryProvider.overrideWithValue(fakeAuditRepo),
              authProvider.overrideWith(() => AuthNotifierMock(
                    role: UserRole.admin,
                    email: 'gerente@hotel.com',
                  )),
            ],
            child: const MaterialApp(
              home: AuditScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Aparece el registro con nombre del recepcionista, motivo de cancelación y fecha/hora
        expect(find.text('Bitácora de Auditoría'), findsOneWidget);
        expect(find.byType(AuditLogCard), findsOneWidget);

        // Nombre del recepcionista visible
        expect(find.text('Carlos Recepcionista'), findsOneWidget);

        // Motivo de la cancelación visible
        expect(find.text('Motivo de cancelación:'), findsOneWidget);
        expect(find.text('Cambio de vuelo y fuerza mayor'), findsOneWidget);

        // Fecha y hora formateada visible (19/11/2026 14:45)
        expect(find.text('19/11/2026 14:45'), findsOneWidget);

        // Badge de tipo "Cancelación"
        expect(find.text('Cancelación'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('AuditScreen permite filtrar por tipo de acción y búsqueda textual', (tester) async {
      final fakeAuditRepo = _FakeAuditRepository(
        initialLogs: [
          AuditLog(
            id: 'log-1',
            action: 'CANCEL_RESERVATION',
            description: 'Cancelación de reservación #101',
            performedBy: 'carlos@hotel.com',
            performedByName: 'Carlos Recepcionista',
            reason: 'Cliente canceló por salud',
            targetId: 'res-101',
            timestamp: DateTime(2026, 11, 19, 10, 0),
          ),
          AuditLog(
            id: 'log-2',
            action: 'CHECK_IN',
            description: 'Check-in Habitación 202',
            performedBy: 'ana@hotel.com',
            performedByName: 'Ana Recepción',
            targetId: 'res-202',
            timestamp: DateTime(2026, 11, 19, 11, 0),
          ),
          AuditLog(
            id: 'log-3',
            action: 'UPDATE_EMPLOYEE',
            description: 'Cambio de rol a Ama de llaves',
            performedBy: 'gerente@hotel.com',
            performedByName: 'Monserrath Gerente',
            targetId: 'usr-88',
            timestamp: DateTime(2026, 11, 19, 12, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentHotelIdProvider.overrideWithValue('hotel_101'),
            auditRepositoryProvider.overrideWithValue(fakeAuditRepo),
          ],
          child: const MaterialApp(
            home: AuditScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Inicialmente se muestran los 3 logs
      expect(find.byType(AuditLogCard), findsNWidgets(3));

      // Filtrar por texto: 'Ana'
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pumpAndSettle();

      expect(find.byType(AuditLogCard), findsOneWidget);
      expect(find.text('Ana Recepción'), findsOneWidget);

      // Limpiar búsqueda
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(AuditLogCard), findsNWidgets(3));

      // Filtrar por chip de Cancelaciones
      await tester.tap(find.text('Cancelaciones'));
      await tester.pumpAndSettle();

      expect(find.byType(AuditLogCard), findsOneWidget);
      expect(find.text('Carlos Recepcionista'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends AuthNotifier {
  final UserRole _role;
  final String _email;

  AuthNotifierMock({
    required UserRole role,
    required String email,
  })  : _role = role,
        _email = email;

  @override
  AuthState build() {
    return AuthState(
      isAuthenticated: true,
      role: _role,
      email: _email,
      name: 'Gerente Mock',
      hotelId: 'hotel_101',
    );
  }
}
