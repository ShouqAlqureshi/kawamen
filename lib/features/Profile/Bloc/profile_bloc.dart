import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/core/services/cache_service.dart';
import 'package:kawamen/features/emotion_detection/Bloc/emotion_detection_bloc.dart';
import 'package:kawamen/features/emotion_detection/Bloc/emotion_detection_event.dart';
import 'package:kawamen/features/registration/bloc/auth_bloc.dart';
import 'package:kawamen/features/registration/bloc/auth_event.dart';
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
    on<ToggleControlCenter>(_onToggleControlCenter);
    on<Logout>(_onLogout);
    on<FetchUserInfo>(_onFetchUserInfo);
    on<InitializeEmotionDetection>(_onInitializeEmotionDetection);

    // Initialize emotion detection state when bloc is created
    add(InitializeEmotionDetection());
  }
/*
this function refreshes user data it fetch and send the 
fetched userinfo from firebase and toggle if not fetched yet 
otherwise if it already fetche just copy it and send
*/
  Future<void> _onFetchUserInfo(
    FetchUserInfo event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(UsernNotAuthenticated());
        return;
      } else {
        //cached data if available, otherwise fetch fresh
        final userData = await UserCacheService().getUserData(userId);
        if (userData != null) {
          if (state is ToggleStatesLoaded) {
            emit((state as ToggleStatesLoaded)
                .copyWith(userData: userData, userId: userId));
          } else {
            add(FetchToggleStates());
          }
        } else {
          emit(ProfileError('User data not found'));
        }
      }
    } catch (e) {
      emit(ProfileError('Error fetching user info: $e'));
    }
  }

  //this is a state handling  to flag if control center is pressed to expand
  void _onToggleControlCenter(
    ToggleControlCenter event,
    Emitter<ProfileState> emit,
  ) {
    if (state is ToggleStatesLoaded) {
      final currentState = state as ToggleStatesLoaded;
      emit(currentState.copyWith(
        showControlCenter: !currentState.showControlCenter,
      ));
    }
  }

//this fetches toggles from cache and firbase info
  Future<void> _onFetchToggleStates(
      FetchToggleStates event, Emitter<ProfileState> emit) async {
    // If we're already in a loaded state, preserve the showControlCenter value
    bool keepControlCenterOpen = false;
    if (state is ToggleStatesLoaded) {
      keepControlCenterOpen = (state as ToggleStatesLoaded).showControlCenter;
    }

    emit(ProfileLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotionDetectionToggle =
          prefs.getBool('emotionDetectionToggle') ?? false;
      final microphoneToggle = prefs.getBool('microphoneToggle') ?? false;

      // Fetch user data from Firestore
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(UsernNotAuthenticated());
        return;
      } else {
        final userDoc = await UserCacheService().getUserData(userId);

        if (userDoc != null) {
          emit(ToggleStatesLoaded(
            userData: userDoc,
            emotionDetectionToggle: emotionDetectionToggle,
            microphoneToggle: microphoneToggle,
            userId: userId,
            showControlCenter: keepControlCenterOpen,
          ));
        }
      }
    } catch (e) {
      emit(ProfileError('Error fetching toggle states: $e'));
    }
  }

  void _onUpdateToggleState(
      UpdateToggleState event, Emitter<ProfileState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(event.toggleName, event.newValue);

      // Keep the control center open by preserving showControlCenter value
      if (state is ToggleStatesLoaded) {
        final currentState = state as ToggleStatesLoaded;
        final bool keepControlCenterOpen = currentState.showControlCenter;

        // Fetch updated toggle states but preserve showControlCenter
        final emotionDetectionToggle =
            prefs.getBool('emotionDetectionToggle') ?? false;
        final microphoneToggle = prefs.getBool('microphoneToggle') ?? false;

        // Get updated user data
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userDoc = await UserCacheService().getUserData(userId);

          if (userDoc != null) {
            // Emit updated state with preserved showControlCenter
            emit(ToggleStatesLoaded(
              userData: userDoc,
              emotionDetectionToggle: emotionDetectionToggle,
              microphoneToggle: microphoneToggle,
              userId: userId,
              showControlCenter: keepControlCenterOpen, // Keep panel open
            ));
            return; // Skip the FetchToggleStates() call
          }
        }
      }

      // If we couldn't preserve the state, fall back to regular update
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
        emit(UsernNotAuthenticated());
        return;
      }

      // Set language code for email templates
      await _auth.setLanguageCode("ar");
      // Check if email is being changed
      final bool isEmailChange = user.email != event.email;
      await _updateBasicProfile(userId, event);

      // Force refresh cache
      await UserCacheService().getUserData(userId, forceRefresh: true);

      if (isEmailChange) {
        await user.verifyBeforeUpdateEmail(event.email);
        // Emit verification needed state
        emit(ProfileNeedsVerification(event.email));
      } else {
        emit(ProfileUpdated());
        add(FetchToggleStates());
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
        emit(UsernNotAuthenticated());
        return;
      }
      await user?.delete();
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      emit(AccountDeleted());
    } on FirebaseAuthException catch (e) {
      await _handleFirebaseAuthException(e, emit);
    } catch (e) {
      emit(ProfileError('Error deleting account: $e'));
    }
  }

  Future<void> _onLogout(Logout event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Check if the user is logged in
      if (user == null) {
        emit(
            UsernNotAuthenticated()); // Just emit this state instead of showing dialog
        return;
      }

      // Remove the second confirmation dialog
      await FirebaseAuth.instance.signOut();

      // Clear shared preferences if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      emit(ProfileInitial()); // Reset the profile state to initial

      // Notify AuthBloc about logout
      BlocProvider.of<AuthBloc>(context).add(LogoutUser());

      // Navigate to login page directly
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (e) {
      emit(ProfileError('Error logging out: ${e.toString()}'));
    }
  }

  Future<void> _onInitializeEmotionDetection(event, emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotionDetectionToggle =
          prefs.getBool('emotionDetectionToggle') ?? false;
      if (emotionDetectionToggle) {
        // Check if microphone permission is granted before enabling
        final microphoneToggle = prefs.getBool('microphoneToggle') ?? false;

        if (!microphoneToggle) {
          // If microphone is off, we can't enable emotion detection
          await prefs.setBool('emotionDetectionToggle', false);
        }
      }
    } catch (e) {
      emit(ProfileError('Error initializing emotion detection: $e'));
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> showLogOutDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Set dialog background to white
          title: const Text(
            'Log Out',
            style: TextStyle(color: Colors.black), // Set title text color
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.black), // Set content text color
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // No
              child: const Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.black), // Customize button color if desired
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Yes
              child: const Text(
                'Log Out',
                style: TextStyle(
                    color: Colors.red), // Set log out button text color
              ),
            ),
          ],
        );
      },
    ).then((value) => value ?? false); // Ensure it returns false if dismissed
  }
}
