import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class DeepBreathingEvent extends Equatable {
  const DeepBreathingEvent();

  @override
  List<Object> get props => [];

  const factory DeepBreathingEvent.play() = PlayEvent;
  const factory DeepBreathingEvent.pause() = PauseEvent;
  const factory DeepBreathingEvent.seekTo(Duration position) = SeekToEvent;
}

class PlayEvent extends DeepBreathingEvent {
  const PlayEvent();
}

class PauseEvent extends DeepBreathingEvent {
  const PauseEvent();
}

class SeekToEvent extends DeepBreathingEvent {
  final Duration position;
  
  const SeekToEvent(this.position);
  
  @override
  List<Object> get props => [position];
}

// State
class DeepBreathingState extends Equatable {
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;

  const DeepBreathingState({
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
  });

  factory DeepBreathingState.initial() => const DeepBreathingState(
        currentPosition: Duration.zero,
        totalDuration: Duration(minutes: 5), // 5 minutes default duration
        isPlaying: false,
      );

  DeepBreathingState copyWith({
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isPlaying,
  }) {
    return DeepBreathingState(
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  List<Object> get props => [currentPosition, totalDuration, isPlaying];
}

// Bloc
class DeepBreathingBloc extends Bloc<DeepBreathingEvent, DeepBreathingState> {
  Timer? _timer;

  DeepBreathingBloc() : super(DeepBreathingState.initial()) {
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<SeekToEvent>(_onSeekTo);
  }

  void _onPlay(PlayEvent event, Emitter<DeepBreathingState> emit) {
    emit(state.copyWith(isPlaying: true));
    _startTimer(emit);
  }

  void _onPause(PauseEvent event, Emitter<DeepBreathingState> emit) {
    _stopTimer();
    emit(state.copyWith(isPlaying: false));
  }

  void _onSeekTo(SeekToEvent event, Emitter<DeepBreathingState> emit) {
    emit(state.copyWith(currentPosition: event.position));
  }

  void _startTimer(Emitter<DeepBreathingState> emit) {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newPosition = state.currentPosition + const Duration(seconds: 1);
      
      if (newPosition >= state.totalDuration) {
        _stopTimer();
        emit(state.copyWith(
          currentPosition: state.totalDuration,
          isPlaying: false,
        ));
      } else {
        emit(state.copyWith(currentPosition: newPosition));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}