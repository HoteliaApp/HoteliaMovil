import 'package:hotel_app/domain/domain.dart';

/// Implementación concreta de [RoomsRepository].
/// Delega las operaciones al [RoomsDataSource] (API remota).
class RoomsRepositoryImpl implements RoomsRepository {
  final RoomsDataSource _dataSource;

  const RoomsRepositoryImpl(this._dataSource);

  @override
  Future<List<Room>> getRooms({RoomStatus? status, RoomType? type}) {
    return _dataSource.getRooms(status: status, type: type);
  }

  @override
  Future<Room> getRoomById(String id) {
    return _dataSource.getRoomById(id);
  }

  @override
  Future<Room> updateRoomStatus(String id, RoomStatus newStatus) {
    return _dataSource.updateRoomStatus(id, newStatus);
  }

  @override
  Stream<List<Room>> watchRooms({RoomStatus? status, RoomType? type}) {
    return _dataSource.watchRooms(status: status, type: type);
  }
}
