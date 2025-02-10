part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class FetchUserInfo extends ProfileEvent {}

class UpdateUserInfo extends ProfileEvent {
  final String name;
  final String email;
  final String age;

  UpdateUserInfo({required this.name, required this.email, required this.age});
}

class FetchToggleStates extends ProfileEvent {}

class UpdateToggleState extends ProfileEvent {
  final String toggleName;
  final bool newValue;

  UpdateToggleState({required this.toggleName, required this.newValue});
}

class DeleteAccount extends ProfileEvent {}


class ReauthenticationComplete extends ProfileEvent {
  final UserCredential credential;
  ReauthenticationComplete(this.credential);
}

class ToggleControlCenter extends ProfileEvent {}  // Add this

