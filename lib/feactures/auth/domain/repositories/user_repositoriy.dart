

import 'package:message_service/feactures/auth/domain/entities/user.dart';

abstract class UserRepository {
  Future<void> createUser(String userId, String name, String email);
  Future<UserEntity> updateUser(String userId, {required name, required String email, required String token});
  Future<UserEntity> login( String email, String password );
  Future<bool> logOut( String user );
  Future<void> deleteUser(String userId);
}