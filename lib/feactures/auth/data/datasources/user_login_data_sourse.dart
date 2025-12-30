
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:message_service/core/config.dart';
import 'package:message_service/feactures/auth/data/models/user_model.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';

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
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
      print('[DEBUG] Login URL: $url');
      print('[DEBUG] Login email: $email');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      print('[DEBUG] Login response status: ${response.statusCode}');
      print('[DEBUG] Login response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception('Failed to login: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ERROR] Login failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity> updateUser(String userId, {required name, required String email, required String token}) {
   
    throw UnimplementedError();
  }
  
}