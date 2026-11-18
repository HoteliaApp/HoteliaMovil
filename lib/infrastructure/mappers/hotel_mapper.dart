import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/entities/hotel.dart';

/// Mapper para convertir entre datos de Firestore y la entidad de dominio [Hotel].
class HotelMapper {
  HotelMapper._();

  static Hotel fromFirestore(Map<String, dynamic> data, String id) {
    DateTime createdAt;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    DateTime? planChangeRequestedAt;
    final rawPlanReq = data['planChangeRequestedAt'];
    if (rawPlanReq is Timestamp) {
      planChangeRequestedAt = rawPlanReq.toDate();
    } else if (rawPlanReq is String) {
      planChangeRequestedAt = DateTime.tryParse(rawPlanReq);
    }

    return Hotel(
      id: id,
      name: data['name'] as String? ?? 'Hotel Sin Nombre',
      floors: (data['floors'] as num?)?.toInt() ?? 1,
      address: data['address'] as String? ?? '',
      createdAt: createdAt,
      plan: data['plan'] as String? ?? 'standard',
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 2,
      customMaxRooms: (data['maxRooms'] as num?)?.toInt(),
      customMaxUsers: (data['maxUsers'] as num?)?.toInt(),
      requestedPlan: data['requestedPlan'] as String?,
      planChangeRequestedAt: planChangeRequestedAt,
    );
  }

  static Map<String, dynamic> toFirestore(Hotel hotel) {
    return {
      'id': hotel.id,
      'name': hotel.name,
      'floors': hotel.floors,
      'address': hotel.address,
      'createdAt': hotel.createdAt.toIso8601String(),
      'plan': hotel.plan,
      'schemaVersion': hotel.schemaVersion,
      if (hotel.customMaxRooms != null) 'maxRooms': hotel.customMaxRooms,
      if (hotel.customMaxUsers != null) 'maxUsers': hotel.customMaxUsers,
      if (hotel.requestedPlan != null) 'requestedPlan': hotel.requestedPlan,
      if (hotel.planChangeRequestedAt != null)
        'planChangeRequestedAt':
            hotel.planChangeRequestedAt!.toIso8601String(),
    };
  }
}
