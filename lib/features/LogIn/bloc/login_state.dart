import 'package:firebase_auth/firebase_auth.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccessState extends LoginState {  // Changed name to LoginSuccessState
  final UserCredential userCredential;
  LoginSuccessState(this.userCredential);
}

class LoginFailure extends LoginState {
  final String error;
  LoginFailure({required this.error});
}
