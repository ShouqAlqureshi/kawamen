import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kawamen/features/emotion_detection/models/emotion_model.dart';
import 'emotion_detection_event.dart';
import 'emotion_detection_state.dart';
import '../repository/emotion_detection_repository.dart';
import '../service/audio_recorder_service.dart';

class EmotionDetectionBloc
    extends Bloc<EmotionDetectionEvent, EmotionDetectionState> {
  final EmotionDetectionRepository repository;
  final AudioRecorderService recorderService;

  EmotionDetectionBloc({
    required this.repository,
    required this.recorderService,
  }) : super(DetectionInitial()) {
    on<StartEmotionDetection>(_onStartDetection);
    on<StopEmotionDetection>(_onStopDetection);
  }

  Future<void> _onStartDetection(
    StartEmotionDetection event,
    Emitter<EmotionDetectionState> emit,
  ) async {
    emit(DetectionInProgress());

    try {
      await recorderService.init();
      await recorderService.startRecording();

      // Record for 30 seconds
      await Future.delayed(Duration(seconds: 30));

      final path = await recorderService.stopRecording();
      if (path == null) throw Exception("Recording failed");

      final file = File(path);
      final fileSize = await file.length();

      print("🎤 File path: $path");
      print('📦 Recorded file size: $fileSize bytes');

      if (fileSize <= 44) {
        emit(DetectionSkippedNoSpeech());
        return;
      }

      // Get the analysis results
      final result = await repository.uploadAndProcessAudio(file);

      // Get the dominant emotion
      final dominantEmotion =
          await repository.getDominantCategoricalEmotion(result);

      // Get emotion scores
      final emotionScores = await repository.getEmotionScores(result);
      print(
          "ABOUT TO SAVE TO FIREBASE - dominantEmotion: $dominantEmotion, scores: $emotionScores");
      // Save to Firebase
      await _saveEmotionToFirebase(dominantEmotion, emotionScores);

      // Create state data with explicit typing
      final Map<String, dynamic> stateData = {
        "dominant": dominantEmotion,
      };

      // Add emotion scores with explicit double conversion
      stateData["angry"] = emotionScores["angry"]?.toDouble() ?? 0.0;
      stateData["sad"] = emotionScores["sad"]?.toDouble() ?? 0.0;
      stateData["neutral"] = emotionScores["neutral"]?.toDouble() ?? 0.0;

      // Emit success state with results
      emit(DetectionSuccess(stateData));

      print('🎯 Final emotion: $dominantEmotion');
      print('😠 Anger score: ${emotionScores["angry"]}');
      print('😢 Sadness score: ${emotionScores["sad"]}');
      print('😐 Neutral score: ${emotionScores["neutral"]}');
    } catch (e) {
      print("ERROR IN START DETECTION: $e");
      print("ERROR STACK TRACE: ${StackTrace.current}");
      emit(DetectionFailure(e.toString()));
    }
  }

//
  void _onStopDetection(
      StopEmotionDetection event, Emitter<EmotionDetectionState> emit) {
    recorderService.stopRecording();
    emit(DetectionStopped());
  }

// Update the _saveEmotionToFirebase method with more detailed logging
  Future<void> _saveEmotionToFirebase(
      String dominantEmotion, Map<String, double> scores) async {
    print("SAVE TO FIREBASE STARTED");
    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print("USER ID: $userId");

      if (userId == null) {
        print("Cannot save to Firebase: No user logged in");
        return;
      }

      // Create a new document ID for the emotion record
      print("Creating Firestore document reference");
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotionalData')
          .doc();

      print("Document ID: ${docRef.id}");

      // Create EmotionModel
      print("Creating emotion model");
      final emotionModel = EmotionModel(
        emotionId: docRef.id,
        emotion: dominantEmotion,
        timestamp: DateTime.now(),
        sessionId: null,
      );
      // Convert to map and add additional fields
      final data = emotionModel.toMap();

      print("Emotion data map: $data");

      // Add emotion scores
      data['emotionScores'] = {
        'angry': scores["angry"] ?? 0.0,
        'sad': scores["sad"] ?? 0.0,
        'neutral': scores["neutral"] ?? 0.0
      };

      // Add intensity
      data['intensity'] = (scores["angry"] ?? 0.0) + (scores["sad"] ?? 0.0);

      print("Final data to save: $data");

      // Save to Firestore - use try/catch specifically for this operation
      try {
        print("Attempting to save to Firestore...");
        await docRef.set(data);
        print("SUCCESSFULLY SAVED TO FIREBASE!");
      } catch (firestoreError) {
        print("FIRESTORE SET OPERATION FAILED: $firestoreError");
        print("FIRESTORE ERROR STACK TRACE: ${StackTrace.current}");
      }
    } catch (e) {
      print("ERROR SAVING TO FIREBASE: $e");
      print("SAVE ERROR STACK TRACE: ${StackTrace.current}");
    }
  }
}
