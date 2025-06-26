import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/auth/domain/use_cases/login_use_case.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitialState()) {
    on<AuthRequestEvent>((event, emit) {
      emit(AuthLoadingState());
      try {
        final resp = loginUseCase.call(event.email, event.password);
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
        
      }
      
      
    });
  }
}
