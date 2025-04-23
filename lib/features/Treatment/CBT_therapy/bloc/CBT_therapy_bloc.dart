import 'dart:async';
import 'dart:math';
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

class PauseCBTTreatmentEvent extends CBTTherapyEvent {
  const PauseCBTTreatmentEvent();
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
  final String userThought;
  final String alternativeThought;
  final String supportingEvidence;
  final String contradictingEvidence;

  const NextCBTStepEvent({
    this.userThought = '',
    this.alternativeThought = '',
    this.supportingEvidence = '',
    this.contradictingEvidence = '',
  });

  @override
  List<Object> get props => [
        userThought,
        alternativeThought,
        supportingEvidence,
        contradictingEvidence
      ];
}

class UpdateInstructionOpacityEvent extends CBTTherapyEvent {
  final double opacity;

  const UpdateInstructionOpacityEvent({required this.opacity});

  @override
  List<Object?> get props => [opacity];
}

class UpdateElapsedTimeEvent extends CBTTherapyEvent {
  final int elapsedTimeSeconds;

  const UpdateElapsedTimeEvent({required this.elapsedTimeSeconds});

  @override
  List<Object?> get props => [elapsedTimeSeconds];
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
  final String supportingEvidence;
  final String contradictingEvidence;

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
    this.supportingEvidence = '',
    this.contradictingEvidence = '',
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
    String? supportingEvidence,
    String? contradictingEvidence,
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
      supportingEvidence: supportingEvidence ?? this.supportingEvidence,
      contradictingEvidence:
          contradictingEvidence ?? this.contradictingEvidence,
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
        supportingEvidence,
        contradictingEvidence,
      ];
}

// Bloc
class CBTTherapyBloc extends Bloc<CBTTherapyEvent, CBTTherapyState> {
  final CBTRepository _repository;
  Timer? _timer;
  Timer? _instructionTimer;
  Timer? _progressUpdateTimer;

  // Cache structures
  final Map<String, List<String>> _instructionsCache = {};
  Map<String, bool>? _cognitiveDistortionsCache;
  DateTime? _cognitiveDistortionsCacheTime;

