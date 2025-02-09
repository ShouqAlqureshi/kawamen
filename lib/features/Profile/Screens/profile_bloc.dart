import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<UpdateUserInfo>(_onUpdateUserInfo);
    on<DeleteAccount>(_onDeleteAccount);
    on<FetchToggleStates>(_onFetchToggleStates);
    on<UpdateToggleState>(_onUpdateToggleState);
  }

  Future<void> _onFetchToggleStates(
      FetchToggleStates event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotionDetectionToggle =
          prefs.getBool('emotionDetectionToggle') ?? false;
      final notificationToggle = prefs.getBool('notificationToggle') ?? false;
      final microphoneToggle = prefs.getBool('microphoneToggle') ?? false;
      // Fetch user data from Firestore
      // final String? userId = FirebaseAuth.instance.currentUser?.uid;
      final String? userId = "abcDEF789";
      if (userId != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          emit(ToggleStatesLoaded(
            userData: userData,
            emotionDetectionToggle: emotionDetectionToggle,
            notificationToggle: notificationToggle,
            microphoneToggle: microphoneToggle,
          ));
        }
      }
    } catch (e) {
      emit(ProfileError('Error fetching toggle states: $e'));
    }
  }

  Future<void> _onUpdateToggleState(
      UpdateToggleState event, Emitter<ProfileState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(event.toggleName, event.newValue);

      // Fetch updated toggle states
      add(FetchToggleStates());
    } catch (e) {
      emit(ProfileError('Error updating toggle state: $e'));
    }
  }
}

Future<void> _onUpdateUserInfo(
    UpdateUserInfo event, Emitter<ProfileState> emit) async {
  emit(ProfileLoading());
  try {
    // final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final String? userId = "abcDEF789";
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fullName': event.name,
        'email': event.email,
        'age': event.age,
      });
      emit(ProfileUpdated());
    }
  } catch (e) {
    emit(ProfileError('Error updating profile: $e'));
  }
}

Future<void> _onDeleteAccount(
    DeleteAccount event, Emitter<ProfileState> emit) async {
  emit(ProfileLoading());
  try {
    final user = FirebaseAuth.instance.currentUser;
    final String? userId = user?.uid;

    if (userId == null) {
      throw Exception("User is not authenticated or UID is null.");
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).delete();

    await user?.delete();
    emit(AccountDeleted());
  } catch (e) {
    emit(ProfileError('Error deleting account: $e'));
  }
}
