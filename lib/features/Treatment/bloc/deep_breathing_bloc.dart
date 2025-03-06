import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

// Events
abstract class DeepBreathingEvent extends Equatable {
  const DeepBreathingEvent();

  @override
  List<Object> get props => [];
}

class StartExerciseEvent extends DeepBreathingEvent {
  const StartExerciseEvent();
}

class PauseExerciseEvent extends DeepBreathingEvent {
  const PauseExerciseEvent();
}

class ResumeExerciseEvent extends DeepBreathingEvent {
  final int remainingTotalSeconds;
  final int remainingCountdownSeconds;
  final int currentInstructionIndex;
  final int currentRepetition;

  const ResumeExerciseEvent({
    required this.remainingTotalSeconds,
    required this.remainingCountdownSeconds,
    required this.currentInstructionIndex,
    required this.currentRepetition,
  });

  @override
  List<Object> get props => [
    remainingTotalSeconds, 
    remainingCountdownSeconds,
    currentInstructionIndex,
    currentRepetition,
  ];
}

class CountdownTickEvent extends DeepBreathingEvent {
  const CountdownTickEvent();
}

class TotalTimerTickEvent extends DeepBreathingEvent {
  const TotalTimerTickEvent();
}

class NextInstructionEvent extends DeepBreathingEvent {
  const NextInstructionEvent();
}

class CompleteExerciseEvent extends DeepBreathingEvent {
  const CompleteExerciseEvent();
}

class ResetExerciseEvent extends DeepBreathingEvent {
  const ResetExerciseEvent();
}

// Add a new event specifically for showing the countdown
class ShowCountdownEvent extends DeepBreathingEvent {
  const ShowCountdownEvent();
}

class FadeInNextInstructionEvent extends DeepBreathingEvent {
  const FadeInNextInstructionEvent();
}

class ShowCountdownForNextInstructionEvent extends DeepBreathingEvent {
  const ShowCountdownForNextInstructionEvent();
}
// State
class DeepBreathingState extends Equatable {
  final bool isPlaying;
  final bool isCompleting;
  final int currentInstructionIndex;
  final int currentRepetition;
  final int totalRepetitions;
  final int countdownSeconds;
  final int totalExerciseSeconds;
  final double instructionOpacity;
  final double countdownOpacity;
  final List<String> instructions;
  final List<int> instructionDurations;
  final int totalExerciseTime;
  final InstructionPhase currentPhase;

  const DeepBreathingState({
    required this.isPlaying,
    required this.isCompleting,
    required this.currentInstructionIndex,
    required this.currentRepetition,
    required this.totalRepetitions,
    required this.countdownSeconds,
    required this.totalExerciseSeconds,
    required this.instructionOpacity,
    required this.countdownOpacity,
    required this.instructions,
    required this.instructionDurations,
    required this.totalExerciseTime,
    required this.currentPhase,
  });

  // Initial state factory
  factory DeepBreathingState.initial() {
    final List<String> instructions = [
      'خذ شهيقًا عميقًا لمدة 4 ثوان...',
      'احبس النفس لمدة 4 ثوان...',
      'أخرج الزفير ببطء لمدة 6 ثوان...',
    ];
    final List<int> instructionDurations = [4, 4, 6];
    final int totalRepetitions = 10;
    
    // Calculate total exercise time
    final int totalExerciseTime = totalRepetitions * 
        (instructionDurations.reduce((a, b) => a + b) + 8) + 3 + 6;

    return DeepBreathingState(
      isPlaying: false,
      isCompleting: false,
      currentInstructionIndex: 0,
      currentRepetition: 1,
      totalRepetitions: totalRepetitions,
      countdownSeconds: instructionDurations[0],
      totalExerciseSeconds: totalExerciseTime,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0,
      instructions: instructions,
      instructionDurations: instructionDurations,
      totalExerciseTime: totalExerciseTime,
      currentPhase: InstructionPhase.inhale,
    );
  }

