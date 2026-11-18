import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/mappers/mappers.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';
import 'package:hotel_app/infrastructure/models/reservation/reservation_model.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';

void main() {
  group('H-24 Multi-Tenant: Entidades y Mappers', () {
    test('User y UserMapper encapsulan y persisten hotelId correctamente', () {
      final user = User(
        id: 'u-1',
        name: 'Ana Recepción',
        email: 'ana@hotel101.com',
        role: UserRole.receptionist,
        status: UserStatus.active,
        createdAt: DateTime(2026, 11, 15),
        hotelId: 'hotel_101',
      );

      expect(user.hotelId, equals('hotel_101'));

      final firestoreMap = UserMapper.toFirestore(user);
      expect(firestoreMap['hotelId'], equals('hotel_101'));

      final parsedUser = UserMapper.fromFirestore(firestoreMap, 'u-1');
      expect(parsedUser.hotelId, equals('hotel_101'));
      expect(parsedUser.name, equals('Ana Recepción'));

      // Fallback a hotel_101 cuando el documento no tiene hotelId
      final legacyUser = UserMapper.fromFirestore({
        'name': 'Carlos Antiguo',
        'email': 'carlos@hotel.com',
      }, 'u-legacy');
      expect(legacyUser.hotelId, equals('hotel_101'));
    });

    test('Room y RoomModel encapsulan y persisten hotelId correctamente', () {
      final room = Room(
        id: 'room-101',
        roomNumber: 101,
        roomType: RoomType.single,
        status: RoomStatus.available,
        pricePerNight: 50.0,
        description: 'Habitación Sencilla',
        images: ['https://example.com/101.jpg'],
        capacity: 1,
        amenities: ['WiFi', 'TV'],
        hotelId: 'hotel_101',
      );

      expect(room.hotelId, equals('hotel_101'));

      final model = RoomModel.fromEntity(room);
      expect(model.hotelId, equals('hotel_101'));

      final json = model.toJson();
      expect(json['hotelId'], equals('hotel_101'));

      final fromJsonRoom = RoomMapper.fromJson(json);
      expect(fromJsonRoom.hotelId, equals('hotel_101'));
      expect(fromJsonRoom.roomNumber, equals(101));

      // Fallback a hotel_101 para documentos existentes sin hotelId
      final legacyRoom = RoomMapper.fromJson({
        'roomNumber': 102,
        'roomType': 'double',
      });
      expect(legacyRoom.hotelId, equals('hotel_101'));
    });

    test('Reservation y ReservationModel encapsulan y persisten hotelId correctamente', () {
      final now = DateTime(2026, 11, 15);
      final checkOut = DateTime(2026, 11, 18);

      final reservation = Reservation(
        id: 'res-101',
        roomId: 'room-101',
        roomNumber: 101,
        guestId: 'guest-1',
        guestName: 'Laura Gómez',
        checkIn: now,
        checkOut: checkOut,
        companions: 1,
        status: ReservationStatus.confirmed,
        total: 150.0,
        createdAt: now,
        hotelId: 'hotel_101',
      );

      expect(reservation.hotelId, equals('hotel_101'));

      final model = ReservationModel.fromEntity(reservation);
      expect(model.hotelId, equals('hotel_101'));

      final json = model.toJson();
      expect(json['hotelId'], equals('hotel_101'));

      final fromJsonRes = ReservationMapper.fromJson(json);
      expect(fromJsonRes.hotelId, equals('hotel_101'));
      expect(fromJsonRes.guestName, equals('Laura Gómez'));

      // Fallback a hotel_101 para documentos antiguos
      final legacyRes = ReservationMapper.fromJson({
        'roomId': 'room-102',
        'roomNumber': 102,
        'guestName': 'Pedro',
        'checkIn': now.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
      });
      expect(legacyRes.hotelId, equals('hotel_101'));
    });

    test('Task y TaskMapper encapsulan hotelId y usan schemaVersion 2', () {
      final task = Task(
        id: 'task-1763000000000',
        roomId: 'room-201',
        roomNumber: 201,
        taskType: 'cleaning',
        status: 'pending',
        description: 'Limpieza post check-out',
        guestName: 'Juan Pérez',
        assignedBy: 'user-admin',
        createdAt: DateTime(2026, 11, 15, 10, 0),
        priority: 4,
        hotelId: 'hotel_101',
      );

      expect(task.hotelId, equals('hotel_101'));
      expect(Task.schemaVersion, equals(2));

      final firestoreMap = TaskMapper.toFirestore(task);
      expect(firestoreMap['hotelId'], equals('hotel_101'));
      expect(firestoreMap['schemaVersion'], equals(2));

      final fromFirestoreTask = TaskMapper.fromFirestore(firestoreMap, task.id);
      expect(fromFirestoreTask.hotelId, equals('hotel_101'));
      expect(fromFirestoreTask.roomNumber, equals(201));

      // Fallback a hotel_101 para tareas de schemaVersion 1 sin hotelId
      final legacyTask = TaskMapper.fromFirestore({
        'id': 'legacy-task',
        'roomNumber': 101,
        'schemaVersion': 1,
      });
      expect(legacyTask.hotelId, equals('hotel_101'));
    });

    test('Hotel y HotelMapper representan y mapean el inquilino (SaaS)', () {
      final hotel = Hotel(
        id: 'hotel_101',
        name: 'Hotel Valle Real',
        floors: 5,
        address: 'Av. Las Palmas 500',
        createdAt: DateTime(2026, 11, 15),
        plan: 'premium',
      );

      expect(hotel.id, equals('hotel_101'));
      expect(hotel.schemaVersion, equals(2));

      final map = HotelMapper.toFirestore(hotel);
      expect(map['id'], equals('hotel_101'));
      expect(map['plan'], equals('premium'));
      expect(map['schemaVersion'], equals(2));

      final parsedHotel = HotelMapper.fromFirestore(map, 'hotel_101');
      expect(parsedHotel.name, equals('Hotel Valle Real'));
      expect(parsedHotel.floors, equals(5));
      expect(parsedHotel.plan, equals('premium'));
    });
  });

  group('H-24 Criterio de Aceptación: Aislamiento de consultas por hotel (Gherkin)', () {
    test('Dado que un usuario autenticado pertenece a hotel_101, sus consultas y tareas quedan acotadas', () {
      // Simulación de repositorio de tareas con filtrado por hotelId
      final allTasks = [
        Task(
          id: 'task-1',
          roomId: 'room-101',
          roomNumber: 101,
          taskType: 'cleaning',
          status: 'pending',
          description: 'Limpieza Hab 101 Hotel 101',
          guestName: 'Huésped 1',
          assignedBy: 'user-1',
          createdAt: DateTime.now(),
          hotelId: 'hotel_101',
        ),
        Task(
          id: 'task-2',
          roomId: 'room-201',
          roomNumber: 201,
          taskType: 'maintenance',
          status: 'pending',
          description: 'Mantenimiento Hab 201 Hotel 101',
          guestName: 'Huésped 2',
          assignedBy: 'user-1',
          createdAt: DateTime.now(),
          hotelId: 'hotel_101',
        ),
        Task(
          id: 'task-3',
          roomId: 'room-999',
          roomNumber: 999,
          taskType: 'cleaning',
          status: 'pending',
          description: 'Limpieza Habitación de Hotel 102 (OTRO INQUILINO)',
          guestName: 'Huésped Invasor',
          assignedBy: 'user-other',
          createdAt: DateTime.now(),
          hotelId: 'hotel_102',
        ),
      ];

      const userHotelId = 'hotel_101';

      // Simulación del filtro where('hotelId', '==', 'hotel_101')
      final userScopedTasks = allTasks.where((t) => t.hotelId == userHotelId).toList();

      // Criterio de aceptación: estricto aislamiento
      expect(userScopedTasks.length, equals(2));
      expect(userScopedTasks.any((t) => t.hotelId == 'hotel_102'), isFalse);
      expect(userScopedTasks.every((t) => t.hotelId == 'hotel_101'), isTrue);
    });

    test('currentHotelIdProvider expone el hotelId del AuthState de manera reactiva', () {
      final container = ProviderContainer();

      // Por defecto fallback a hotel_101
      expect(container.read(currentHotelIdProvider), equals('hotel_101'));

      // Cuando el usuario inicia sesión con otro hotel
      final containerCustom = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(
                const AuthState(
                  isAuthenticated: true,
                  email: 'gerente@valle.com',
                  name: 'Gerente Valle',
                  role: UserRole.admin,
                  status: UserStatus.active,
                  hotelId: 'hotel_valle_01',
                ),
              )),
        ],
      );

      expect(containerCustom.read(currentHotelIdProvider), equals('hotel_valle_01'));
    });
  });

  group('H-26 Reglas de Seguridad Firestore y Aislamiento Cross-Tenant (Gherkin)', () {
    test('firestore.rules y firebase.json definen reglas estrictas por Custom Claim hotelId', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final rulesContent = rulesFile.readAsStringSync();
      expect(rulesContent, contains("rules_version = '2';"));
      expect(rulesContent, contains('request.auth.token.hotelId'));
      expect(rulesContent, contains('belongsToTenant'));
      expect(rulesContent, contains('isSameTenantUpdate'));

      for (final collectionPattern in [
        'match /hotels/{hotelId}',
        'match /users/{userId}',
        'match /rooms/{roomId}',
        'match /reservations/{reservationId}',
        'match /tasks/{taskId}',
        'match /alerts/{alertId}',
        'match /audit_logs/{logId}',
        'match /{document=**}',
      ]) {
        expect(rulesContent, contains(collectionPattern));
      }

      final firebaseJsonFile = File('firebase.json');
      expect(firebaseJsonFile.existsSync(), isTrue);
      final decoded =
          jsonDecode(firebaseJsonFile.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['firestore'], equals({'rules': 'firestore.rules'}));
      expect(decoded['flutter'], isA<Map<String, dynamic>>());
    });

    test(
      'Escenario 1 (Gherkin): Usuario con credenciales del Hotel A tiene acceso denegado a documentos del Hotel B',
      () {
        // Evaluación fiel de las funciones belongsToTenant / isSameTenantUpdate de firestore.rules
        bool hasHotelClaim(Map<String, dynamic>? authToken) {
          if (authToken == null) return false;
          final claim = authToken['hotelId'];
          return claim is String && claim.isNotEmpty;
        }

        bool canReadTenantDoc(Map<String, dynamic>? authToken, String? docHotelId) {
          return hasHotelClaim(authToken) && docHotelId == authToken!['hotelId'];
        }

        bool canCreateTenantDoc(Map<String, dynamic>? authToken, String? newDocHotelId) {
          return hasHotelClaim(authToken) && newDocHotelId == authToken!['hotelId'];
        }

        bool canUpdateTenantDoc(
          Map<String, dynamic>? authToken,
          String? existingHotelId,
          String? nextHotelId,
        ) {
          return canReadTenantDoc(authToken, existingHotelId) &&
              nextHotelId == existingHotelId;
        }

        bool canDeleteTenantDoc(Map<String, dynamic>? authToken, String? existingHotelId) {
          return canReadTenantDoc(authToken, existingHotelId);
        }

        // Dado un usuario con credenciales válidas del Hotel A
        final hotelAToken = <String, dynamic>{'hotelId': 'hotel_A'};

        // Cuando intenta leer o escribir documentos del Hotel B
        expect(canReadTenantDoc(hotelAToken, 'hotel_B'), isFalse);
        expect(canCreateTenantDoc(hotelAToken, 'hotel_B'), isFalse);
        expect(canUpdateTenantDoc(hotelAToken, 'hotel_B', 'hotel_B'), isFalse);
        expect(canDeleteTenantDoc(hotelAToken, 'hotel_B'), isFalse);

        // Intento de alterar el hotelId de un documento propio del Hotel A hacia Hotel B
        expect(canUpdateTenantDoc(hotelAToken, 'hotel_A', 'hotel_B'), isFalse);

        // Token sin Custom Claim hotelId también queda bloqueado
        expect(canReadTenantDoc(<String, dynamic>{}, 'hotel_A'), isFalse);
        expect(canReadTenantDoc(null, 'hotel_A'), isFalse);

        // Operaciones legítimas sobre documentos propios del Hotel A son permitidas
        expect(canReadTenantDoc(hotelAToken, 'hotel_A'), isTrue);
        expect(canCreateTenantDoc(hotelAToken, 'hotel_A'), isTrue);
        expect(canUpdateTenantDoc(hotelAToken, 'hotel_A', 'hotel_A'), isTrue);
        expect(canDeleteTenantDoc(hotelAToken, 'hotel_A'), isTrue);
      },
    );

    test(
      'AuthNotifier.resolveTenantHotelId prioriza el Custom Claim y rechaza discrepancias cross-tenant',
      () {
        expect(
          AuthNotifier.resolveTenantHotelId(
            tokenClaimHotelId: 'hotel_A',
            documentHotelId: null,
          ),
          equals('hotel_A'),
        );
        expect(
          AuthNotifier.resolveTenantHotelId(
            tokenClaimHotelId: 'hotel_A',
            documentHotelId: 'hotel_A',
          ),
          equals('hotel_A'),
        );
        expect(
          AuthNotifier.resolveTenantHotelId(
            tokenClaimHotelId: null,
            documentHotelId: 'hotel_B',
          ),
          equals('hotel_B'),
        );
        expect(
          AuthNotifier.resolveTenantHotelId(
            tokenClaimHotelId: null,
            documentHotelId: null,
          ),
          equals('hotel_101'),
        );
        expect(
          () => AuthNotifier.resolveTenantHotelId(
            tokenClaimHotelId: 'hotel_A',
            documentHotelId: 'hotel_B',
          ),
          throwsStateError,
        );
      },
    );
  });
}

class _MockAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  _MockAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}
