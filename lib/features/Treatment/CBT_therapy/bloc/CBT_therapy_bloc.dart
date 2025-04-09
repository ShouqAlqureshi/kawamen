import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kawamen/features/Treatment/deep_breathing/bloc/deep_breathing_bloc.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/repository/CBT_therapy_repository.dart';

// Events
abstract class CBTTherapyEvent extends Equatable {
  const CBTTherapyEvent();

  @override
  List<Object?> get props => [];
}

class LoadCBTDataEvent extends CBTTherapyEvent {
  final String treatmentId;
  
  const LoadCBTDataEvent({required this.treatmentId});
  
  @override
  List<Object?> get props => [treatmentId];
}

class StartCBTExerciseEvent extends CBTTherapyEvent {}

class PauseCBTExerciseEvent extends CBTTherapyEvent {}

class ResetCBTExerciseEvent extends CBTTherapyEvent {}

class NextCBTStepEvent extends CBTTherapyEvent {
  final String? userThought;
  final String? alternativeThought;

  const NextCBTStepEvent({this.userThought, this.alternativeThought});

  @override
  List<Object?> get props => [userThought, alternativeThought];
}

class PreviousCBTStepEvent extends CBTTherapyEvent {}

class ToggleDistortionEvent extends CBTTherapyEvent {
  final String distortion;

  const ToggleDistortionEvent({required this.distortion});

  @override
  List<Object?> get props => [distortion];
}

class CompleteCBTExerciseEvent extends CBTTherapyEvent {}
class StartTrackingCBTTreatmentEvent extends CBTTherapyEvent {
  const StartTrackingCBTTreatmentEvent();
}

class UpdateCBTTreatmentProgressEvent extends CBTTherapyEvent {
  final double progress;

  const UpdateCBTTreatmentProgressEvent({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class CompleteCBTTreatmentEvent extends CBTTherapyEvent {
  final String? emotion;

  const CompleteCBTTreatmentEvent({this.emotion});

  @override
  List<Object?> get props => [emotion];
}

class LoadUserCBTTreatmentEvent extends CBTTherapyEvent {
  final String userTreatmentId;
  final String treatmentId;

  const LoadUserCBTTreatmentEvent({
    required this.userTreatmentId,
    required this.treatmentId,
  });

  @override
  List<Object?> get props => [userTreatmentId, treatmentId];
}
// State
class CBTTherapyState extends Equatable {
  final bool isLoading;
  final bool isError;
  final String errorMessage;
  final bool isPlaying;
  final bool isCompleting;
  final int currentStep;
  final int totalSteps;
  final int elapsedTimeSeconds;
  final int currentInstructionIndex;
  final double instructionOpacity;
  final String userThought;
  final String alternativeThought;
  final Map<String, bool> cognitiveDistortions;
  final List<String> instructions;
  final String? userTreatmentId;  
  final double progress; 

  const CBTTherapyState({
    this.isLoading = true,
    this.isError = false,
    this.errorMessage = '',
    this.isPlaying = false,
    this.isCompleting = false,
    this.currentStep = 1,
    this.totalSteps = 5,
    this.elapsedTimeSeconds = 0,
    this.currentInstructionIndex = 0,
    this.instructionOpacity = 1.0,
    this.userThought = '',
    this.alternativeThought = '',
    this.cognitiveDistortions = const {},
    this.instructions = const [],
    this.userTreatmentId,   
    this.progress = 0.0, 
  });

  CBTTherapyState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    bool? isPlaying,
    bool? isCompleting,
    int? currentStep,
    int? totalSteps,
    int? elapsedTimeSeconds,
    int? currentInstructionIndex,
    double? instructionOpacity,
    String? userThought,
    String? alternativeThought,
    Map<String, bool>? cognitiveDistortions,
    List<String>? instructions,
    String? userTreatmentId, 
    double? progress, 
  }) {
    return CBTTherapyState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleting: isCompleting ?? this.isCompleting,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      elapsedTimeSeconds: elapsedTimeSeconds ?? this.elapsedTimeSeconds,
      currentInstructionIndex:
          currentInstructionIndex ?? this.currentInstructionIndex,
      instructionOpacity: instructionOpacity ?? this.instructionOpacity,
      userThought: userThought ?? this.userThought,
      alternativeThought: alternativeThought ?? this.alternativeThought,
      cognitiveDistortions: cognitiveDistortions ?? this.cognitiveDistortions,
      instructions: instructions ?? this.instructions,
      userTreatmentId: userTreatmentId ?? this.userTreatmentId, 
      progress: progress ?? this.progress,         
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isError,
        errorMessage,
        isPlaying,
        isCompleting,
        currentStep,
        totalSteps,
        elapsedTimeSeconds,
        currentInstructionIndex,
        instructionOpacity,
        userThought,
        alternativeThought,
        cognitiveDistortions,
        instructions,
        userTreatmentId,  
        progress,  
      ];
}

// Bloc
class CBTTherapyBloc extends Bloc<CBTTherapyEvent, CBTTherapyState> {
  final CBTRepository _repository;
  Timer? _timer;
  Timer? _instructionTimer;
   Timer? _progressUpdateTimer; // Add timer for regular progress updates
  
