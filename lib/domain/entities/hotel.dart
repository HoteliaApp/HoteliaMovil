/// Entidad de dominio que representa a un inquilino (Hotel) en la arquitectura multi-tenant.
class Hotel {
  static const int currentSchemaVersion = 2;

  final String id;
  final String name;
  final int floors;
  final String address;
  final DateTime createdAt;
  final String plan; // 'basic' | 'standard' | 'premium'
  final int schemaVersion;

  const Hotel({
    required this.id,
    required this.name,
    required this.floors,
    required this.address,
    required this.createdAt,
    this.plan = 'standard',
    this.schemaVersion = currentSchemaVersion,
  });

  Hotel copyWith({
    String? id,
    String? name,
    int? floors,
    String? address,
    DateTime? createdAt,
    String? plan,
    int? schemaVersion,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      floors: floors ?? this.floors,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      plan: plan ?? this.plan,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  String toString() => 'Hotel(id: $id, name: $name, plan: $plan, floors: $floors)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Hotel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
