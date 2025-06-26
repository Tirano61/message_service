
// Convierte los datos del usuario a una instancia de User

import 'package:message_service/feactures/auth/domain/entities/user.dart';

class UserModel extends User{
  UserModel({
    required super.id, 
    required super.fullName, 
    required super.email, 
    required super.token,    
  });

  // Convierte un mapa a una instancia de UserModel
  factory UserModel.fromJson(json){
    return UserModel(
      id      : json['id'],
      fullName: json['fullName'],
      email   : json['email'],
      token   : json['token'],
// Maneja el caso de imageUrl nulo
    );
  }
  // Convierte una instancia de UserModel a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id'      : id,
      'fullName': fullName,
      'email'   : email,
      'token'   : token,

    };
  }
  @override 
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, token: $token)';
  }
  
}