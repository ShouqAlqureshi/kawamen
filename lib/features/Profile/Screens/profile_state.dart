part of 'profile_bloc.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userData;

  ProfileLoaded(this.userData);
}

class ToggleStatesLoaded extends ProfileState {
  final Map<String, dynamic> userData;
  final bool emotionDetectionToggle;
  final bool notificationToggle;
  final bool microphoneToggle;

  ToggleStatesLoaded({
    required this.userData,
    required this.emotionDetectionToggle,
    required this.notificationToggle,
    required this.microphoneToggle,
  });
}

class ProfileUpdated extends ProfileState {}

class AccountDeleted extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}