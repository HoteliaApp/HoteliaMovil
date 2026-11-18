import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/mappers/hotel_mapper.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';

/// Implementación concreta de [HotelOnboardingDataSource] usando Firebase Firestore con WriteBatch.
class HotelOnboardingDataSourceImpl implements HotelOnboardingDataSource {
  final FirebaseFirestore _firestore;

  HotelOnboardingDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitOnboarding(HotelOnboardingData data) async {
    try {
      final hotelId = data.hotel.id;
      final hotelRef = _firestore.collection('hotels').doc(hotelId);

      // 1. Validar que el hotel no exista previamente
      final existingDoc = await hotelRef.get();
      if (existingDoc.exists) {
        throw Exception('El identificador del hotel "$hotelId" ya está en uso. Por favor elige otro.');
      }

      // Preparar lotes de escritura (Firestore soporta máx 500 operaciones por batch)
      const maxBatchSize = 400;
      WriteBatch currentBatch = _firestore.batch();
      int operationCount = 0;

      Future<void> checkBatchThreshold() async {
        operationCount++;
        if (operationCount >= maxBatchSize) {
          await currentBatch.commit();
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
      }

      // A. Registrar el hotel
      currentBatch.set(hotelRef, HotelMapper.toFirestore(data.hotel));
      await checkBatchThreshold();

      // B. Registrar las habitaciones generadas
      final rooms = data.allRooms;
      for (final room in rooms) {
        final roomRef = _firestore.collection('rooms').doc(room.id);
        final roomModel = RoomModel.fromEntity(room);
        currentBatch.set(roomRef, roomModel.toJson());
        await checkBatchThreshold();
      }

      // C. Registrar o actualizar al Dueño como Administrador activo
      final ownerRef = _firestore.collection('users').doc(data.ownerId);
      currentBatch.set(
        ownerRef,
        {
          'id': data.ownerId,
          'name': data.ownerName,
          'email': data.ownerEmail,
          'role': UserRole.admin.name,
          'status': UserStatus.active.name,
          'hotelId': hotelId,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await checkBatchThreshold();

      // D. Registrar los usuarios iniciales del personal
      for (int i = 0; i < data.initialStaff.length; i++) {
        final staff = data.initialStaff[i];
        final staffDocId = 'staff-${DateTime.now().millisecondsSinceEpoch}-$i';
        final staffRef = _firestore.collection('users').doc(staffDocId);
        currentBatch.set(staffRef, {
          'id': staffDocId,
          'name': staff.name,
          'email': staff.email,
          'role': staff.role.name,
          'status': UserStatus.active.name,
          'hotelId': hotelId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await checkBatchThreshold();
      }

      // E. Bitácora de Auditoría
      final auditLogId = 'audit-${DateTime.now().millisecondsSinceEpoch}';
      final auditRef = _firestore.collection('audit_logs').doc(auditLogId);
      currentBatch.set(auditRef, {
        'id': auditLogId,
        'action': 'HOTEL_ONBOARDING',
        'description':
            'Alta inicial del hotel "${data.hotel.name}" con ${rooms.length} habitaciones y ${data.initialStaff.length} usuarios iniciales.',
        'performedBy': data.ownerEmail,
        'targetId': hotelId,
        'hotelId': hotelId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      operationCount++;

      // Commit final del lote
      if (operationCount > 0) {
        await currentBatch.commit();
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al registrar el hotel en Firestore: $e');
    }
  }
}
