import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kawamen/features/Treatment/deep_breathing/repository/deep_breathing_repository.dart';

// Model classes for Treatment data
class TreatmentStep {
  final int stepNumber;
  final String instruction;
  final int duration;
  final String? mediaURL;

  TreatmentStep({
    required this.stepNumber,
    required this.instruction,
    required this.duration,
    this.mediaURL,
  });

  factory TreatmentStep.fromMap(Map<String, dynamic> map) {
    return TreatmentStep(
      stepNumber: map['stepNumber'] ?? 0,
      instruction: map['instruction'] ?? '',
      duration: map['duration'] ?? 0,
      mediaURL: map['mediaURL'],
    );
  }
}

class Treatment {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<TreatmentStep> steps;

  Treatment({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.steps,
  });

  factory Treatment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception(
          "Treatment document does not exist or you don't have permission.");
    }

    final map = data as Map<String, dynamic>;

    return Treatment(
      id: doc.id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      steps: [], // Steps will be added later
    );
  }
}

// Events
abstract class DeepBreathingEvent extends Equatable {
  const DeepBreathingEvent();

  @override
  List<Object> get props => [];
}

class LoadTreatmentEvent extends DeepBreathingEvent {
  final String treatmentId;

  const LoadTreatmentEvent({required this.treatmentId});

  @override
  List<Object> get props => [treatmentId];
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

class ShowCountdownEvent extends DeepBreathingEvent {
  const ShowCountdownEvent();
}

class FadeInNextInstructionEvent extends DeepBreathingEvent {
  const FadeInNextInstructionEvent();
}

class ShowCountdownForNextInstructionEvent extends DeepBreathingEvent {
  const ShowCountdownForNextInstructionEvent();
}

class StartTrackingTreatmentEvent extends DeepBreathingEvent {
  const StartTrackingTreatmentEvent();
}

class CompleteTrackingTreatmentEvent extends DeepBreathingEvent {
  const CompleteTrackingTreatmentEvent();

  @override
  List<Object> get props => [];
}

class LoadUserTreatmentEvent extends DeepBreathingEvent {
  final String userTreatmentId;
  final String treatmentId;

  const LoadUserTreatmentEvent({
    required this.userTreatmentId,
    required this.treatmentId,
  });

  @override
  List<Object> get props => [userTreatmentId, treatmentId];
}
class UpdateTreatmentProgressEvent extends DeepBreathingEvent {
  final double progress;

  const UpdateTreatmentProgressEvent({required this.progress});

  @override
  List<Object> get props => [progress];
}

// Enum for treatment status
enum TreatmentStatus { started, inProgress, completed, paused }

// Extension to convert enum to string for Firestore
extension TreatmentStatusExtension on TreatmentStatus {
  String get value {
    switch (this) {
      case TreatmentStatus.started:
        return 'started';
      case TreatmentStatus.inProgress:
        return 'in_progress';
      case TreatmentStatus.completed:
        return 'completed';
      case TreatmentStatus.paused:
        return 'paused';
    }
  }
}

// State
class DeepBreathingState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final Treatment? treatment;
  final bool isPlaying;
  final bool isCompleting;
  final int currentInstructionIndex;
  final int currentRepetition;
  final int totalRepetitions; // Fixed in code
  final int countdownSeconds;
  final int totalExerciseSeconds;
  final double instructionOpacity;
  final double countdownOpacity;
  final InstructionPhase currentPhase;
  final bool isAnimating;
  final String? userTreatmentId;

  const DeepBreathingState({
    required this.isLoading,
    this.errorMessage,
    this.treatment,
    required this.isPlaying,
    required this.isCompleting,
    required this.currentInstructionIndex,
    required this.currentRepetition,
    required this.totalRepetitions,
    required this.countdownSeconds,
    required this.totalExerciseSeconds,
    required this.instructionOpacity,
    required this.countdownOpacity,
    required this.currentPhase,
    required this.isAnimating,
    this.userTreatmentId,
  });

