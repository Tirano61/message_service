part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}



class AuthRequestEvent extends AuthEvent {
  final String email;
  final String password;

  AuthRequestEvent({
    required this.email,
    required this.password,
  });

}