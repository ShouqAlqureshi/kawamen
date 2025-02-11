import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final FirebaseAuth _firebaseAuth;

  ResetPasswordBloc({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const ResetPasswordState()) {
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<ResetPasswordReauthenticationComplete>(_onReauthenticationComplete);
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (event.email.isEmpty) {
      emit(state.copyWith(
        status: ResetPasswordStatus.error,
        errorMessage: 'Please enter an email address',
      ));
      return;
    }

    emit(state.copyWith(
      status: ResetPasswordStatus.submitting,
      email: event.email,
    ));

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: event.email);
      emit(state.copyWith(status: ResetPasswordStatus.success));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        emit(state.copyWith(status: ResetPasswordStatus.requiresReauth));
      } else {
        emit(state.copyWith(
          status: ResetPasswordStatus.error,
          errorMessage: _getErrorMessage(e),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ResetPasswordStatus.error,
        errorMessage: 'An unexpected error occurred',
      ));
    }
  }

  Future<void> _onReauthenticationComplete(
    ResetPasswordReauthenticationComplete event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(state.copyWith(
      status: ResetPasswordStatus.submitting,
      credential: event.credential,
    ));

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user
            .reauthenticateWithCredential(event.credential as AuthCredential);
        await _firebaseAuth.sendPasswordResetEmail(email: state.email);
        emit(state.copyWith(status: ResetPasswordStatus.success));
      } else {
        throw Exception('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: ResetPasswordStatus.error,
        errorMessage: _getErrorMessage(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ResetPasswordStatus.error,
        errorMessage: 'An unexpected error occurred',
      ));
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid: $e';
      case 'user-not-found':
        return 'No user found with this email address: $e';
      case 'requires-recent-login':
        return 'Please sign in again to continue: $e';
      default:
        return 'Failed to send reset password email: $e';
    }
  }
}
