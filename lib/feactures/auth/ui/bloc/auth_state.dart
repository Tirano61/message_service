part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitialState extends AuthState {}

final class AuthLoadingState extends AuthState {}
final class AuthAuthenticatedState extends AuthState {}
final class AuthErrorState extends AuthState {
  final String message;

  AuthErrorState({required this.message});  
  @override
  String toString() => 'AuthErrorState(message: $message)';
}