  // Cache expiration duration - adjust as needed
  static const Duration _cacheDuration = Duration(hours: 1);
  static const int progressUpdateInterval = 10;

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
    on<UpdateInstructionOpacityEvent>(_onUpdateInstructionOpacity);
    on<UpdateElapsedTimeEvent>(_onUpdateElapsedTime);
    on<PauseCBTTreatmentEvent>(_onPauseTreatment);
  }

  // Helper method to check if cache is valid
  bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    final now = DateTime.now();
    return now.difference(cacheTime) < _cacheDuration;
  }

  void _onUpdateInstructionOpacity(
      UpdateInstructionOpacityEvent event, Emitter<CBTTherapyState> emit) {
    emit(state.copyWith(instructionOpacity: event.opacity));
  }

  void _onUpdateElapsedTime(
      UpdateElapsedTimeEvent event, Emitter<CBTTherapyState> emit) {
    emit(state.copyWith(elapsedTimeSeconds: event.elapsedTimeSeconds));
  }

  Future<void> _onPauseTreatment(
      PauseCBTTreatmentEvent event, Emitter<CBTTherapyState> emit) async {
    if (state.userTreatmentId == null) return;

    try {
      // Create a userData map with the current user inputs
      final Map<String, dynamic> userData = {
        'userThought': state.userThought,
        'alternativeThought': state.alternativeThought,
        'cognitiveDistortions': state.cognitiveDistortions,
        'supportingEvidence': state.supportingEvidence,
        'contradictingEvidence': state.contradictingEvidence,
      };

      // Calculate current progress
      final progressPercentage = (state.currentStep / state.totalSteps) * 100;

      await _repository.trackUserTreatment(
        treatmentId: 'CBTtherapy',
        status: TreatmentStatus.paused,
        userTreatmentId: state.userTreatmentId,
        progress: progressPercentage,
        userData: userData, // Pass the userData to be saved
      );

      emit(state.copyWith(progress: progressPercentage));
    } catch (e) {
      print('Error pausing treatment: $e');
    }
  }

  void debugCognitiveDistortions() {
    print('---------------- COGNITIVE DISTORTIONS DEBUG ----------------');
    print(
        'Current cognitive distortions in state: ${state.cognitiveDistortions}');
    print('Number of distortions: ${state.cognitiveDistortions.length}');
    print(
        'Are any distortions selected: ${state.cognitiveDistortions.containsValue(true)}');
    print('--------------------------------------------------------------');
  }

  Future<void> _onStartTrackingTreatment(StartTrackingCBTTreatmentEvent event,
      Emitter<CBTTherapyState> emit) async {
    try {
      // If we already have a userTreatmentId, we should resume rather than create a new document
      if (state.userTreatmentId != null) {
        // Update the existing treatment to in-progress status
        await _repository.trackUserTreatment(
          treatmentId: 'CBTtherapy',
          status: TreatmentStatus.inProgress,
          userTreatmentId: state.userTreatmentId,
          emotionFeedback: "sad",
          progress: state.progress,
        );
      } else {
        // Create a new treatment document
        final userTreatmentId = await _repository.trackUserTreatment(
          treatmentId: 'CBTtherapy',
          status: TreatmentStatus.started,
          emotionFeedback: "sad",
          progress: 0.0,
        );

        emit(state.copyWith(userTreatmentId: userTreatmentId));
        print('CBT treatment tracking started with ID: $userTreatmentId');
      }

      _startProgressUpdateTimer();
    } catch (e) {
      print('Error starting CBT treatment tracking: $e');
    }
  }

  Future<void> _onUpdateTreatmentProgress(UpdateCBTTreatmentProgressEvent event,
      Emitter<CBTTherapyState> emit) async {
    if (state.userTreatmentId == null) return;

    try {
      // Create a userData map with the current user inputs
      final Map<String, dynamic> userData = {
        'userThought': state.userThought,
        'alternativeThought': state.alternativeThought,
        'cognitiveDistortions': state.cognitiveDistortions,
      };

      await _repository.trackUserTreatment(
        treatmentId: 'CBTtherapy',
        status: TreatmentStatus.inProgress,
        userTreatmentId: state.userTreatmentId,
        progress: event.progress,
        userData: userData, // Pass the userData to be saved
      );

      emit(state.copyWith(progress: event.progress));
    } catch (e) {
      print('Error updating treatment progress: $e');
    }
  }

  Future<void> _onCompleteTreatment(
      CompleteCBTTreatmentEvent event, Emitter<CBTTherapyState> emit) async {
    if (state.userTreatmentId == null) return;

    try {
      await _repository.trackUserTreatment(
        treatmentId: 'CBTtherapy',
        status: TreatmentStatus.completed,
        emotionFeedback: event.emotion,
        userTreatmentId: state.userTreatmentId,
        progress: 100.0,
      );
    } catch (e) {
      print('Error completing treatment tracking: $e');
    }
  }

  Future<void> _onLoadUserTreatment(
      LoadUserCBTTreatmentEvent event, Emitter<CBTTherapyState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, isError: false, errorMessage: ''));

      // First, load the CBT data
      await _onLoadData(LoadCBTDataEvent(treatmentId: event.treatmentId), emit);

      // Then get the user treatment details
      final userTreatment =
          await _repository.getUserTreatmentById(event.userTreatmentId);

      if (userTreatment == null) {
        throw Exception("Couldn't find the specific treatment session");
      }

      final progress = userTreatment['progress'] as double? ?? 0.0;
      final totalSteps = state.totalSteps;

      // Calculate current step from progress
      final currentStep =
          min(((progress / 100) * totalSteps).ceil(), totalSteps);
      final currentInstructionIndex = currentStep > 0 ? currentStep - 1 : 0;

      final estimatedSecondsPerStep = 60;
      final estimatedElapsedTime = currentStep * estimatedSecondsPerStep;

      // Retrieve saved user input data
      String userThought = '';
      String alternativeThought = '';
      String supportingEvidence = '';
      String contradictingEvidence = '';
      Map<String, bool>? cognitiveDistortions;

      // Check if additional data exists in userTreatment
      if (userTreatment.containsKey('userData')) {
        final userData = userTreatment['userData'] as Map<String, dynamic>?;
        if (userData != null) {
          userThought = userData['userThought'] as String? ?? '';
          alternativeThought = userData['alternativeThought'] as String? ?? '';
          supportingEvidence = userData['supportingEvidence'] as String? ?? '';
          contradictingEvidence =
              userData['contradictingEvidence'] as String? ?? '';

          // Restore cognitive distortions if saved
          if (userData.containsKey('cognitiveDistortions')) {
            final distortionsData =
                userData['cognitiveDistortions'] as Map<String, dynamic>?;
            if (distortionsData != null) {
              cognitiveDistortions = {};
              distortionsData.forEach((key, value) {
                cognitiveDistortions![key] = value as bool;
              });
            }
          }
        }
      }

      // Determine the treatment status
      final status = userTreatment['status'] as String? ?? 'paused';

      // IMPORTANT FIX: Set isPlaying to true when resuming
      // This will make sure the UI shows the fields for the current step
      // rather than just showing the "Start" button
      final bool isPlaying = progress > 0 && currentStep > 0;

      emit(state.copyWith(
        isLoading: false,
        userTreatmentId: event.userTreatmentId,
        progress: progress,
        currentStep: max(currentStep, 1),
        currentInstructionIndex: currentInstructionIndex,
        elapsedTimeSeconds: estimatedElapsedTime,
        userThought: userThought,
        alternativeThought: alternativeThought,
        supportingEvidence: supportingEvidence,
        contradictingEvidence: contradictingEvidence,
        cognitiveDistortions:
            cognitiveDistortions ?? state.cognitiveDistortions,
        // IMPORTANT FIX: Set isPlaying flag to show proper fields
        isPlaying: isPlaying,
      ));

      print(
          'Loaded user CBT treatment: ${event.userTreatmentId} with progress: $progress%, currentStep: $currentStep, isPlaying: $isPlaying');
    } catch (e) {
      print('Error loading user CBT treatment: $e');
      emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage:
              'Failed to load CBT treatment session: ${e.toString()}'));
    }
  }

  Future<void> _onLoadData(
      LoadCBTDataEvent event, Emitter<CBTTherapyState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, isError: false, errorMessage: ''));

      // Fetch instructions with caching
      List<String> instructions;
      if (_instructionsCache.containsKey(event.treatmentId)) {
        print("Using cached instructions for ${event.treatmentId}");
        instructions = _instructionsCache[event.treatmentId]!;
      } else {
        print("Fetching instructions for ${event.treatmentId}");
        instructions = await _repository.fetchInstructions(event.treatmentId);
        _instructionsCache[event.treatmentId] = instructions;
      }

      print("Loaded instructions: $instructions");

      // Fetch cognitive distortions with caching
      Map<String, bool> cognitiveDistortions;
      if (_cognitiveDistortionsCache != null &&
          _isCacheValid(_cognitiveDistortionsCacheTime)) {
        print("Using cached cognitive distortions");
        cognitiveDistortions = _cognitiveDistortionsCache!;
      } else {
        print("Fetching cognitive distortions");
        cognitiveDistortions = await _repository.fetchCognitiveDistortions();
        _cognitiveDistortionsCache = cognitiveDistortions;
        _cognitiveDistortionsCacheTime = DateTime.now();
      }

      print("Loaded cognitive distortions: $cognitiveDistortions");

      emit(state.copyWith(
        isLoading: false,
        instructions: instructions,
        cognitiveDistortions: cognitiveDistortions,
        totalSteps: instructions.length,
      ));

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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(UpdateElapsedTimeEvent(
          elapsedTimeSeconds: state.elapsedTimeSeconds + 1));
    });

    emit(state.copyWith(isPlaying: true));
    _startInstructionAnimation(emit);
    add(const StartTrackingCBTTreatmentEvent());
  }

  void _onPauseExercise(
      PauseCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
    ));

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

    add(const CompleteCBTTreatmentEvent());
  }

  void _onResetExercise(
      ResetCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();

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
          state.cognitiveDistortions.keys.map((key) => MapEntry(key, false))),
    ));
  }

  void _onNextStep(NextCBTStepEvent event, Emitter<CBTTherapyState> emit) {
    if (state.currentStep < state.totalSteps) {
      final Map<String, bool> cogDistortions =
          event.userThought != null && event.userThought.isNotEmpty
              ? state.cognitiveDistortions
              : Map.fromEntries(state.cognitiveDistortions.keys
                  .map((key) => MapEntry(key, false)));

      emit(state.copyWith(
        currentStep: state.currentStep + 1,
        currentInstructionIndex: state.currentInstructionIndex + 1,
        instructionOpacity: 1.0,
        userThought: event.userThought.isNotEmpty
            ? event.userThought
            : state.userThought,
        alternativeThought: event.alternativeThought.isNotEmpty
            ? event.alternativeThought
            : state.alternativeThought,
        supportingEvidence: event.supportingEvidence.isNotEmpty
            ? event.supportingEvidence
            : state.supportingEvidence,
        contradictingEvidence: event.contradictingEvidence.isNotEmpty
            ? event.contradictingEvidence
            : state.contradictingEvidence,
      ));

      _instructionTimer?.cancel();
      _instructionTimer =
          Timer.periodic(const Duration(milliseconds: 4000), (_) {
        if (!emit.isDone) {
          emit(state.copyWith(instructionOpacity: 0.0));
        }
      });
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
        const Duration(seconds: progressUpdateInterval), (timer) {
      if (state.totalSteps > 0) {
        final progressPercentage = (state.currentStep / state.totalSteps) * 100;
        add(UpdateCBTTreatmentProgressEvent(progress: progressPercentage));
      }
    });
  }

  void _startInstructionAnimation(Emitter<CBTTherapyState> emit) {
    _instructionTimer?.cancel();

    _instructionTimer = Timer.periodic(const Duration(milliseconds: 4000), (_) {
      add(const UpdateInstructionOpacityEvent(opacity: 0.0));

      Future.delayed(const Duration(milliseconds: 500), () {
        add(const UpdateInstructionOpacityEvent(opacity: 1.0));
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

  // Method to clear caches (useful for testing or when user wants fresh data)
  void clearCaches() {
    _instructionsCache.clear();
    _cognitiveDistortionsCache = null;
    _cognitiveDistortionsCacheTime = null;
    print('Caches cleared');
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
