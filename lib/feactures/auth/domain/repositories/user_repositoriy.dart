

import 'package:message_service/feactures/auth/domain/entities/user.dart';

abstract class UserRepository {
  Future<void> createUser(String userId, String name, String email);
  Future<User> updateUser(String userId, {required name, required String email, required String token});
  Future<User> login( String email, String password );
  Future<bool> logOut( String user );
  Future<void> deleteUser(String userId);
}