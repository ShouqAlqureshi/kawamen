// features/registration/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// Event for user registration
class RegisterUser extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final int age; // ✅ Add this missing field


  RegisterUser({required this.fullName, required this.email, required this.password,     required this.age // ✅ Update constructor to include age
});

  @override
  List<Object> get props => [fullName, email, password,age];

}

// Event for login
class LoginUser extends AuthEvent {
  final String email;
  final String password;

  LoginUser({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
class CheckAuthStatus extends AuthEvent {}

// Event for logout
class LogoutUser extends AuthEvent {}