

class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String token;
  final String role; // 'user' o 'tecnico'

  UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.token,
    required this.role,
  });

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, token: $token, role: $role)';
  }
}