  static const int progressUpdateInterval = 10; // Update progress every 10 seconds

  CBTTherapyBloc({CBTRepository? repository})
      : _repository = repository ?? CBTRepository(),
        super(const CBTTherapyState()) {
    on<LoadCBTDataEvent>(_onLoadData);
    on<StartCBTExerciseEvent>(_onStartExercise);
    on<PauseCBTExerciseEvent>(_onPauseExercise);
    on<ResetCBTExerciseEvent>(_onResetExercise);
    on<NextCBTStepEvent>(_onNextStep);
    on<PreviousCBTStepEvent>(_onPreviousStep);
    on<ToggleDistortionEvent>(_onToggleDistortion);
    on<CompleteCBTExerciseEvent>(_onCompleteExercise);
    on<StartTrackingCBTTreatmentEvent>(_onStartTrackingTreatment);
    on<UpdateCBTTreatmentProgressEvent>(_onUpdateTreatmentProgress);
    on<CompleteCBTTreatmentEvent>(_onCompleteTreatment);
    on<LoadUserCBTTreatmentEvent>(_onLoadUserTreatment);
  }

  // Add this method to your CBTTherapyBloc class
void debugCognitiveDistortions() {
  print('---------------- COGNITIVE DISTORTIONS DEBUG ----------------');
  print('Current cognitive distortions in state: ${state.cognitiveDistortions}');
  print('Number of distortions: ${state.cognitiveDistortions.length}');
  print('Are any distortions selected: ${state.cognitiveDistortions.containsValue(true)}');
  print('--------------------------------------------------------------');
}
//test
 Future<void> _onStartTrackingTreatment(
      StartTrackingCBTTreatmentEvent event,
      Emitter<CBTTherapyState> emit) async {
    try {
      final userTreatmentId = await _repository.trackUserTreatment(
        treatmentId: 'CBTtherapy', // Assuming 'CBTtherapy' is your default treatmentId
        status: TreatmentStatus.started,
        emotionFeedback: "sad", // Default emotion when starting
        progress: 0.0,
      );
      
      emit(state.copyWith(userTreatmentId: userTreatmentId));
      print('CBT treatment tracking started with ID: $userTreatmentId');
      
      // Start progress update timer
      _startProgressUpdateTimer();
    } catch (e) {
      print('Error starting CBT treatment tracking: $e');
    }
  }

  Future<void> _onUpdateTreatmentProgress(
      UpdateCBTTreatmentProgressEvent event,
      Emitter<CBTTherapyState> emit) async {
    if (state.userTreatmentId == null) return;

    try {
      await _repository.trackUserTreatment(
        treatmentId: 'CBTtherapy', // Assuming 'CBTtherapy' is your default treatmentId
        status: TreatmentStatus.inProgress,
        userTreatmentId: state.userTreatmentId,
        progress: event.progress,
      );
      
      emit(state.copyWith(progress: event.progress));
    } catch (e) {
      print('Error updating treatment progress: $e');
    }
  }