  // Initial state factory
  factory DeepBreathingState.initial() {
    return const DeepBreathingState(
      isLoading: false,
      isPlaying: false,
      isCompleting: false,
      currentInstructionIndex: 0,
      currentRepetition: 1,
      totalRepetitions: 10, // Fixed in code - 10 repetitions
      countdownSeconds: 0,
      totalExerciseSeconds: 0, // Will be calculated when treatment is loaded
      instructionOpacity: 1.0,
      countdownOpacity: 0.0,
      currentPhase: InstructionPhase.inhale,
      isAnimating: false,
      userTreatmentId: null,
    );
  }

  // Loading state
  factory DeepBreathingState.loading() {
    return const DeepBreathingState(
      isLoading: true,
      isPlaying: false,
      isCompleting: false,
      currentInstructionIndex: 0,
      currentRepetition: 1,
      totalRepetitions: 10,
      countdownSeconds: 0,
      totalExerciseSeconds: 0,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0,
      currentPhase: InstructionPhase.inhale,
      isAnimating: false,
      userTreatmentId: null,
    );
  }

  static const int transitionTimePerRepetition = 6; // seconds

  // Error state
  factory DeepBreathingState.error(String message) {
    return DeepBreathingState(
      isLoading: false,
      errorMessage: message,
      isPlaying: false,
      isCompleting: false,
      currentInstructionIndex: 0,
      currentRepetition: 1,
      totalRepetitions: 10,
      countdownSeconds: 0,
      totalExerciseSeconds: 0,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0,
      currentPhase: InstructionPhase.inhale,
      isAnimating: false,
      userTreatmentId: null,
    );
  }

  int get totalExerciseTime {
    if (treatment == null) return 0;

    int totalStepsTime = 0;
    for (var step in treatment!.steps) {
      totalStepsTime += step.duration;
    }

    return totalRepetitions * (totalStepsTime + transitionTimePerRepetition);
  }

  // Get current instruction text
  String get currentInstruction {
    if (treatment == null || treatment!.steps.isEmpty) {
      return '';
    }
    return treatment!.steps[currentInstructionIndex].instruction;
  }

  // Get current instruction duration
  int get currentInstructionDuration {
    if (treatment == null || treatment!.steps.isEmpty) {
      return 0;
    }
    return treatment!.steps[currentInstructionIndex].duration;
  }

  // Get current step's media URL
  String? get currentMediaURL {
    if (treatment == null || treatment!.steps.isEmpty) {
      return null;
    }
    return treatment!.steps[currentInstructionIndex].mediaURL;
  }

  // CopyWith method for immutability
  DeepBreathingState copyWith({
    bool? isLoading,
    String? errorMessage,
    Treatment? treatment,
    bool? isPlaying,
    bool? isCompleting,
    int? currentInstructionIndex,
    int? currentRepetition,
    int? totalRepetitions,
    int? countdownSeconds,
    int? totalExerciseSeconds,
    double? instructionOpacity,
    double? countdownOpacity,
    InstructionPhase? currentPhase,
    bool? isAnimating,
    String? userTreatmentId,

  }) {
    return DeepBreathingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      treatment: treatment ?? this.treatment,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleting: isCompleting ?? this.isCompleting,
      currentInstructionIndex:
          currentInstructionIndex ?? this.currentInstructionIndex,
      currentRepetition: currentRepetition ?? this.currentRepetition,
      totalRepetitions: totalRepetitions ?? this.totalRepetitions,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalExerciseSeconds: totalExerciseSeconds ?? this.totalExerciseSeconds,
      instructionOpacity: instructionOpacity ?? this.instructionOpacity,
      countdownOpacity: countdownOpacity ?? this.countdownOpacity,
      currentPhase: currentPhase ?? this.currentPhase,
      isAnimating: isAnimating ?? this.isAnimating,
      userTreatmentId: userTreatmentId ?? this.userTreatmentId,

    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        treatment,
        isPlaying,
        isCompleting,
        currentInstructionIndex,
        currentRepetition,
        totalRepetitions,
        countdownSeconds,
        totalExerciseSeconds,
        instructionOpacity,
        countdownOpacity,
        currentPhase,
        isAnimating,
        userTreatmentId,

      ];
}

// Enum for breathing phases
enum InstructionPhase { inhale, hold, exhale }

