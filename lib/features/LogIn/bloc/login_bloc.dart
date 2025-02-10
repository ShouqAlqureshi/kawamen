import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_event.dart';
import 'login_state.dart';


class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BuildContext context; // Add context to the LoginBloc
  String? _email;

  LoginBloc(this.context) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<ForgotPasswordPressed>(_onForgotPasswordPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit
  ) async {
    emit(LoginLoading());
    
    try {
      _email = event.email;

      // Validate email and password
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(LoginFailure(error: 'Please enter email and password'));
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password.trim(),
      );

      Navigator.of(context).pop(userCredential);

      // If you still want to emit a success state
      emit(LoginSuccess());
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'Authentication failed. Please try again.';
      }

      emit(LoginFailure(error: errorMessage));
    } catch (e) {
      // Catch any other unexpected errors
      emit(LoginFailure(error: 'An unexpected error occurred'));
    }
  }

  Future<void> _onForgotPasswordPressed(
    ForgotPasswordPressed event, 
    Emitter<LoginState> emit
  ) async {
    try {
      // Check if email is available
      if (_email != null && _email!.isNotEmpty) {
        await _auth.sendPasswordResetEmail(email: _email!.trim());
        emit(LoginFailure(error: 'Password reset email sent'));
      } else {
        // If no email is available, emit an error
        emit(LoginFailure(error: 'Please enter your email first'));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'Password reset failed. Please try again.';
      }
      emit(LoginFailure(error: errorMessage));
    }
  }
}
