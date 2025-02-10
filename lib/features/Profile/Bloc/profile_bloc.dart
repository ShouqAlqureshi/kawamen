import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final BuildContext context;

  ProfileBloc({
    required this.context,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(ProfileInitial()) {
    on<UpdateUserInfo>(_onUpdateUserInfo);
    on<ReauthenticationComplete>(_onReauthenticationComplete);
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

  Future<void> _onUpdateUserInfo(
    UpdateUserInfo event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final user = _auth.currentUser;
    final String? userId = user?.uid;

    try {
      if (userId == null || user == null) {
        emit(ProfileError('No user logged in'));
        return;
      }

      // Set language code for email templates
      await _auth.setLanguageCode("ar");
      // Check if email is being changed
      final bool isEmailChange = user.email != event.email;
      await _updateBasicProfile(userId, event);

      if (isEmailChange) {
        await user.verifyBeforeUpdateEmail(event.email);
        // Emit verification needed state
        emit(ProfileNeedsVerification(event.email));
      } else {
        emit(ProfileUpdated());
      }
    } on FirebaseAuthException catch (e) {
      await _handleFirebaseAuthException(e, emit);
    } catch (e) {
      emit(ProfileError('Error updating profile: ${e.toString()}'));
    }
  }

  Future<void> _updateBasicProfile(String userId, UpdateUserInfo event) async {
    await _firestore.collection('users').doc(userId).update({
      'fullName': event.name,
      'age': event.age,
    });
  }

  Future<void> _handleFirebaseAuthException(
    FirebaseAuthException e,
    Emitter<ProfileState> emit,
  ) async {
    switch (e.code) {
      case 'requires-recent-login':
        emit(ProfileNeedsReauth());
        break;
      case 'email-already-in-use':
        emit(ProfileError('This email is already in use'));
        break;
      case 'invalid-email':
        emit(ProfileError('Invalid email address'));
        break;
      default:
        emit(ProfileError('Authentication error: ${e.message}'));
    }
  }

  Future<void> _onReauthenticationComplete(
    ReauthenticationComplete event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user
            .reauthenticateWithCredential(event.credential as AuthCredential);
        // After successful reauthentication, user can retry their action
        emit(ProfileInitial());
      }
    } catch (e) {
      emit(ProfileError('Reauthentication failed: ${e.toString()}'));
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
    } on FirebaseAuthException catch (e) {
      await _handleFirebaseAuthException(e, emit);
    } catch (e) {
      emit(ProfileError('Error deleting account: $e'));
    }
  }
}
