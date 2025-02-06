import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

// EVENTS
abstract class MicrophoneEvent extends Equatable {
  const MicrophoneEvent();

  @override
  List<Object> get props => [];
}

class ToggleMicrophone extends MicrophoneEvent {}

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

// BLOC
class MicrophoneBloc extends Bloc<MicrophoneEvent, MicrophoneState> {
  MicrophoneBloc() : super(MicrophoneInitial()) {
    on<ToggleMicrophone>((event, emit) async {
      PermissionStatus status = await Permission.microphone.request();

      if (status.isGranted) {
        emit(MicrophoneEnabled());
      } else {
        emit(MicrophonePermissionDenied());
      }
    });
  }
}
