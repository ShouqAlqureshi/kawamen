
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class CBTTherapyEvent extends Equatable {
  const CBTTherapyEvent();

  @override
  List<Object?> get props => [];
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

// State
class CBTTherapyState extends Equatable {
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

  const CBTTherapyState({
    this.isPlaying = false,
    this.isCompleting = false,
    this.currentStep = 1,
    this.totalSteps = 5,
    this.elapsedTimeSeconds = 0,
    this.currentInstructionIndex = 0,
    this.instructionOpacity = 1.0,
    this.userThought = '',
    this.alternativeThought = '',
    required this.cognitiveDistortions,
    required this.instructions,
  });

  CBTTherapyState copyWith({
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
  }) {
    return CBTTherapyState(
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleting: isCompleting ?? this.isCompleting,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      elapsedTimeSeconds: elapsedTimeSeconds ?? this.elapsedTimeSeconds,
      currentInstructionIndex: currentInstructionIndex ?? this.currentInstructionIndex,
      instructionOpacity: instructionOpacity ?? this.instructionOpacity,
      userThought: userThought ?? this.userThought,
      alternativeThought: alternativeThought ?? this.alternativeThought,
      cognitiveDistortions: cognitiveDistortions ?? this.cognitiveDistortions,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  List<Object?> get props => [
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
  ];
}

// Bloc
class CBTTherapyBloc extends Bloc<CBTTherapyEvent, CBTTherapyState> {
  Timer? _timer;
  Timer? _instructionTimer;

  CBTTherapyBloc() 
      : super(CBTTherapyState(
          cognitiveDistortions: {
            'التفكير الثنائي (كل شيء أو لا شيء)': false,
            'التعميم المفرط': false,
            'التصفية العقلية (التركيز على السلبيات)': false,
            'القفز إلى الاستنتاجات': false,
            'التهويل أو التقليل': false,
            'الاستدلال العاطفي': false,
            'العبارات الإلزامية (يجب، ينبغي)': false,
            'التسمية الخاطئة': false,
            'لوم الذات أو الآخرين': false,
          },
          instructions: [
            'تعرّف على أفكارك',
            'حدد التشويهات المعرفية',
            'تحدى أفكارك',
            'ابتكر أفكاراً بديلة',
            'تأمل وانعكس',
          ],
        )) {
    on<StartCBTExerciseEvent>(_onStartExercise);
    on<PauseCBTExerciseEvent>(_onPauseExercise);
    on<ResetCBTExerciseEvent>(_onResetExercise);
    on<NextCBTStepEvent>(_onNextStep);
    on<PreviousCBTStepEvent>(_onPreviousStep);
    on<ToggleDistortionEvent>(_onToggleDistortion);
    on<CompleteCBTExerciseEvent>(_onCompleteExercise);
  }

  void _onStartExercise(StartCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
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
  }

  void _onPauseExercise(PauseCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
    ));
  }

  void _onResetExercise(ResetCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(CBTTherapyState(
      cognitiveDistortions: {
        'التفكير الثنائي (كل شيء أو لا شيء)': false,
        'التعميم المفرط': false,
        'التصفية العقلية (التركيز على السلبيات)': false,
        'القفز إلى الاستنتاجات': false,
        'التهويل أو التقليل': false,
        'الاستدلال العاطفي': false,
        'العبارات الإلزامية (يجب، ينبغي)': false,
        'التسمية الخاطئة': false,
        'لوم الذات أو الآخرين': false,
      },
      instructions: state.instructions,
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
      final newState = event.userThought != null && event.userThought!.isNotEmpty
          ? updatedState.copyWith(userThought: event.userThought)
          : updatedState;
      
      // Update alternative thought if provided and not empty
      final finalState = event.alternativeThought != null && event.alternativeThought!.isNotEmpty
          ? newState.copyWith(alternativeThought: event.alternativeThought)
          : newState;
      
      emit(finalState);
      
      // Start instruction animation for the new step
      _startInstructionAnimation(emit);
    }
  }

  void _onPreviousStep(PreviousCBTStepEvent event, Emitter<CBTTherapyState> emit) {
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

  void _onToggleDistortion(ToggleDistortionEvent event, Emitter<CBTTherapyState> emit) {
    final updatedDistortions = Map<String, bool>.from(state.cognitiveDistortions);
    updatedDistortions[event.distortion] = !updatedDistortions[event.distortion]!;
    
    emit(state.copyWith(
      cognitiveDistortions: updatedDistortions,
    ));
  }

  void _onCompleteExercise(CompleteCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isCompleting: true,
    ));
  }

  // Helper method to start instruction animation
  void _startInstructionAnimation(Emitter<CBTTherapyState> emit) {
    _instructionTimer?.cancel();
    
    // Fade in-out animation for instructions
    _instructionTimer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
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
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}