  // CopyWith method for immutability
  DeepBreathingState copyWith({
    bool? isPlaying,
    bool? isCompleting,
    int? currentInstructionIndex,
    int? currentRepetition,
    int? totalRepetitions,
    int? countdownSeconds,
    int? totalExerciseSeconds,
    double? instructionOpacity,
    double? countdownOpacity,
    List<String>? instructions,
    List<int>? instructionDurations,
    int? totalExerciseTime,
    InstructionPhase? currentPhase,
  }) {
    return DeepBreathingState(
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleting: isCompleting ?? this.isCompleting,
      currentInstructionIndex: currentInstructionIndex ?? this.currentInstructionIndex,
      currentRepetition: currentRepetition ?? this.currentRepetition,
      totalRepetitions: totalRepetitions ?? this.totalRepetitions,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalExerciseSeconds: totalExerciseSeconds ?? this.totalExerciseSeconds,
      instructionOpacity: instructionOpacity ?? this.instructionOpacity,
      countdownOpacity: countdownOpacity ?? this.countdownOpacity,
      instructions: instructions ?? this.instructions,
      instructionDurations: instructionDurations ?? this.instructionDurations,
      totalExerciseTime: totalExerciseTime ?? this.totalExerciseTime,
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }

  @override
  List<Object> get props => [
    isPlaying,
    isCompleting,
    currentInstructionIndex,
    currentRepetition,
    totalRepetitions,
    countdownSeconds,
    totalExerciseSeconds,
    instructionOpacity,
    countdownOpacity,
    instructions,
    instructionDurations,
    totalExerciseTime,
    currentPhase,
  ];
}

// Enum for breathing phases
enum InstructionPhase { inhale, hold, exhale }

// BLoC
class DeepBreathingBloc extends Bloc<DeepBreathingEvent, DeepBreathingState> {
  Timer? _countdownTimer;
  Timer? _totalExerciseTimer;
  Timer? _delayTimer;
  
  DeepBreathingBloc() : super(DeepBreathingState.initial()) {
    on<StartExerciseEvent>(_onStartExercise);
    on<PauseExerciseEvent>(_onPauseExercise);
    on<ResumeExerciseEvent>(_onResumeExercise);
    on<CountdownTickEvent>(_onCountdownTick);
    on<TotalTimerTickEvent>(_onTotalTimerTick);
    on<NextInstructionEvent>(_onNextInstruction);
    on<CompleteExerciseEvent>(_onCompleteExercise);
    on<ResetExerciseEvent>(_onResetExercise);
    on<ShowCountdownEvent>(_onShowCountdown);
    // New event handlers for the timer callbacks
    on<FadeInNextInstructionEvent>(_onFadeInNextInstruction);
    on<ShowCountdownForNextInstructionEvent>(_onShowCountdownForNextInstruction);
  }
  
  // Add these new events
  void _onFadeInNextInstruction(FadeInNextInstructionEvent event, Emitter<DeepBreathingState> emit) {
    if (!state.isPlaying) return;
    
    // Check if we've completed all repetitions
    if (state.currentRepetition >= state.totalRepetitions && 
        state.currentInstructionIndex >= state.instructions.length - 1) {
      add(const CompleteExerciseEvent());
      return;
    }
    
    // Determine next instruction/repetition
    int nextInstructionIndex = state.currentInstructionIndex;
    int nextRepetition = state.currentRepetition;
    
    if (state.currentInstructionIndex >= state.instructions.length - 1) {
      // End of cycle, move to next repetition
      nextInstructionIndex = 0;
      nextRepetition = state.currentRepetition + 1;
      developer.log('Moving to next repetition: $nextRepetition');
    } else {
      // Move to next instruction in this repetition
      nextInstructionIndex = state.currentInstructionIndex + 1;
      developer.log('Moving to next instruction in repetition: $nextInstructionIndex');
    }
    
    // Update state with new instruction
    InstructionPhase nextPhase;
    if (nextInstructionIndex == 0) {
      nextPhase = InstructionPhase.inhale;
    } else if (nextInstructionIndex == 1) {
      nextPhase = InstructionPhase.hold;
    } else {
      nextPhase = InstructionPhase.exhale;
    }
    
    emit(state.copyWith(
      currentInstructionIndex: nextInstructionIndex,
      currentRepetition: nextRepetition,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0, // Ensure countdown is invisible initially
      countdownSeconds: state.instructionDurations[nextInstructionIndex],
      currentPhase: nextPhase,
    ));
    
    developer.log('New instruction set: ${state.instructions[nextInstructionIndex]}, opacity: 1.0');
    
    // Schedule the countdown to appear after 2 seconds
    _delayTimer = Timer(const Duration(seconds: 2), () {
      add(const ShowCountdownForNextInstructionEvent());
    });
  }
  
  void _onShowCountdownForNextInstruction(ShowCountdownForNextInstructionEvent event, Emitter<DeepBreathingState> emit) {
    if (!state.isPlaying) return;
    
    developer.log('Showing countdown for instruction ${state.currentInstructionIndex}');
    add(const ShowCountdownEvent());
  }