// BLoC
class DeepBreathingBloc extends Bloc<DeepBreathingEvent, DeepBreathingState> {
  final TreatmentRepository _repository = TreatmentRepository();
  Timer? _countdownTimer;
  Timer? _totalExerciseTimer;
  Timer? _delayTimer;
  Timer? _progressUpdateTimer;

  // Constants defined in code, not from database
  static const int totalRepetitions = 10;
  static const int transitionTimePerRepetition = 6; // seconds
  static const int progressUpdateInterval = 10; 

  DeepBreathingBloc() : super(DeepBreathingState.initial()) {
    on<LoadTreatmentEvent>(_onLoadTreatment);
    on<StartExerciseEvent>(_onStartExercise);
    on<PauseExerciseEvent>(_onPauseExercise);
    on<ResumeExerciseEvent>(_onResumeExercise);
    on<CountdownTickEvent>(_onCountdownTick);
    on<TotalTimerTickEvent>(_onTotalTimerTick);
    on<NextInstructionEvent>(_onNextInstruction);
    on<CompleteExerciseEvent>(_onCompleteExercise);
    on<ResetExerciseEvent>(_onResetExercise);
    on<ShowCountdownEvent>(_onShowCountdown);
    on<FadeInNextInstructionEvent>(_onFadeInNextInstruction);
    on<ShowCountdownForNextInstructionEvent>(
        _onShowCountdownForNextInstruction);
    on<StartTrackingTreatmentEvent>(_onStartTrackingTreatment);
    on<CompleteTrackingTreatmentEvent>(_onCompleteTrackingTreatment);
    on<UpdateTreatmentProgressEvent>(_onUpdateTreatmentProgress);
    on<LoadUserTreatmentEvent>(_onLoadUserTreatment);

  }
 Future<void> _onStartTrackingTreatment(
    StartTrackingTreatmentEvent event,
    Emitter<DeepBreathingState> emit) async {
  if (state.treatment == null) return;

  try {
    final userTreatmentId = await _repository.trackUserTreatment(
      treatmentId: state.treatment!.id,
      status: TreatmentStatus.started,
      emotionFeedback: "angry", // Add constant "angry" emotion when starting
      progress: 0.0,
    );
    
    emit(state.copyWith(userTreatmentId: userTreatmentId));
    developer.log('Treatment tracking started with ID: $userTreatmentId');
  } catch (e) {
    developer.log('Error starting treatment tracking: $e');
  }
}

Future<void> _onCompleteTrackingTreatment(
    CompleteTrackingTreatmentEvent event,
    Emitter<DeepBreathingState> emit) async {
  if (state.treatment == null || state.userTreatmentId == null) return;

  try {
    await _repository.trackUserTreatment(
      treatmentId: state.treatment!.id,
      status: TreatmentStatus.completed,
      userTreatmentId: state.userTreatmentId,
      progress: 100.0, // Completed means 100%
    );
  } catch (e) {
    developer.log('Error completing treatment tracking: $e');
  }
}

Future<void> _onUpdateTreatmentProgress(
    UpdateTreatmentProgressEvent event,
    Emitter<DeepBreathingState> emit) async {
  if (state.treatment == null || state.userTreatmentId == null) return;

  try {
    await _repository.trackUserTreatment(
      treatmentId: state.treatment!.id,
      status: TreatmentStatus.inProgress,
      userTreatmentId: state.userTreatmentId,
      progress: event.progress,
    );
  } catch (e) {
    developer.log('Error updating treatment progress: $e');
  }
}

// Add new method to load a specific user treatment
Future<void> _onLoadUserTreatment(
    LoadUserTreatmentEvent event,
    Emitter<DeepBreathingState> emit) async {
  try {
    emit(DeepBreathingState.loading());

    // First, get the treatment details
    final treatment = await _repository.getTreatmentWithSteps(event.treatmentId);

    // Then get the user treatment details
    final userTreatment = await _repository.getUserTreatmentById(event.userTreatmentId);
    
    if (userTreatment == null) {
      throw Exception("Couldn't find the specific treatment session");
    }
    
    // Calculate total exercise time
    int totalStepsDuration = 0;
    for (var step in treatment.steps) {
      totalStepsDuration += step.duration;
    }
    final totalExerciseTime = totalRepetitions * (totalStepsDuration + transitionTimePerRepetition);
    
    // Get stored progress
    final progress = userTreatment['progress'] as double? ?? 0.0;
    
    // Calculate where we are in the exercise based on progress
    final completedTime = (totalExerciseTime * (progress / 100)).round();
    final remainingTime = totalExerciseTime - completedTime;
    
    // Determine initial phase (simplified - you might want to store more state info)
    InstructionPhase initialPhase = InstructionPhase.inhale;
    
    emit(state.copyWith(
      isLoading: false,
      treatment: treatment,
      totalExerciseSeconds: remainingTime,
      userTreatmentId: event.userTreatmentId,
      currentPhase: initialPhase,
      // You might want to restore more state from the saved userTreatment
      // such as currentRepetition, currentInstructionIndex, etc.
    ));
    
    developer.log('Loaded user treatment: ${event.userTreatmentId} with progress: $progress%');
  } catch (e) {
    developer.log('Error loading user treatment: $e');
    emit(DeepBreathingState.error('Failed to load treatment session: ${e.toString()}'));
  }
}


