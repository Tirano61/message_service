
import 'package:message_service/feactures/auth/data/datasources/user_login_data_sourse.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/auth/domain/repositories/user_repositoriy.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLoginDataSource remoteDataSource;
  
  UserRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<void> createUser(String userId, String name, String email) {
    return remoteDataSource.createUser(userId, name, email);
  }

  @override
  Future<void> deleteUser(String userId) {
    return remoteDataSource.deleteUser(userId);
  }

  @override
  Future<bool> logOut(String user) {
    return remoteDataSource.logOut(user);
  }

  @override
  Future<UserEntity> login(String email, String password) {
    return remoteDataSource.login(email, password);
  }

  @override
  Future<UserEntity> updateUser(String userId, {required name, required String email, required String token}) {
    return remoteDataSource.updateUser(userId, name: name, email: email, token: token);
  }

  
}