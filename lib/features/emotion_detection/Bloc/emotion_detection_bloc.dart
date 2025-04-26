import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kawamen/features/Treatment/bloc/emotion_bloc.dart';
import 'package:kawamen/features/emotion_detection/models/emotion_model.dart';
import 'emotion_detection_event.dart';
import 'emotion_detection_state.dart';
import '../repository/emotion_detection_repository.dart';
import '../service/audio_recorder_service.dart';

class EmotionDetectionBloc
    extends Bloc<EmotionDetectionEvent, EmotionDetectionState> {
  final EmotionDetectionRepository repository;
  final AudioRecorderService recorderService;
  Timer? _autoStopTimer;

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
    print("START DETECTION EVENT RECEIVED");

    if (state is DetectionInProgress) {
      print("Detection already in progress, ignoring start event");
      return;
    }

    emit(DetectionInProgress());

    // Set a one-time detection with auto-stop timer
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(Duration(seconds: 15), () {
      print("AUTO-STOPPING DETECTION AFTER 15 SECONDS");
      add(StopEmotionDetection());
      print("==================================================");
      print("============ DETECTION AUTO-STOPPED ==============");
      print("==================================================");
    });

    try {
      // Single detection cycle, no continuation
      await recorderService.init();
      await recorderService.startRecording();
      await Future.delayed(Duration(seconds: 10));

      // Check if stopped during recording
      if (state is DetectionStopped) {
        print("Detection stopped during recording");
        return;
      }

      final path = await recorderService.stopRecording();
      if (path == null) {
        emit(DetectionFailure("Recording failed"));
        return;
      }

      // Check if stopped after recording
      if (state is DetectionStopped) {
        print("Detection stopped after recording");
        return;
      }

      final file = File(path);
      final fileSize = await file.length();

      if (fileSize <= 44) {
        emit(DetectionSkippedNoSpeech());
        return;
      }

      // Process only if not stopped
      if (state is DetectionStopped) return;

      final result = await repository.uploadAndProcessAudio(file);
      final dominantEmotion =
          await repository.getDominantCategoricalEmotion(result);
      final emotionScores = await repository.getEmotionScores(result);

      // Only save if the emotion is one we want to track
      if (dominantEmotion == "angry" ||
          dominantEmotion == "sad" ||
          dominantEmotion == "neutral") {
        await _saveEmotionToFirebase(dominantEmotion, emotionScores);
      }

      // Success state with no continuation
      emit(DetectionSuccess({
        "dominant": dominantEmotion,
        "angry": emotionScores["angry"],
        "sad": emotionScores["sad"],
        "neutral": emotionScores["neutral"],
      }));

      // Always auto-stop after one successful detection
      add(StopEmotionDetection());
    } catch (e) {
      print("ERROR IN EMOTION DETECTION: $e");
      emit(DetectionFailure(e.toString()));
      // Always stop on error
      add(StopEmotionDetection());
    }
  }

  Future<void> _saveEmotionToFirebase(
      String emotion, Map<String, double> scores) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (emotion != "angry" && emotion != "sad" && emotion != "neutral") {
        print("Ignoring emotion: $emotion as it's not in our target list");
        return; // Don't save emotions we don't care about
      }

      final emotionId = DateTime.now().millisecondsSinceEpoch;

      // Create emotion model
      final model = EmotionModel(
        emotionId: emotionId.toString(),
        emotion: emotion,
        timestamp: DateTime.now(),
        sessionId: null,
      );

      // Convert to map
      final data = model.toMap();

      // Add scores and intensity
      data['emotionScores'] = scores;
      data['intensity'] = (scores["angry"] ?? 0.0) + (scores["sad"] ?? 0.0);
      data['treatmentStatus'] = 'pending';

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData')
          .doc(emotionId.toString())
          .set(data);

      print("Saved emotion data to Firebase");
    } catch (e) {
      print("Error saving to Firebase: $e");
    }
  }

  void _onStopDetection(
      StopEmotionDetection event, Emitter<EmotionDetectionState> emit) {
    print("Stopping emotion detection");
    // Cancel auto-stop timer
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    // Stop recording
    recorderService.stopRecording();
    emit(DetectionStopped());
  }

  @override
  Future<void> close() {
    _autoStopTimer?.cancel();
    return super.close();
  }
}
