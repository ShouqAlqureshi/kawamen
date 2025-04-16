import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<RegisterUser>(_onRegisterUser);
    on<LoginUser>(_onLoginUser);
    on<LogoutUser>(_onLogoutUser);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  // Handle User Registration
  Future<void> _onRegisterUser(
      RegisterUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.registerUser(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        age: event.age,
      );
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  // Handle User Login
  Future<void> _onLoginUser(LoginUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(  // Changed loginUser to signIn to match repository
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await _authRepository.isUserAuthenticated();
      if (isAuthenticated) {
        emit(AuthSuccess());
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
  // Handle User Logout
  Future<void> _onLogoutUser(LogoutUser event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.signOut();  // Changed logout to signOut to match repository
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
}