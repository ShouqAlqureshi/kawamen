part of 'reset_password_bloc.dart';

sealed class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object> get props => [];
}
class ResetPasswordSubmitted extends ResetPasswordEvent {
  final String email;
  const ResetPasswordSubmitted(this.email);
}
class ResetPasswordReauthenticationComplete extends ResetPasswordEvent {
  final UserCredential credential;
  const ResetPasswordReauthenticationComplete(this.credential);
}
