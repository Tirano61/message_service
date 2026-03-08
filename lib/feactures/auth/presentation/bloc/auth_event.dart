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

class GuestAuthenticatedEvent extends AuthEvent {
  final String sessionToken;
  final String conversationId;

  GuestAuthenticatedEvent({required this.sessionToken, required this.conversationId});
}

class AuthAutoLoginEvent extends AuthEvent {
  final UserEntity user;
  AuthAutoLoginEvent({required this.user});
}

class AuthLogoutEvent extends AuthEvent {}