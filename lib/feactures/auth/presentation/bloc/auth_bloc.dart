import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/auth/domain/use_cases/login_use_case.dart';
import 'package:meta/meta.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/core/services/socket_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitialState()) {
    on<AuthRequestEvent>((event, emit)async {
      emit(AuthLoadingState());
      try {
        final resp  = await loginUseCase.call(event.email, event.password);
        if (resp != null) {
          // Clear any anonymous session when a real user logs in
          SessionManager().sessionToken = null;
          SessionManager().conversationId = null;
          emit(AuthAuthenticatedState(user: resp));
        } else {
          emit(AuthErrorState(message: "Login failed"));
        }
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
        
      }
      
      
    });
    on<GuestAuthenticatedEvent>((event, emit) async {
      // Save session info and connect socket
      SessionManager().sessionToken = event.sessionToken;
      SessionManager().conversationId = event.conversationId;
      try {
  // For anonymous session, pass empty token so SocketService reads from SessionManager
  SocketService().connect(token: '');
      } catch (_) {}
      emit(AuthGuestAuthenticatedState(sessionToken: event.sessionToken, conversationId: event.conversationId));
    });
  }
}