  Future<void> _onLoadTreatment(
      LoadTreatmentEvent event, Emitter<DeepBreathingState> emit) async {
    try {
      emit(DeepBreathingState.loading());

      final treatment =
          await _repository.getTreatmentWithSteps(event.treatmentId);

      // Calculate total exercise time using steps from database but fixed repetitions from code
      int totalStepsDuration = 0;
      for (var step in treatment.steps) {
        totalStepsDuration += step.duration;
      }

      // Total duration calculated in code using fixed constants
      final totalExerciseTime =
          totalRepetitions * (totalStepsDuration + transitionTimePerRepetition);

      // Determine initial phase based on first step
      InstructionPhase initialPhase = InstructionPhase.inhale;
      if (treatment.steps.isNotEmpty) {
        final firstStepNumber = treatment.steps.first.stepNumber;
        if (firstStepNumber == 1) {
          initialPhase = InstructionPhase.inhale;
        } else if (firstStepNumber == 2) {
          initialPhase = InstructionPhase.hold;
        } else if (firstStepNumber == 3) {
          initialPhase = InstructionPhase.exhale;
        }
      }

      emit(state.copyWith(
        isLoading: false,
        treatment: treatment,
        totalExerciseSeconds: totalExerciseTime,
        countdownSeconds:
            treatment.steps.isNotEmpty ? treatment.steps.first.duration : 0,
        currentPhase: initialPhase,
      ));
    } catch (e) {
      developer.log('Error loading treatment: $e');
      emit(DeepBreathingState.error(
          'Failed to load treatment: ${e.toString()}'));
    }
  }

   void _onStartExercise(StartExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Starting exercise');
    if (state.treatment == null) {
      developer.log('Cannot start exercise: No treatment loaded');
      return;
    }
    
    // Cancel any existing timers
    _cancelTimers();
    
    emit(state.copyWith(
      isPlaying: true,
      isCompleting: false,
      currentInstructionIndex: 0,
      currentRepetition: 1,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0, // Start with instruction visible first
      isAnimating: false, // Start with animation off
      countdownSeconds: state.treatment!.steps.isNotEmpty ? state.treatment!.steps.first.duration : 0,
    ));
    
    // Start the total exercise timer
    _startTotalTimer();
    
    // Start tracking treatment
    add(const StartTrackingTreatmentEvent());
    
    // Start progress update timer
    _startProgressUpdateTimer();
    
    // After 2 seconds, show countdown and start countdown timer
    _delayTimer = Timer(const Duration(seconds: 2), () {
      add(const ShowCountdownEvent());
    });
  }
  
