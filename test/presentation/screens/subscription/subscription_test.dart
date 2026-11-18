import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/screens/rooms/rooms_screen.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';
import 'package:hotel_app/presentation/widgets/subscription/room_limit_reached_dialog.dart';
import 'package:hotel_app/presentation/widgets/subscription/subscription_card.dart';

class _FakeSubscriptionRepository implements SubscriptionRepository {
  Hotel currentHotel;
  String? requestedPlan;
  String? requestedNotes;

  _FakeSubscriptionRepository({required this.currentHotel});

  @override
  Future<Hotel> getHotelSubscription(String hotelId) async => currentHotel;

  @override
  Stream<Hotel> watchHotelSubscription(String hotelId) =>
      Stream.value(currentHotel);

  @override
  Future<void> requestPlanChange(
    String hotelId,
    String newPlan, {
    String? notes,
  }) async {
    requestedPlan = newPlan;
    requestedNotes = notes;
    currentHotel = currentHotel.copyWith(
      requestedPlan: newPlan,
      planChangeRequestedAt: DateTime.now(),
    );
  }
}

class _MockRoomsNotifier extends RoomsNotifier {
  final RoomsState _initial;
  _MockRoomsNotifier(this._initial);

  @override
  RoomsState build() => _initial;
}

void main() {
  group('H-29 Entidades de Suscripción y Límites SaaS', () {
    test('Hotel y HotelSubscription aplican los límites correctos según el plan contratado', () {
      final basicHotel = Hotel(
        id: 'h-basic',
        name: 'Hotel Básico',
        floors: 1,
        address: 'Calle 1',
        createdAt: DateTime.now(),
        plan: 'basic',
      );

      expect(basicHotel.maxRooms, equals(20));
      expect(basicHotel.maxUsers, equals(5));
      expect(basicHotel.planLabel, equals('Básico'));

      final standardHotel = Hotel(
        id: 'h-std',
        name: 'Hotel Intermedio',
        floors: 3,
        address: 'Calle 2',
        createdAt: DateTime.now(),
        plan: 'standard',
      );

      expect(standardHotel.maxRooms, equals(50));
      expect(standardHotel.maxUsers, equals(15));
      expect(standardHotel.planLabel, equals('Intermedio'));

      final premiumHotel = Hotel(
        id: 'h-prem',
        name: 'Hotel Premium',
        floors: 6,
        address: 'Calle 3',
        createdAt: DateTime.now(),
        plan: 'premium',
      );

      expect(premiumHotel.maxRooms, equals(150));
      expect(premiumHotel.maxUsers, equals(50));
      expect(premiumHotel.planLabel, equals('Premium'));
    });

    test('HotelSubscription calcula correctamente límites alcanzados y porcentajes de uso', () {
      const sub = HotelSubscription(
        hotelId: 'h-1',
        plan: 'basic',
        maxRooms: 20,
        maxUsers: 5,
        currentRooms: 20,
        currentUsers: 3,
      );

      expect(sub.isRoomsLimitReached, isTrue);
      expect(sub.isUsersLimitReached, isFalse);
      expect(sub.roomsUsagePercentage, equals(1.0));
      expect(sub.usersUsagePercentage, equals(0.6));
    });
  });

  group('H-29 Criterios de Aceptación Gherkin: Límite de habitaciones alcanzado', () {
    testWidgets(
      'Escenario 1 (Gherkin): Dado un hotel con suscripción Básica (máximo 20 habitaciones), cuando el usuario intenta registrar la habitación número 21, entonces la app muestra un diálogo informando que ha alcanzado el límite con botón para mejorar suscripción',
      (tester) async {
        // ── Dado: Hotel con suscripción Básica y 20 habitaciones registradas ──
        final initialRooms = List.generate(
          20,
          (i) => Room(
            id: 'room-${101 + i}',
            roomNumber: 101 + i,
            roomType: RoomType.single,
            status: RoomStatus.available,
            pricePerNight: 50.0,
            description: 'Habitación ${101 + i}',
            images: const ['https://example.com/room.jpg'],
            capacity: 1,
            amenities: const ['WiFi'],
            hotelId: 'hotel_basic_test',
          ),
        );

        final basicSubscription = HotelSubscription(
          hotelId: 'hotel_basic_test',
          plan: 'basic',
          maxRooms: 20,
          maxUsers: 5,
          currentRooms: 20,
          currentUsers: 2,
        );

        final fakeSubRepo = _FakeSubscriptionRepository(
          currentHotel: Hotel(
            id: 'hotel_basic_test',
            name: 'Hotel Paraíso Básico',
            floors: 2,
            address: 'Av. Costa 100',
            createdAt: DateTime.now(),
            plan: 'basic',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionRepositoryProvider.overrideWithValue(fakeSubRepo),
              hotelSubscriptionProvider.overrideWithValue(basicSubscription),
              roomsProvider.overrideWith(
                () => _MockRoomsNotifier(
                  RoomsState(rooms: initialRooms, isLoading: false),
                ),
              ),
              currentHotelIdProvider.overrideWithValue('hotel_basic_test'),
              authProvider.overrideWith(() => _MockAdminAuthNotifier()),
            ],
            child: const MaterialApp(
              home: RoomsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar que estamos en RoomsScreen con 20 habitaciones
        expect(find.text('20 habitaciones encontradas'), findsOneWidget);
        expect(find.text('Nueva habitación'), findsOneWidget);

        // ── Cuando: El usuario intenta registrar la habitación número 21 ──
        await tester.tap(find.text('Nueva habitación'));
        await tester.pumpAndSettle();

        // ── Entonces: La app muestra el diálogo informando del límite alcanzado ──
        expect(find.byType(RoomLimitReachedDialog), findsOneWidget);
        expect(find.text('Límite de habitaciones alcanzado'), findsOneWidget);
        expect(
          find.textContaining('máximo de 20 habitaciones'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Para registrar la habitación número 21'),
          findsOneWidget,
        );

        // Y contiene el botón para mejorar la suscripción
        expect(find.widgetWithText(ElevatedButton, 'Mejorar suscripción'), findsOneWidget);

        // Al presionar 'Mejorar suscripción', se abre el diálogo para solicitar cambio de plan
        await tester.tap(find.widgetWithText(ElevatedButton, 'Mejorar suscripción'));
        await tester.pumpAndSettle();

        expect(find.byType(ChangePlanDialog), findsOneWidget);
        expect(find.text('Solicitar Cambio de Plan'), findsOneWidget);
      },
    );

    test('SubscriptionActionNotifier registra solicitud de cambio de plan en Firestore', () async {
      final fakeSubRepo = _FakeSubscriptionRepository(
        currentHotel: Hotel(
          id: 'hotel_101',
          name: 'Hotel 101',
          floors: 3,
          address: 'Centro',
          createdAt: DateTime.now(),
          plan: 'basic',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(fakeSubRepo),
          currentHotelIdProvider.overrideWithValue('hotel_101'),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(subscriptionActionProvider.notifier);

      await notifier.requestPlanChange('premium', notes: 'Queremos añadir 40 habitaciones');

      expect(fakeSubRepo.requestedPlan, equals('premium'));
      expect(fakeSubRepo.requestedNotes, contains('Queremos añadir 40 habitaciones'));
      expect(container.read(subscriptionActionProvider).isSuccess, isTrue);
    });
  });

  group('H-29 Widgets de Visualización de Suscripción', () {
    testWidgets('SubscriptionCard muestra plan activo y barras de uso para el administrador', (tester) async {
      const standardSubscription = HotelSubscription(
        hotelId: 'hotel_101',
        plan: 'standard', // 50 hab / 15 users
        maxRooms: 50,
        maxUsers: 15,
        currentRooms: 12,
        currentUsers: 4,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hotelSubscriptionProvider.overrideWithValue(standardSubscription),
            currentHotelIdProvider.overrideWithValue('hotel_101'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suscripción SaaS'), findsOneWidget);
      expect(find.text('Plan Intermedio'), findsOneWidget);
      expect(find.text('INTERMEDIO'), findsOneWidget);
      expect(find.text('Habitaciones contratadas'), findsOneWidget);
      expect(find.text('Usuarios contratados'), findsOneWidget);
      expect(find.text('Solicitar cambio de plan'), findsOneWidget);
    });
  });
}

class _MockAdminAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(
      isAuthenticated: true,
      email: 'admin@hotel.com',
      name: 'Administrador Hotel',
      role: UserRole.admin,
      status: UserStatus.active,
      hotelId: 'hotel_basic_test',
    );
  }
}
