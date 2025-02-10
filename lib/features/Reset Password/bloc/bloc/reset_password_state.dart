part of 'reset_password_bloc.dart';
enum ResetPasswordStatus { 
  initial, 
  submitting, 
  requiresReauth,
  success, 
  error 
}

class ResetPasswordState {
  final String email;
  final ResetPasswordStatus status;
  final String? errorMessage;
  final UserCredential? credential;

  const ResetPasswordState({
    this.email = '',
    this.status = ResetPasswordStatus.initial,
    this.errorMessage,
    this.credential,
  });

  ResetPasswordState copyWith({
    String? email,
    ResetPasswordStatus? status,
    String? errorMessage,
    UserCredential? credential,
  }) {
    return ResetPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      credential: credential ?? this.credential,
    );
  }
}
