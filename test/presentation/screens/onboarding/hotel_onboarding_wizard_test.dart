import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/onboarding/hotel_onboarding_provider.dart';
import 'package:hotel_app/presentation/screens/onboarding/hotel_onboarding_wizard_screen.dart';

class _FakeOnboardingRepository implements HotelOnboardingRepository {
  HotelOnboardingData? submittedData;

  @override
  Future<void> submitOnboarding(HotelOnboardingData data) async {
    submittedData = data;
  }
}

void main() {
  group('H-25 Dominio y Generación de Habitaciones', () {
    test('FloorConfig genera habitaciones estructuradas con su hotelId correspondiente', () {
      const config = FloorConfig(
        floorNumber: 2,
        roomCount: 3,
        roomType: RoomType.suite,
        pricePerNight: 160.0,
        capacity: 4,
        amenities: ['WiFi', 'TV', 'AC', 'Jacuzzi'],
      );

      final rooms = config.generateRooms('hotel_paraiso');

      expect(rooms.length, equals(3));

      // Piso 2 genera 201, 202, 203
      expect(rooms[0].roomNumber, equals(201));
      expect(rooms[0].id, equals('room-201-hotel_paraiso'));
      expect(rooms[0].roomType, equals(RoomType.suite));
      expect(rooms[0].pricePerNight, equals(160.0));
      expect(rooms[0].capacity, equals(4));
      expect(rooms[0].amenities, contains('Jacuzzi'));
      expect(rooms[0].hotelId, equals('hotel_paraiso'));
      expect(rooms[0].status, equals(RoomStatus.available));

      expect(rooms[1].roomNumber, equals(202));
      expect(rooms[2].roomNumber, equals(203));
    });

    test('HotelOnboardingNotifier genera slugs canónicos para hotelId', () {
      expect(
        HotelOnboardingNotifier.generateHotelIdSlug('Gran Hotel Paraíso & Spa'),
        equals('hotel_gran_hotel_paraiso_spa'),
      );
      expect(
        HotelOnboardingNotifier.generateHotelIdSlug('Hotel Cancún'),
        equals('hotel_cancun'),
      );
      expect(
        HotelOnboardingNotifier.generateHotelIdSlug('hotel_sol_mar'),
        equals('hotel_sol_mar'),
      );
    });
  });

  group('H-25 Criterios de Aceptación Gherkin: Wizard de 3 Pasos', () {
    test(
      'Escenario 1 (Gherkin): Dado un dueño de nuevo hotel, cuando completa pisos, tipos y amenities, entonces genera la estructura inicial con hotelId',
      () async {
        final fakeRepo = _FakeOnboardingRepository();
        final container = ProviderContainer(
          overrides: [
            hotelOnboardingRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(hotelOnboardingProvider.notifier);

        // ── Paso 1: Datos del Hotel ──
        expect(container.read(hotelOnboardingProvider).currentStep, equals(0));

        notifier.setHotelName('Hotel del Sol');
        notifier.setHotelAddress('Av. Del Mar 777');
        notifier.setFloorsCount(2);
        notifier.setPlan('premium');

        final step1State = container.read(hotelOnboardingProvider);
        expect(step1State.hotelId, equals('hotel_del_sol'));
        expect(step1State.floorsConfig.length, equals(2));

        // Avanzar a Paso 2
        notifier.nextStep();
        expect(container.read(hotelOnboardingProvider).currentStep, equals(1));

        // ── Paso 2: Pisos, Tipos de Habitación y Amenities ──
        notifier.updateFloorConfig(
          0,
          const FloorConfig(
            floorNumber: 1,
            roomCount: 2,
            roomType: RoomType.single,
            pricePerNight: 70.0,
            capacity: 1,
            amenities: ['WiFi', 'TV'],
          ),
        );
        notifier.updateFloorConfig(
          1,
          const FloorConfig(
            floorNumber: 2,
            roomCount: 2,
            roomType: RoomType.suite,
            pricePerNight: 180.0,
            capacity: 4,
            amenities: ['WiFi', 'TV', 'AC', 'Minibar', 'Jacuzzi'],
          ),
        );

        final step2State = container.read(hotelOnboardingProvider);
        expect(step2State.totalRoomsCount, equals(4));

        // Avanzar a Paso 3
        notifier.nextStep();
        expect(container.read(hotelOnboardingProvider).currentStep, equals(2));

        // ── Paso 3: Creación de Usuarios Iniciales ──
        notifier.addStaff(
          const InitialStaffUser(
            name: 'Carlos Recepción',
            email: 'carlos@hoteldelsol.com',
            role: UserRole.receptionist,
          ),
        );

        // Envío final del onboarding
        await notifier.submitOnboarding(
          ownerId: 'owner-uuid-123',
          ownerName: 'Monse Castañón',
          ownerEmail: 'monse@hoteldelsol.com',
        );

        // ── Verificación del resultado en Firestore (Criterio de Aceptación) ──
        final submitted = fakeRepo.submittedData;
        expect(submitted, isNotNull);

        // 1. Hotel registrado con su hotelId correspondiente
        expect(submitted!.hotel.id, equals('hotel_del_sol'));
        expect(submitted.hotel.name, equals('Hotel del Sol'));
        expect(submitted.hotel.floors, equals(2));
        expect(submitted.hotel.plan, equals('premium'));
        expect(submitted.hotel.schemaVersion, equals(2));

        // 2. Dueño registrado como Admin
        expect(submitted.ownerId, equals('owner-uuid-123'));
        expect(submitted.ownerName, equals('Monse Castañón'));
        expect(submitted.ownerEmail, equals('monse@hoteldelsol.com'));

        // 3. Estructura de habitaciones generada con su hotelId correspondiente
        final rooms = submitted.allRooms;
        expect(rooms.length, equals(4));

        // Piso 1: 101, 102
        expect(rooms[0].roomNumber, equals(101));
        expect(rooms[0].hotelId, equals('hotel_del_sol'));
        expect(rooms[0].roomType, equals(RoomType.single));
        expect(rooms[0].pricePerNight, equals(70.0));
        expect(rooms[0].amenities, equals(['WiFi', 'TV']));

        expect(rooms[1].roomNumber, equals(102));
        expect(rooms[1].hotelId, equals('hotel_del_sol'));

        // Piso 2: 201, 202
        expect(rooms[2].roomNumber, equals(201));
        expect(rooms[2].hotelId, equals('hotel_del_sol'));
        expect(rooms[2].roomType, equals(RoomType.suite));
        expect(rooms[2].pricePerNight, equals(180.0));
        expect(rooms[2].amenities, contains('Jacuzzi'));

        expect(rooms[3].roomNumber, equals(202));
        expect(rooms[3].hotelId, equals('hotel_del_sol'));

        // 4. Usuarios iniciales
        expect(submitted.initialStaff.any((u) => u.name == 'Carlos Recepción'), isTrue);

        // 5. Estado del provider refleja éxito
        expect(container.read(hotelOnboardingProvider).isSuccess, isTrue);
      },
    );

    test('Validaciones de formulario impiden avanzar con datos incompletos', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(hotelOnboardingProvider.notifier);

      // Paso 1 vacío no permite avanzar
      expect(notifier.validateCurrentStep(), isFalse);
      expect(container.read(hotelOnboardingProvider).errorMessage, isNotNull);

      // Llenar datos paso 1
      notifier.setHotelName('Hotel Plaza');
      notifier.setHotelAddress('Calle 10 # 45');
      expect(notifier.validateCurrentStep(), isTrue);
      notifier.nextStep();
      expect(container.read(hotelOnboardingProvider).currentStep, equals(1));

      // Piso con precio 0 no permite avanzar
      notifier.updateFloorConfig(
        0,
        const FloorConfig(floorNumber: 1, roomCount: 2, pricePerNight: 0),
      );
      expect(notifier.validateCurrentStep(), isFalse);
      expect(
        container.read(hotelOnboardingProvider).errorMessage,
        contains('debe ser mayor a 0'),
      );
    });
  });

  group('H-25 UI Widget: HotelOnboardingWizardScreen', () {
    testWidgets('Renderiza el asistente y permite navegar entre los pasos', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HotelOnboardingWizardScreen(),
          ),
        ),
      );

      // Verificación de título y paso 1 inicial
      expect(find.text('Asistente de Onboarding SaaS'), findsOneWidget);
      expect(find.text('1. Datos del Hotel'), findsOneWidget);
      expect(find.text('Paso 1: Datos Generales del Hotel'), findsOneWidget);

      // Ingresar nombre y dirección
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre comercial del hotel *'),
        'Hotel Los Pinos',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Dirección física *'),
        'Carretera Sur Km 5',
      );
      await tester.pumpAndSettle();

      // Verificar que el hotelId se autogeneró
      expect(find.text('hotel_los_pinos'), findsOneWidget);

      // Presionar Siguiente
      await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
      await tester.pumpAndSettle();

      // Debe estar en el Paso 2
      expect(find.text('Paso 2: Pisos, Tipos y Amenities'), findsOneWidget);
      expect(find.text('Generación rápida'), findsOneWidget);

      // Presionar Siguiente a Paso 3
      await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
      await tester.pumpAndSettle();

      // Debe estar en el Paso 3
      expect(find.text('Paso 3: Creación de Usuarios Iniciales'), findsOneWidget);
      expect(find.text('Finalizar y dar de alta hotel'), findsOneWidget);
    });
  });
}
