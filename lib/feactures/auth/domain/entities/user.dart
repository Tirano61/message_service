

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

  /// Devuelve true si el usuario tiene el rol indicado.
  /// Soporta valores compuestos en `role` separados por comas, por ejemplo: 'tecnico,sales'
  bool hasRole(String r) {
    final wanted = r.toLowerCase().trim();
    final current = role
        .toLowerCase()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (current.contains('both')) return true; // valor especial aceptado

    // Valid roles declared by the server
    const allowed = ['sales', 'tecnico', 'developer', 'user'];
    if (!allowed.contains(wanted)) return false;

    // Developer has access to all role-based sections.
    if (current.contains('developer')) return true;

    return current.contains(wanted);
  }
}