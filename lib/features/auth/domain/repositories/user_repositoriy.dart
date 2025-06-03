

import 'package:message_service/domain/entities/user.dart';

abstract class UserRepository {
  Future<void> createUser(String userId, String name, String email);
  Future<User> updateUser(String userId, {required name, required String email, required String token});
  Future<User> getUser(String userId);
  Future<void> deleteUser(String userId);
}