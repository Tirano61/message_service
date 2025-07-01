
import 'dart:convert';
import 'package:message_service/feactures/auth/data/models/user_model.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:http/http.dart' as http;

abstract class UserLoginDataSource {
  Future<void> createUser(String userId, String name, String email);
  Future<UserEntity> updateUser(String userId, {required name, required String email, required String token});
  Future<UserEntity> login( String email, String password );
  Future<bool> logOut( String user );
  Future<void> deleteUser(String userId);
}

class UserLoginDataSourceImpl implements UserLoginDataSource {
  @override
  Future<void> createUser(String userId, String name, String email) {
    
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String userId) {
    
    throw UnimplementedError();
  }

  @override
  Future<bool> logOut(String user) {
    
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    final url = Uri.parse('http://10.0.2.2:3000/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

  @override
  Future<UserEntity> updateUser(String userId, {required name, required String email, required String token}) {
   
    throw UnimplementedError();
  }
  
}