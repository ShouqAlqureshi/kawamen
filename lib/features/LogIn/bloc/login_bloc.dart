import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(LoginLoading());
      try {
        // Add your authentication logic here
        await Future.delayed(Duration(seconds: 2)); // Simulated API call
        emit(LoginSuccess());
      } catch (error) {
        emit(LoginFailure(error: error.toString()));
      }
    });

    on<ForgotPasswordPressed>((event, emit) {
      // Handle forgot password logic
    });
  }
}