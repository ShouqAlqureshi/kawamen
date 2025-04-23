part of 'profile_bloc.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdated extends ProfileState {}

class ProfileNeedsReauth extends ProfileState {}

class ProfileNeedsVerification extends ProfileState {
  final String email;
  ProfileNeedsVerification(this.email);
}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userData;

  ProfileLoaded(this.userData);
}

class UsernNotAuthenticated extends ProfileState {}

class ToggleStatesLoaded extends ProfileState {
  final Map<String, dynamic> userData;
  final String userId;
  final bool emotionDetectionToggle;
  final bool notificationToggle;
  final bool microphoneToggle;
  final bool showControlCenter;

  ToggleStatesLoaded({
    required this.userData,
    required this.emotionDetectionToggle,
    required this.notificationToggle,
    required this.microphoneToggle,
    required this.userId,
    this.showControlCenter = false,
  });

  ToggleStatesLoaded copyWith({
    Map<String, dynamic>? userData,
    bool? emotionDetectionToggle,
    bool? notificationToggle,
    bool? microphoneToggle,
    bool? showControlCenter,
    String? userId,
  }) {
    return ToggleStatesLoaded(
      userData: userData ?? this.userData,
      userId: userId ?? this.userId, // Use the parameter here
      emotionDetectionToggle:
          emotionDetectionToggle ?? this.emotionDetectionToggle,
      notificationToggle: notificationToggle ?? this.notificationToggle,
      microphoneToggle: microphoneToggle ?? this.microphoneToggle,
      showControlCenter: showControlCenter ?? this.showControlCenter,
    );
  }
}

class AccountDeleted extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
