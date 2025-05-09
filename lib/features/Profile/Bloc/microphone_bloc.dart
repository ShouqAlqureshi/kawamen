import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// EVENTS
abstract class MicrophoneEvent extends Equatable {
  const MicrophoneEvent();

  @override
  List<Object> get props => [];
}

class ToggleMicrophone extends MicrophoneEvent {}

// Add this new event for initialization
class InitializeMicrophone extends MicrophoneEvent {}

// STATES
abstract class MicrophoneState extends Equatable {
  const MicrophoneState();

  @override
  List<Object> get props => [];
}

class MicrophoneInitial extends MicrophoneState {}

class MicrophoneEnabled extends MicrophoneState {}

class MicrophoneDisabled extends MicrophoneState {}

class MicrophonePermissionDenied extends MicrophoneState {}

class MicrophoneError extends MicrophoneState {
  final String message;

  const MicrophoneError(this.message);

  @override
  List<Object> get props => [message];
}

// BLOC
class MicrophoneBloc extends Bloc<MicrophoneEvent, MicrophoneState> {
  MicrophoneBloc() : super(MicrophoneInitial()) {
    on<ToggleMicrophone>(_onToggleMicrophone);
    on<InitializeMicrophone>(_onInitializeMicrophone);

    // Initialize microphone state when bloc is created
    add(InitializeMicrophone());
  }

  Future<void> _onInitializeMicrophone(
      InitializeMicrophone event, Emitter<MicrophoneState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final microphoneToggle = prefs.getBool('microphoneToggle') ?? false;

      if (microphoneToggle) {
        // Check if permission is already granted
        final status = await Permission.microphone.status;
        if (status.isGranted) {
          emit(MicrophoneEnabled());
        } else {
          // If toggle is on but permission is not granted, update the preference
          await prefs.setBool('microphoneToggle', false);
          emit(MicrophonePermissionDenied());
        }
      } else {
        emit(MicrophoneDisabled());
      }
    } catch (e) {
      emit(MicrophoneError('Error initializing microphone: $e'));
    }
  }

  Future<void> _onToggleMicrophone(
      ToggleMicrophone event, Emitter<MicrophoneState> emit) async {
    try {
      if (state is MicrophoneEnabled) {
        emit(MicrophoneDisabled());

        // Update SharedPreferences directly here
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('microphoneToggle', false);

        return;
      }

      PermissionStatus status = await Permission.microphone.status;

      if (status.isGranted) {
        emit(MicrophoneEnabled());

        // Update SharedPreferences directly here
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('microphoneToggle', true);
      } else {
        status = await Permission.microphone.request();
        if (status.isGranted) {
          emit(MicrophoneEnabled());

          // Update SharedPreferences directly here
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('microphoneToggle', true);
        } else {
          emit(MicrophonePermissionDenied());

          // Update SharedPreferences directly here
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('microphoneToggle', false);
        }
      }
    } catch (e) {
      emit(MicrophoneError('Error toggling microphone: $e'));
    }
  }
}
