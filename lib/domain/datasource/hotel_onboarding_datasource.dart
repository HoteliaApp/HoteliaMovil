import 'package:hotel_app/domain/entities/hotel_onboarding_data.dart';

/// Contrato del DataSource para persistir el onboarding inicial de un hotel.
abstract class HotelOnboardingDataSource {
  /// Registra el hotel, sus habitaciones generadas, los usuarios iniciales
  /// y actualiza el perfil del dueño en Firestore.
  Future<void> submitOnboarding(HotelOnboardingData data);
}