  Future<void> _onCompleteTreatment(
      CompleteCBTTreatmentEvent event,
      Emitter<CBTTherapyState> emit) async {
    if (state.userTreatmentId == null) return;

    try {
      await _repository.trackUserTreatment(
        treatmentId: 'CBTtherapy', // Assuming 'CBTtherapy' is your default treatmentId
        status: TreatmentStatus.completed,
        emotionFeedback: event.emotion,
        userTreatmentId: state.userTreatmentId,
        progress: 100.0, // Completed means 100%
      );
    } catch (e) {
      print('Error completing treatment tracking: $e');
    }
  }

  Future<void> _onLoadUserTreatment(
      LoadUserCBTTreatmentEvent event,
      Emitter<CBTTherapyState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, isError: false, errorMessage: ''));

      // First, load the CBT data
      await _onLoadData(LoadCBTDataEvent(treatmentId: event.treatmentId), emit);
      
      // Then get the user treatment details
      final userTreatment = await _repository.getUserTreatmentById(event.userTreatmentId);
      
      if (userTreatment == null) {
        throw Exception("Couldn't find the specific treatment session");
      }
      
      // Get stored progress
      final progress = userTreatment['progress'] as double? ?? 0.0;
      
      // Calculate the current step and elapsed time based on progress
      final totalSteps = state.totalSteps;
      final completedSteps = ((totalSteps * progress) / 100).floor();
      final currentStep = completedSteps + 1;
      
      // Determine elapsed time based on progress
      // Assuming each step takes roughly the same amount of time
      final estimatedSecondsPerStep = 60; // Example: each step takes about 60 seconds
      final estimatedElapsedTime = completedSteps * estimatedSecondsPerStep;
      
      emit(state.copyWith(
        isLoading: false,
        userTreatmentId: event.userTreatmentId,
        progress: progress,
        currentStep: currentStep > totalSteps ? totalSteps : currentStep,
        elapsedTimeSeconds: estimatedElapsedTime,
      ));
      
      print('Loaded user CBT treatment: ${event.userTreatmentId} with progress: $progress%');
    } catch (e) {
      print('Error loading user CBT treatment: $e');
      emit(state.copyWith(
        isLoading: false,
        isError: true, 
        errorMessage: 'Failed to load CBT treatment session: ${e.toString()}'
      ));
    }
  }