  void _onStartExercise(StartExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Starting exercise');
    // Cancel any existing timers
    _cancelTimers();
    
    // Reset to initial state with playing=true
    final initialState = DeepBreathingState.initial().copyWith(
      isPlaying: true,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0, // Start with instruction visible first
    );
    
    emit(initialState);
    
    // Start the total exercise timer
    _startTotalTimer();
    
    // After 2 seconds, show countdown and start countdown timer
    _delayTimer = Timer(const Duration(seconds: 2), () {
      add(const ShowCountdownEvent());
    });
  }

  void _onShowCountdown(ShowCountdownEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('ShowCountdownEvent triggered');
    if (!state.isPlaying) return;
    
    // Explicitly set countdown duration and make it visible
    final currentDuration = state.instructionDurations[state.currentInstructionIndex];
    developer.log('Setting countdown seconds to: $currentDuration');
    
    emit(state.copyWith(
      countdownSeconds: currentDuration,
      countdownOpacity: 1.0,
    ));
    
    // Start countdown timer after confirming the countdown is visible
    _startCountdownTimer();
  }

  void _onPauseExercise(PauseExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Pausing exercise');
    _cancelTimers();
    emit(state.copyWith(isPlaying: false));
  }

  void _onResumeExercise(ResumeExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Resuming exercise');
    // Cancel any existing timers
    _cancelTimers();
    
    // Update state with provided values
    emit(state.copyWith(
      isPlaying: true,
      totalExerciseSeconds: event.remainingTotalSeconds,
      countdownSeconds: event.remainingCountdownSeconds,
      currentInstructionIndex: event.currentInstructionIndex,
      currentRepetition: event.currentRepetition,
      countdownOpacity: event.remainingCountdownSeconds > 0 ? 1.0 : 0.0,
      currentPhase: InstructionPhase.values[event.currentInstructionIndex],
    ));
    
    // Restart timers
    _startTotalTimer();
    if (event.remainingCountdownSeconds > 0) {
      _startCountdownTimer();
    }
  }

  void _onCountdownTick(CountdownTickEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Countdown tick: ${state.countdownSeconds - 1}');
    if (state.countdownSeconds > 1) {
      emit(state.copyWith(
        countdownSeconds: state.countdownSeconds - 1,
      ));
    } else {
      // Countdown is complete, cancel timer and fade out countdown
      developer.log('Countdown complete');
      _countdownTimer?.cancel();
      _countdownTimer = null;
      
      emit(state.copyWith(
        countdownSeconds: 0,
        countdownOpacity: 0.0,
      ));
      
      // After animation delay, move to next instruction
      _delayTimer = Timer(const Duration(milliseconds: 500), () {
        add(const NextInstructionEvent());
      });
    }
  }

  void _onTotalTimerTick(TotalTimerTickEvent event, Emitter<DeepBreathingState> emit) {
    if (state.totalExerciseSeconds > 1) {
      emit(state.copyWith(
        totalExerciseSeconds: state.totalExerciseSeconds - 1,
      ));
    } else {
      // Exercise is complete
      developer.log('Total exercise time complete');
      _cancelTimers();
      add(const CompleteExerciseEvent());
    }
  }

  // Modified to just fade out and dispatch the next event
  void _onNextInstruction(NextInstructionEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Moving to next instruction');
    // Cancel any existing timers to prevent overlap
    _countdownTimer?.cancel();
    _countdownTimer = null;
    
    // Fade out current instruction
    emit(state.copyWith(
      instructionOpacity: 0.0,
    ));
    
    // After fade out animation completes, dispatch a new event
    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      add(const FadeInNextInstructionEvent());
    });
  }

  void _onCompleteExercise(CompleteExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Exercise completed');
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
      isCompleting: true,
    ));
  }

  void _onResetExercise(ResetExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Exercise reset');
    _cancelTimers();
    emit(DeepBreathingState.initial());
  }

  // Helper methods for timers
  void _startCountdownTimer() {
    developer.log('Starting countdown timer');
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const CountdownTickEvent());
    });
  }

  void _startTotalTimer() {
    developer.log('Starting total timer');
    _totalExerciseTimer?.cancel();
    _totalExerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const TotalTimerTickEvent());
    });
  }

  void _cancelTimers() {
    developer.log('Cancelling all timers');
    _countdownTimer?.cancel();
    _totalExerciseTimer?.cancel();
    _delayTimer?.cancel();
    
    _countdownTimer = null;
    _totalExerciseTimer = null;
    _delayTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
