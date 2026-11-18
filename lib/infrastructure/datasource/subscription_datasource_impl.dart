import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/entities/hotel.dart';
import 'package:hotel_app/domain/datasource/subscription_datasource.dart';
import 'package:hotel_app/infrastructure/mappers/hotel_mapper.dart';

/// Implementación concreta de [SubscriptionDataSource] con Firebase Firestore.
class SubscriptionDataSourceImpl implements SubscriptionDataSource {
  final FirebaseFirestore _firestore;

  SubscriptionDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Hotel> getHotelSubscription(String hotelId) async {
    try {
      final doc = await _firestore.collection('hotels').doc(hotelId).get();
      if (!doc.exists || doc.data() == null) {
        return Hotel(
          id: hotelId,
          name: 'Hotel Hotelia',
          floors: 3,
          address: '',
          createdAt: DateTime.now(),
          plan: 'basic',
        );
      }
      return HotelMapper.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      // Fallback seguro ante entornos sin inicialización
      return Hotel(
        id: hotelId,
        name: 'Hotel Hotelia',
        floors: 3,
        address: '',
        createdAt: DateTime.now(),
        plan: 'basic',
      );
    }
  }

  @override
  Stream<Hotel> watchHotelSubscription(String hotelId) {
    return _firestore
        .collection('hotels')
        .doc(hotelId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return Hotel(
          id: hotelId,
          name: 'Hotel Hotelia',
          floors: 3,
          address: '',
          createdAt: DateTime.now(),
          plan: 'basic',
        );
      }
      return HotelMapper.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> requestPlanChange(
    String hotelId,
    String newPlan, {
    String? notes,
  }) async {
    final hotelRef = _firestore.collection('hotels').doc(hotelId);
    await hotelRef.set({
      'requestedPlan': newPlan,
      'planChangeRequestedAt': FieldValue.serverTimestamp(),
      if (notes != null && notes.isNotEmpty) 'planChangeNotes': notes,
    }, SetOptions(merge: true));

    // Registrar en auditoría
    final logId = 'audit-${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('audit_logs').doc(logId).set({
      'id': logId,
      'action': 'REQUEST_PLAN_CHANGE',
      'description':
          'Solicitud de cambio a plan "$newPlan" para el hotel $hotelId',
      'hotelId': hotelId,
      'targetId': hotelId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
