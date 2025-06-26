

class User {
  final String id;
  final String fullName;
  final String email;
  final String token;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.token,
  });

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, token: $token)';
  }
}