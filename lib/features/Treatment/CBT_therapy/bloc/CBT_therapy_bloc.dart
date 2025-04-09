import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CBTRepository {
  final FirebaseFirestore _firestore;

  CBTRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Fetch treatment details including steps
  Future<Map<String, dynamic>> fetchTreatmentDetails(String treatmentId) async {
    try {
      // Get treatment document
      final treatmentDoc =
          await _firestore.collection('treatments ').doc(treatmentId).get();

      if (!treatmentDoc.exists) {
        throw Exception('Treatment not found');
      }

      final treatmentData = treatmentDoc.data()!;

      // Get treatment steps
      final stepsSnapshot = await _firestore
          .collection('treatments ')
          .doc(treatmentId)
          .collection('steps')
          .orderBy('stepNumber')
          .get();

      final steps = stepsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'stepNumber': data['stepNumber'],
          'instruction': data['instruction'],
          'mediaURL': data['mediaURL'],
        };
      }).toList();

      // Get cognitive distortions (assuming they're stored as a subcollection or field)
      List<String> cognitiveDistortions =
          treatmentData['cognitiveDistortions'] != null
              ? List<String>.from(treatmentData['cognitiveDistortions'])
              : [];

      return {
        'id': treatmentDoc.id,
        'name': treatmentData['name'],
        'description': treatmentData['description'],
        'type': treatmentData['type'],
        'steps': steps,
        'cognitiveDistortions': cognitiveDistortions,
      };
    } catch (e) {
      throw Exception('Failed to fetch treatment: $e');
    }
  }

  // Fetch instructions for CBT exercise
  Future<List<String>> fetchInstructions(String treatmentId) async {
  try {
    print('Fetching instructions for treatmentId: $treatmentId');
    
    final treatmentDoc = await _firestore
        .collection('treatments ').doc(treatmentId).get();
    
    print('Treatment document exists: ${treatmentDoc.exists}');
    
    final stepsSnapshot = await _firestore
        .collection('treatments ') 
        .doc(treatmentId)
        .collection('steps')
        .orderBy('stepNumber')
        .get();
    
    print('Found ${stepsSnapshot.docs.length} steps');
    
    if (stepsSnapshot.docs.isEmpty) {
      print('No steps found for this treatment');
      return [];
    }
    
    List<String> instructions = [];
    for (var doc in stepsSnapshot.docs) {
      final data = doc.data();
      print('Step data: $data');
      if (data.containsKey('instruction')) {
        instructions.add(data['instruction'] as String);
      } else {
        print('Warning: Missing instruction field in step ${doc.id}');
      }
    }
    
    print('Parsed ${instructions.length} instructions');
    return instructions;
  } catch (e) {
    print('Error fetching instructions: $e');
    throw Exception('Failed to fetch instructions: $e');
  }
}

  // Fetch cognitive distortions
 // Direct method to fetch cognitive distortions from the specified path
Future<Map<String, bool>> fetchCognitiveDistortions() async {
  try {
    print('Attempting to fetch cognitive distortions directly from the specified path');
    
    // Also try with space
    final treatmentsSpaceSnapshot = await _firestore.collection('treatments ').get();
    print('Found ${treatmentsSpaceSnapshot.docs.length} treatments (with space)');
    
    for (var doc in treatmentsSpaceSnapshot.docs) {
      print('Found treatment (with space): ${doc.id}');
    }
    
    // Try to get the CBTtherapy document specifically
    final therapyDoc = await _firestore.collection('treatments ').doc('CBTtherapy').get();
    print('CBTtherapy document exists: ${therapyDoc.exists}');
    
    if (therapyDoc.exists) {
      // Check if cognitive distortions are stored as a field rather than a subcollection
      final therapyData = therapyDoc.data() as Map<String, dynamic>?;
      
      if (therapyData != null && therapyData.containsKey('cognitiveDistortions')) {
        print('Found cognitive distortions as a field in CBTtherapy document');
        
        // Handle different possible formats
        final distortions = <String, bool>{};
        final distortionsData = therapyData['cognitiveDistortions'];
        
        if (distortionsData is List) {
          // If it's a list of strings
          for (var item in distortionsData) {
            if (item is String) {
              distortions[item] = false;
            }
          }
        } else if (distortionsData is Map) {
          // If it's a map
          distortionsData.forEach((key, value) {
            if (key is String) {
              distortions[key] = value is bool ? value : false;
            }
          });
        }
        
        if (distortions.isNotEmpty) {
          print('Successfully processed ${distortions.length} distortions from field');
          return distortions;
        }
      }
    }
    
    // If we couldn't find them as a field, try the subcollection approach
    final distortionsCollectionSnapshot = await _firestore
        .collection('treatments ')
        .doc('CBTtherapy')
        .collection('cognitiveDistortions')
        .get();
        
    print('Subcollection exists: ${distortionsCollectionSnapshot.metadata != null}');
    print('Found ${distortionsCollectionSnapshot.docs.length} documents in subcollection');
    
    if (distortionsCollectionSnapshot.docs.isNotEmpty) {
      final distortions = <String, bool>{};
      
      for (var doc in distortionsCollectionSnapshot.docs) {
        final data = doc.data();
        print('Document data: $data');
        
        if (data.containsKey('name') && data['name'] != null) {
          distortions[data['name'] as String] = false;
        }
      }
      
      if (distortions.isNotEmpty) {
        print('Successfully processed ${distortions.length} distortions from subcollection');
        return distortions;
      }
    }
    
    // If all attempts fail, use default distortions
    print('No distortions found in any locations, using default distortions');
    return _getDefaultCognitiveDistortions();
  } catch (e) {
    print('Error fetching cognitive distortions: $e');
    return _getDefaultCognitiveDistortions();
  }
}

// Separate method for default distortions to keep code clean
Map<String, bool> _getDefaultCognitiveDistortions() {
  return {
    'التفكير الثنائي ( شيء أو لا شيء)': false,
    'التعميم المفرط': false,
    'التصفية العقلية (التركيز على السلبيات)': false,
    'القفز إلى الاستنتاجات': false,
    'التهويل أو التقليل': false,
    'الاستدلال العاطفي': false,
    'العبارات الإلزامية (يجب، ينبغي)': false,
    'التسمية الخاطئة': false,
    'لوم الذات أو الآخرين': false,
  };
}
}

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
      ];
}

// Bloc
class CBTTherapyBloc extends Bloc<CBTTherapyEvent, CBTTherapyState> {
  final CBTRepository _repository;
  Timer? _timer;
  Timer? _instructionTimer;

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
  }

  // Add this method to your CBTTherapyBloc class
void debugCognitiveDistortions() {
  print('---------------- COGNITIVE DISTORTIONS DEBUG ----------------');
  print('Current cognitive distortions in state: ${state.cognitiveDistortions}');
  print('Number of distortions: ${state.cognitiveDistortions.length}');
  print('Are any distortions selected: ${state.cognitiveDistortions.containsValue(true)}');
  print('--------------------------------------------------------------');
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
  }

  void _onPauseExercise(
      PauseCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isPlaying: false,
    ));
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

  void _onCompleteExercise(
      CompleteCBTExerciseEvent event, Emitter<CBTTherapyState> emit) {
    _cancelTimers();
    emit(state.copyWith(
      isCompleting: true,
    ));
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
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}