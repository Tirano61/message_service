

class User {
  final String id;
  final String name;
  final String email;
  final String token;
  final String? imageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    required this.imageUrl,
  });

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, token: $token, imageUrl: $imageUrl)';
  }
}