  void _onCompleteExercise(CompleteExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Exercise completed');
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
      isCompleting: true,
      isAnimating: false, // Stop animation when exercise completes
    ));
    
    // Complete tracking with no emotion (emotion will be added later if provided)
    add(const CompleteTrackingTreatmentEvent());
  }
  
  void _onPauseExercise(PauseExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Pausing exercise');
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
      isAnimating: false, // Stop animation when paused
    ));
    
    // Update progress when paused
    if (state.treatment != null && state.totalExerciseTime > 0) {
      final completedTime = state.totalExerciseTime - state.totalExerciseSeconds;
      final progressPercentage = (completedTime / state.totalExerciseTime) * 100;
      add(UpdateTreatmentProgressEvent(progress: progressPercentage));
    }
  }
  
  // Helper method to start progress update timer
  void _startProgressUpdateTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(
      const Duration(seconds: progressUpdateInterval), 
      (timer) {
        if (state.treatment != null && state.totalExerciseTime > 0) {
          final completedTime = state.totalExerciseTime - state.totalExerciseSeconds;
          final progressPercentage = (completedTime / state.totalExerciseTime) * 100;
          add(UpdateTreatmentProgressEvent(progress: progressPercentage));
        }
      }
    );
  }
  
  void _cancelTimers() {
    developer.log('Cancelling all timers');
    _countdownTimer?.cancel();
    _totalExerciseTimer?.cancel();
    _delayTimer?.cancel();
    _progressUpdateTimer?.cancel();
    
    _countdownTimer = null;
    _totalExerciseTimer = null;
    _delayTimer = null;
    _progressUpdateTimer = null;
  }



  void _onFadeInNextInstruction(
      FadeInNextInstructionEvent event, Emitter<DeepBreathingState> emit) {
    if (!state.isPlaying || state.treatment == null) return;

    // Check if we've completed all repetitions
    if (state.currentRepetition >= totalRepetitions &&
        state.currentInstructionIndex >= state.treatment!.steps.length - 1) {
      add(const CompleteExerciseEvent());
      return;
    }

    // Determine next instruction/repetition
    int nextInstructionIndex = state.currentInstructionIndex;
    int nextRepetition = state.currentRepetition;

    if (state.currentInstructionIndex >= state.treatment!.steps.length - 1) {
      // End of cycle, move to next repetition
      nextInstructionIndex = 0;
      nextRepetition = state.currentRepetition + 1;
      developer.log('Moving to next repetition: $nextRepetition');
    } else {
      // Move to next instruction in this repetition
      nextInstructionIndex = state.currentInstructionIndex + 1;
      developer.log(
          'Moving to next instruction in repetition: $nextInstructionIndex');
    }

    // Update state with new instruction
    InstructionPhase nextPhase;
    final stepNumber = state.treatment!.steps[nextInstructionIndex].stepNumber;
    if (stepNumber == 1) {
      nextPhase = InstructionPhase.inhale;
    } else if (stepNumber == 2) {
      nextPhase = InstructionPhase.hold;
    } else {
      nextPhase = InstructionPhase.exhale;
    }

    emit(state.copyWith(
      currentInstructionIndex: nextInstructionIndex,
      currentRepetition: nextRepetition,
      instructionOpacity: 1.0,
      countdownOpacity: 0.0, // Ensure countdown is invisible initially
      countdownSeconds: state.treatment!.steps[nextInstructionIndex].duration,
      currentPhase: nextPhase,
      isAnimating: false, // Stop animation when showing new instruction
    ));

    developer
        .log('New instruction set: ${state.currentInstruction}, opacity: 1.0');

    // Schedule the countdown to appear after 2 seconds
    _delayTimer = Timer(const Duration(seconds: 2), () {
      add(const ShowCountdownForNextInstructionEvent());
    });
  }

  void _onShowCountdownForNextInstruction(
      ShowCountdownForNextInstructionEvent event,
      Emitter<DeepBreathingState> emit) {
    if (!state.isPlaying) return;

    developer.log(
        'Showing countdown for instruction ${state.currentInstructionIndex}');
    add(const ShowCountdownEvent());
  }

  
  void _onShowCountdown(
      ShowCountdownEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('ShowCountdownEvent triggered');
    if (!state.isPlaying || state.treatment == null) return;

    // Explicitly set countdown duration and make it visible
    final currentDuration = state.currentInstructionDuration;
    developer.log('Setting countdown seconds to: $currentDuration');

    emit(state.copyWith(
      countdownSeconds: currentDuration,
      countdownOpacity: 1.0,
      isAnimating: true, // Start the animation when countdown starts
    ));

    // Start countdown timer after confirming the countdown is visible
    _startCountdownTimer();
  }

  void _onResumeExercise(
      ResumeExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Resuming exercise');
    if (state.treatment == null) {
      developer.log('Cannot resume exercise: No treatment loaded');
      return;
    }

    // Cancel any existing timers
    _cancelTimers();

    // Determine if we should be animating
    bool shouldAnimate = event.remainingCountdownSeconds > 0;

    // Calculate phase based on instruction index
    InstructionPhase phase;
    if (state.treatment!.steps.isNotEmpty) {
      final stepNumber =
          state.treatment!.steps[event.currentInstructionIndex].stepNumber;
      if (stepNumber == 1) {
        phase = InstructionPhase.inhale;
      } else if (stepNumber == 2) {
        phase = InstructionPhase.hold;
      } else {
        phase = InstructionPhase.exhale;
      }
    } else {
      phase = InstructionPhase.inhale;
    }

    // Update state with provided values
    emit(state.copyWith(
      isPlaying: true,
      totalExerciseSeconds: event.remainingTotalSeconds,
      countdownSeconds: event.remainingCountdownSeconds,
      currentInstructionIndex: event.currentInstructionIndex,
      currentRepetition: event.currentRepetition,
      countdownOpacity: event.remainingCountdownSeconds > 0 ? 1.0 : 0.0,
      currentPhase: phase,
      isAnimating: shouldAnimate, // Only animate if countdown is active
    ));

    // Restart timers
    _startTotalTimer();
    if (event.remainingCountdownSeconds > 0) {
      _startCountdownTimer();
    }
  }

  // Modified to match first code: countdown stops at 1 second
  void _onCountdownTick(
      CountdownTickEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Countdown tick: ${state.countdownSeconds - 1}');
    if (state.countdownSeconds > 2) {
      // Change from > 1 to > 2
      emit(state.copyWith(
        countdownSeconds: state.countdownSeconds - 1,
      ));
    } else if (state.countdownSeconds == 2) {
      // Stop at 1 instead of going to 0
      emit(state.copyWith(
        countdownSeconds: 1, // This ensures we show "1" as the final number
      ));

      // Countdown is complete, cancel timer and fade out countdown
      developer.log('Countdown complete');
      _countdownTimer?.cancel();
      _countdownTimer = null;

      emit(state.copyWith(
        countdownOpacity: 0.0,
        isAnimating: false, // Stop animation when countdown ends
      ));

      // After animation delay, move to next instruction
      _delayTimer = Timer(const Duration(milliseconds: 500), () {
        add(const NextInstructionEvent());
      });
    }
  }

  void _onTotalTimerTick(
      TotalTimerTickEvent event, Emitter<DeepBreathingState> emit) {
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

  // Modified to match first code: fade out current instruction before moving to next
  void _onNextInstruction(
      NextInstructionEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Moving to next instruction');
    // Cancel any existing timers to prevent overlap
    _countdownTimer?.cancel();
    _countdownTimer = null;

    // Fade out current instruction
    emit(state.copyWith(
      instructionOpacity: 0.0,
      isAnimating: false, // Ensure animation is stopped
    ));

    // After fade out animation completes, dispatch a new event
    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      add(const FadeInNextInstructionEvent());
    });
  }

  void _onResetExercise(
      ResetExerciseEvent event, Emitter<DeepBreathingState> emit) {
    developer.log('Exercise reset');
    _cancelTimers();

    // Keep the loaded treatment but reset other fields
    final treatment = state.treatment;
    final initialState = DeepBreathingState.initial();

    // If we have a treatment, recalculate the total exercise time
    int totalExerciseTime = initialState.totalExerciseSeconds;
    if (treatment != null && treatment.steps.isNotEmpty) {
      totalExerciseTime = calculateTotalExerciseTime(treatment);
    }

    emit(initialState.copyWith(
      treatment: treatment,
      totalExerciseSeconds: totalExerciseTime,
    ));
  }

  // Helper method to calculate total exercise time (fixed in code)
  int calculateTotalExerciseTime(Treatment treatment) {
    int totalStepsDuration = 0;
    for (var step in treatment.steps) {
      totalStepsDuration += step.duration;
    }
    return totalRepetitions *
        (totalStepsDuration + transitionTimePerRepetition);
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

    @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}