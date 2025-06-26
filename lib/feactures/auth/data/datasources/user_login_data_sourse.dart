

import 'package:message_service/feactures/auth/domain/entities/user.dart';

abstract class UserLoginDataSource {
  Future<void> createUser(String userId, String name, String email);
  Future<User> updateUser(String userId, {required name, required String email, required String token});
  Future<User> login( String email, String password );
  Future<bool> logOut( String user );
  Future<void> deleteUser(String userId);
}

class UserLoginDataSourceImpl implements UserLoginDataSource {
  @override
  Future<void> createUser(String userId, String name, String email) {
    // TODO: implement createUser
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String userId) {
    // TODO: implement deleteUser
    throw UnimplementedError();
  }

  @override
  Future<bool> logOut(String user) {
    // TODO: implement logOut
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) {

    
    return Future.value(User(
      id: '123',
      fullName: 'Test User',
      email: email,
      token: 'test_token',
    ));
  }

  @override
  Future<User> updateUser(String userId, {required name, required String email, required String token}) {
    // TODO: implement updateUser
    throw UnimplementedError();
  }
  
}