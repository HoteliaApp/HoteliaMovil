import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_app/domain/domain.dart';

/// Mapper para convertir entre datos de Firestore y la entidad de dominio [User].
class UserMapper {
  UserMapper._();

  /// Convierte un documento/mapa de Firestore a la entidad [User].
  static User fromFirestore(Map<String, dynamic> data, String id) {
    final roleStr = data['role'] as String? ?? 'unassigned';
    final statusStr = data['status'] as String? ?? 'active';

    DateTime createdAt;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return User(
      id: id,
      name: data['name'] as String? ?? 'Desconocido',
      email: data['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => UserRole.unassigned,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => UserStatus.pending,
      ),
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: createdAt,
    );
  }

  /// Convierte una entidad [User] a un mapa para Firestore.
  static Map<String, dynamic> toFirestore(User user) {
    return {
      'name': user.name,
      'email': user.email,
      'role': user.role.name,
      'status': user.status.name,
      if (user.avatarUrl != null) 'avatarUrl': user.avatarUrl,
      'createdAt': Timestamp.fromDate(user.createdAt),
    };
  }
}
