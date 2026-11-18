import 'package:hotel_app/domain/domain.dart';

/// Implementación concreta de [HotelOnboardingRepository] delegando en [HotelOnboardingDataSource].
class HotelOnboardingRepositoryImpl implements HotelOnboardingRepository {
  final HotelOnboardingDataSource _dataSource;

  HotelOnboardingRepositoryImpl(this._dataSource);

  @override
  Future<void> submitOnboarding(HotelOnboardingData data) {
    return _dataSource.submitOnboarding(data);
  }
}
