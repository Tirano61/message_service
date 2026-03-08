import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/auth/domain/use_cases/login_use_case.dart';
import 'package:meta/meta.dart';
import 'package:message_service/core/session_manager.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitialState()) {
    on<AuthRequestEvent>((event, emit)async {
      emit(AuthLoadingState());
      try {
        final resp  = await loginUseCase.call(event.email, event.password);
        // Clear any anonymous session when a real user logs in
        SessionManager().sessionToken = null;
        SessionManager().conversationId = null;
        emit(AuthAuthenticatedState(user: resp));
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
        
      }
      
      
    });
    on<GuestAuthenticatedEvent>((event, emit) async {
      // Save session info
      SessionManager().sessionToken = event.sessionToken;
      SessionManager().conversationId = event.conversationId;
      // HTTP-only: No socket connection needed
      emit(AuthGuestAuthenticatedState(sessionToken: event.sessionToken, conversationId: event.conversationId));
    });
    on<AuthAutoLoginEvent>((event, emit) async {
      // Rehidrata el estado autenticado con el usuario recuperado
      emit(AuthAuthenticatedState(user: event.user));
    });

    on<AuthLogoutEvent>((event, emit) async {
      await SessionManager().clearSession();
      emit(AuthInitialState());
    });
  }
}
