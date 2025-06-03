
// Convierte los datos del usuario a una instancia de User

import 'package:message_service/features/auth/domain/entities/user.dart';

class UserModel extends User{
  UserModel({
    required super.id, 
    required super.name, 
    required super.email, 
    required super.token, 
    required super.imageUrl
  });

  // Convierte un mapa a una instancia de UserModel
  factory UserModel.fromJson(json){
    return UserModel(
      id      : json['id'],
      name    : json['name'],
      email   : json['email'],
      token   : json['token'],
      imageUrl: json['imageUrl'] ?? '', // Maneja el caso de imageUrl nulo
    );
  }
  // Convierte una instancia de UserModel a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id'      : id,
      'name'    : name,
      'email'   : email,
      'token'   : token,
      'imageUrl': imageUrl,
    };
  }
  @override 
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, token: $token, imageUrl: $imageUrl)';
  }
  
}