// Modify your _onLoadData method to call this debug function
Future<void> _onLoadData(
  LoadCBTDataEvent event, Emitter<CBTTherapyState> emit) async {
  try {
    emit(state.copyWith(isLoading: true, isError: false, errorMessage: ''));

    // Fetch instructions from database
    final List<String> instructions = 
        await _repository.fetchInstructions(event.treatmentId);
    
    print("Loaded instructions: $instructions");
    
    // Fetch cognitive distortions
    final Map<String, bool> cognitiveDistortions = 
        await _repository.fetchCognitiveDistortions();
        
    print("Loaded cognitive distortions: $cognitiveDistortions");

    emit(state.copyWith(
      isLoading: false,
      instructions: instructions,
      cognitiveDistortions: cognitiveDistortions,
      totalSteps: instructions.length,
    ));
    
    // Debug after state update
    debugCognitiveDistortions();
    
    print("New state instructions: ${state.instructions}");
    print("New state totalSteps: ${state.totalSteps}");
  } catch (e) {
    print("Error in _onLoadData: $e");
    emit(state.copyWith(
      isLoading: false,
      isError: true,
      errorMessage: 'Failed to load CBT exercise data: $e',
    ));
  }
}

  void _onStartExercise(
      StartCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    if (state.instructions.isEmpty) {
      emit(state.copyWith(
        isError: true,
        errorMessage: 'Cannot start exercise: Instructions not loaded',
      ));
      return;
    }

    _cancelTimers();

    // Start the timer for elapsed time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      emit(state.copyWith(
        elapsedTimeSeconds: state.elapsedTimeSeconds + 1,
      ));
    });

    // Start instruction timer for animation
    _startInstructionAnimation(emit);

    emit(state.copyWith(
      isPlaying: true,
    ));
    
    // Start tracking treatment
    add(const StartTrackingCBTTreatmentEvent());
  }

  void _onPauseExercise(
      PauseCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
    ));
    
    // Update progress when paused
    if (state.totalSteps > 0) {
      final progressPercentage = (state.currentStep / state.totalSteps) * 100;
      add(UpdateCBTTreatmentProgressEvent(progress: progressPercentage));
    }
  }

  void _onCompleteExercise(
      CompleteCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isCompleting: true,
    ));
    
    // Complete tracking
    add(const CompleteCBTTreatmentEvent());
  }

  void _onResetExercise(
      ResetCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    
    // Reset the state but keep the fetched instructions and distortions
    emit(state.copyWith(
      isPlaying: false,
      isCompleting: false,
      currentStep: 1,
      elapsedTimeSeconds: 0,
      currentInstructionIndex: 0,
      instructionOpacity: 1.0,
      userThought: '',
      alternativeThought: '',
      cognitiveDistortions: Map.fromEntries(
        state.cognitiveDistortions.keys.map((key) => MapEntry(key, false))
      ),
    ));
  }

  void _onNextStep(NextCBTStepEvent event, Emitter<CBTTherapyState> emit) {
    if (state.currentStep < state.totalSteps) {
      // Update state with user inputs if provided
      final updatedState = state.copyWith(
        currentStep: state.currentStep + 1,
        currentInstructionIndex: state.currentInstructionIndex + 1,
        instructionOpacity: 1.0,
      );

      // Update user thought if provided and not empty
      final newState =
          event.userThought != null && event.userThought!.isNotEmpty
              ? updatedState.copyWith(userThought: event.userThought)
              : updatedState;

      // Update alternative thought if provided and not empty
      final finalState = event.alternativeThought != null &&
              event.alternativeThought!.isNotEmpty
          ? newState.copyWith(alternativeThought: event.alternativeThought)
          : newState;

      emit(finalState);

      // Start instruction animation for the new step
      _startInstructionAnimation(emit);
    }
  }

  void _onPreviousStep(
      PreviousCBTStepEvent event, Emitter<CBTTherapyState> emit) {
    if (state.currentStep > 1) {
      emit(state.copyWith(
        currentStep: state.currentStep - 1,
        currentInstructionIndex: state.currentInstructionIndex - 1,
        instructionOpacity: 1.0,
      ));

      // Start instruction animation for the previous step
      _startInstructionAnimation(emit);
    }
  }

  void _onToggleDistortion(
      ToggleDistortionEvent event, Emitter<CBTTherapyState> emit) {
    final updatedDistortions =
        Map<String, bool>.from(state.cognitiveDistortions);
    updatedDistortions[event.distortion] =
        !updatedDistortions[event.distortion]!;

    emit(state.copyWith(
      cognitiveDistortions: updatedDistortions,
    ));
  }
void _startProgressUpdateTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(
      const Duration(seconds: progressUpdateInterval), 
      (timer) {
        if (state.totalSteps > 0) {
          final progressPercentage = (state.currentStep / state.totalSteps) * 100;
          add(UpdateCBTTreatmentProgressEvent(progress: progressPercentage));
        }
      }
    );
  }
  // Helper method to start instruction animation
  void _startInstructionAnimation(Emitter<CBTTherapyState> emit) {
    _instructionTimer?.cancel();

    // Fade in-out animation for instructions
    _instructionTimer =
        Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      emit(state.copyWith(instructionOpacity: 0.0));

      Future.delayed(const Duration(milliseconds: 500), () {
        emit(state.copyWith(instructionOpacity: 1.0));
      });
    });
  }

  void _cancelTimers() {
    _timer?.cancel();
    _timer = null;
    _instructionTimer?.cancel();
    _instructionTimer = null;
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}