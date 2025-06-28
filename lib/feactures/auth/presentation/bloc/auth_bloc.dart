import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/auth/domain/use_cases/login_use_case.dart';
import 'package:meta/meta.dart';

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
          emit(AuthAuthenticatedState(user: resp));
        } else {
          emit(AuthErrorState(message: "Login failed"));
        }
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
        
      }
      
      
    });
  }
}
