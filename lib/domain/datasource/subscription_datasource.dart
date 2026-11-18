import 'package:hotel_app/domain/entities/hotel.dart';

/// Contrato abstracto para la fuente de datos de suscripción del hotel.
abstract class SubscriptionDataSource {
  /// Obtiene los datos del hotel y su suscripción por [hotelId].
  Future<Hotel> getHotelSubscription(String hotelId);

  /// Emite en tiempo real los cambios del documento del hotel.
  Stream<Hotel> watchHotelSubscription(String hotelId);

  /// Solicita un cambio de plan SaaS para el hotel.
  Future<void> requestPlanChange(String hotelId, String newPlan, {String? notes});
}
