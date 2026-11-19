import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/mappers/room_mapper.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';

/// Implementación concreta de [RoomsDataSource] usando Firebase Firestore.
class RoomsDataSourceImpl implements RoomsDataSource {
  final FirebaseFirestore _firestore;
  final String hotelId;

  RoomsDataSourceImpl(this._firestore, {this.hotelId = 'hotel_101'});

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  @override
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type}) async {
    try {
      Query<Map<String, dynamic>> query =
          _rooms.where('hotelId', isEqualTo: hotelId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (type != null) {
        query = query.where('roomType', isEqualTo: type.name);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await query.get();
      } catch (e) {
        // Fallback a caché local de Firestore cuando no hay red (H-31)
        snapshot = await query.get(const GetOptions(source: Source.cache));
      }

      final rooms = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RoomMapper.fromJson(data);
      }).toList();

      return rooms;
    } catch (e) {
      throw Exception('Error al obtener habitaciones de Firebase: $e');
    }
  }

  @override
  Future<Room> getRoomById(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _rooms.doc(id).get();
      } catch (_) {
        doc = await _rooms.doc(id).get(const GetOptions(source: Source.cache));
      }

      if (!doc.exists) throw Exception('Habitación no encontrada');
      
      final data = doc.data()!;
      final docHotelId = data['hotelId'] as String?;
      if (docHotelId != null && docHotelId != hotelId) {
        throw Exception('La habitación no pertenece a este hotel');
      }

      data['id'] = doc.id;
      return RoomMapper.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener habitación: $e');
    }
  }

  @override
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus) async {
    try {
      await getRoomById(id);
      await _rooms.doc(id).update({'status': newStatus.name});
      return await getRoomById(id);
    } catch (e) {
      throw Exception('Error al actualizar habitación: $e');
    }
  }

  @override
  Future<bool> markRoomCleanedIfPending(String roomId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final ref = _rooms.doc(roomId);
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) return false;

        final data = snapshot.data();

        // Aislamiento multi-inquilino (#24): no tocar habitaciones de otro hotel.
        final docHotelId = data?['hotelId'] as String?;
        if (docHotelId != null && docHotelId != hotelId) return false;

        final current = data?['status'] as String?;

        // Idempotencia por estado: solo avanza desde los estados de limpieza.
        // Si la habitación ya está limpia, ocupada o disponible, no se toca.
        final isPending = current == RoomStatus.pendingCleaning.name ||
            current == RoomStatus.cleaning.name;

        if (!isPending) return false;

        transaction.update(ref, {'status': RoomStatus.cleaned.name});
        return true;
      });
    } catch (e) {
      throw Exception('Error al cerrar el ciclo de limpieza: $e');
    }
  }

  @override
  Stream<List<Room>> watchRooms({RoomStatus? status, RoomType? type}) {
    Query<Map<String, dynamic>> query =
        _rooms.where('hotelId', isEqualTo: hotelId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (type != null) {
      query = query.where('roomType', isEqualTo: type.name);
    }

    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RoomMapper.fromJson(data);
      }).toList();
    });
  }

  /// Método para poblar la base de datos con cuartos fijos si está vacía para este hotel
  Future<void> seedRoomsIfEmpty() async {
    final snapshot =
        await _rooms.where('hotelId', isEqualTo: hotelId).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final idSuffix = hotelId == 'hotel_101' ? '' : '-$hotelId';

    final defaultRooms = [
      RoomModel(id: 'room-101$idSuffix', roomNumber: 101, roomType: 'single', status: 'available', pricePerNight: 50.0, description: 'Habitación Sencilla Estándar', images: [RoomModel.defaultRoomImageUrl(101)], capacity: 1, amenities: ['TV', 'WiFi'], hotelId: hotelId),
      RoomModel(id: 'room-102$idSuffix', roomNumber: 102, roomType: 'single', status: 'available', pricePerNight: 50.0, description: 'Habitación Sencilla Estándar', images: [RoomModel.defaultRoomImageUrl(102)], capacity: 1, amenities: ['TV', 'WiFi'], hotelId: hotelId),
      RoomModel(id: 'room-103$idSuffix', roomNumber: 103, roomType: 'double', status: 'available', pricePerNight: 80.0, description: 'Habitación Doble Estándar', images: [RoomModel.defaultRoomImageUrl(103)], capacity: 2, amenities: ['TV', 'WiFi', 'AC'], hotelId: hotelId),
      RoomModel(id: 'room-104$idSuffix', roomNumber: 104, roomType: 'double', status: 'available', pricePerNight: 80.0, description: 'Habitación Doble Estándar', images: [RoomModel.defaultRoomImageUrl(104)], capacity: 2, amenities: ['TV', 'WiFi', 'AC'], hotelId: hotelId),
      RoomModel(id: 'room-201$idSuffix', roomNumber: 201, roomType: 'suite', status: 'available', pricePerNight: 150.0, description: 'Suite Principal con Vista', images: [RoomModel.defaultRoomImageUrl(201)], capacity: 4, amenities: ['TV', 'WiFi', 'AC', 'Minibar', 'Jacuzzi'], hotelId: hotelId),
      RoomModel(id: 'room-202$idSuffix', roomNumber: 202, roomType: 'suite', status: 'available', pricePerNight: 150.0, description: 'Suite Principal con Vista', images: [RoomModel.defaultRoomImageUrl(202)], capacity: 4, amenities: ['TV', 'WiFi', 'AC', 'Minibar', 'Jacuzzi'], hotelId: hotelId),
      RoomModel(id: 'room-301$idSuffix', roomNumber: 301, roomType: 'deluxe', status: 'available', pricePerNight: 120.0, description: 'Habitación Deluxe', images: [RoomModel.defaultRoomImageUrl(301)], capacity: 3, amenities: ['TV', 'WiFi', 'AC', 'Minibar'], hotelId: hotelId),
      RoomModel(id: 'room-302$idSuffix', roomNumber: 302, roomType: 'deluxe', status: 'available', pricePerNight: 120.0, description: 'Habitación Deluxe', images: [RoomModel.defaultRoomImageUrl(302)], capacity: 3, amenities: ['TV', 'WiFi', 'AC', 'Minibar'], hotelId: hotelId),
      RoomModel(id: 'room-401$idSuffix', roomNumber: 401, roomType: 'penthouse', status: 'available', pricePerNight: 300.0, description: 'Penthouse Exclusivo', images: [RoomModel.defaultRoomImageUrl(401)], capacity: 6, amenities: ['TV', 'WiFi', 'AC', 'Minibar', 'Jacuzzi', 'Cocina', 'Terraza'], hotelId: hotelId),
      RoomModel(id: 'room-402$idSuffix', roomNumber: 402, roomType: 'penthouse', status: 'available', pricePerNight: 300.0, description: 'Penthouse Exclusivo', images: [RoomModel.defaultRoomImageUrl(402)], capacity: 6, amenities: ['TV', 'WiFi', 'AC', 'Minibar', 'Jacuzzi', 'Cocina', 'Terraza'], hotelId: hotelId),
    ];

    for (var room in defaultRooms) {
      await _rooms.doc(room.id).set(room.toJson());
    }
  }

  @override
  Future<void> createRoom(Room room) async {
    try {
      final finalHotelId = room.hotelId.isNotEmpty ? room.hotelId : hotelId;
      final roomId = room.id.isNotEmpty
          ? room.id
          : 'room-${room.roomNumber}-$finalHotelId';
      final model = RoomModel.fromEntity(room.copyWith(
        id: roomId,
        hotelId: finalHotelId,
      ));
      await _rooms.doc(roomId).set(model.toJson());
    } catch (e) {
      throw Exception('Error al registrar habitación: $e');
    }
  }
}
