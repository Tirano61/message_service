

import 'package:message_service/features/auth/domain/entities/user.dart';

abstract class UserLoginDataSource {
  Future<User> login(String email, String password);
  Future<bool> logout();
  Future<bool> isLoggedIn();
  Future<String?> getUserToken();
  Future<bool> saveUserToken(String token);
  Future<bool> clearUserToken();
}