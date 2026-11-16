import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/mappers/user_mapper.dart';

/// Implementación concreta de [EmployeesDataSource] usando Firebase Firestore.
class EmployeesDataSourceImpl implements EmployeesDataSource {
  final FirebaseFirestore _firestore;
  final String hotelId;

  EmployeesDataSourceImpl({
    FirebaseFirestore? firestore,
    this.hotelId = 'hotel_101',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<List<User>> watchEmployees() {
    return _users
        .where('hotelId', isEqualTo: hotelId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserMapper.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> updateEmployeeRoleAndStatus(
    String userId,
    UserRole newRole,
    UserStatus newStatus,
  ) async {
    await _users.doc(userId).update({
      'role': newRole.name,
      'status': newStatus.name,
    });
  }

  @override
  Future<User?> getEmployeeById(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    final docHotelId = data['hotelId'] as String?;
    if (docHotelId != null && docHotelId != hotelId) {
      return null;
    }
    return UserMapper.fromFirestore(data, doc.id);
  }

  @override
  Future<void> linkWearablePin(String userId, String pin) async {
    await _users.doc(userId).set({
      'wearablePin': pin,
      'pinCreatedAt': FieldValue.serverTimestamp(),
      'wearableLinkedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
