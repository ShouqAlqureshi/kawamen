// features/registration/bloc/auth_state.dart
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class AuthInitial extends AuthState {}

// Loading state
class AuthLoading extends AuthState {}

// Success state (User registered or logged in)
class AuthSuccess extends AuthState {}

// Failure state (Authentication error)
class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}