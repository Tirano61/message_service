

import 'package:message_service/features/auth/domain/entities/user.dart';
import 'package:message_service/features/auth/domain/repositories/user_repositoriy.dart';

class LoginUseCase {
  
  final UserRepository userRepository;
  LoginUseCase({required this.userRepository});

  Future<User> call( String email, String password ) async {

    return await userRepository.login(email, password);
  }
}