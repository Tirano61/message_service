
// Convierte los datos del usuario a una instancia de User

import 'package:message_service/feactures/auth/domain/entities/user.dart';

class UserModel extends UserEntity{
  UserModel({
    required super.id, 
    required super.fullName, 
    required super.email, 
  required super.token,
  required super.role,
  });

  // Convierte un mapa a una instancia de UserModel
  factory UserModel.fromJson(json){
    // El servidor devuelve siempre `roles` como array. Extraemos y normalizamos
    const allowed = ['sales', 'tecnico', 'user'];
    String roleValue = 'user';

    final dynamic rolesField = json != null ? json['roles'] : null;
    if (rolesField is List) {
      final extracted = rolesField
          .map((e) => e.toString().toLowerCase().trim())
          .where((r) => allowed.contains(r))
          .toList();
      if (extracted.isNotEmpty) {
        roleValue = extracted.join(',');
      }
    }

    return UserModel(
      id      : json['id'],
      fullName: json['fullName'],
      email   : json['email'],
      token   : json['token'],
      role    : roleValue,
    );
  }
  // Convierte una instancia de UserModel a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id'      : id,
      'fullName': fullName,
      'email'   : email,
      'token'   : token,
      'role'    : role,

    };
  }
  @override 
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, token: $token, role: $role)';
  }
  
}