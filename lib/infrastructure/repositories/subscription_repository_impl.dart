import 'package:hotel_app/domain/entities/hotel.dart';
import 'package:hotel_app/domain/datasource/subscription_datasource.dart';
import 'package:hotel_app/domain/repositories/subscription_repository.dart';

/// Implementación concreta de [SubscriptionRepository] delegando en [SubscriptionDataSource].
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionDataSource _dataSource;

  const SubscriptionRepositoryImpl(this._dataSource);

  @override
  Future<Hotel> getHotelSubscription(String hotelId) {
    return _dataSource.getHotelSubscription(hotelId);
  }

  @override
  Stream<Hotel> watchHotelSubscription(String hotelId) {
    return _dataSource.watchHotelSubscription(hotelId);
  }

  @override
  Future<void> requestPlanChange(
    String hotelId,
    String newPlan, {
    String? notes,
  }) {
    return _dataSource.requestPlanChange(hotelId, newPlan, notes: notes);
  }
}
