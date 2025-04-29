import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kawamen/core/services/Notification_service.dart';
import 'package:kawamen/features/emotion_detection/models/emotion_model.dart';
import 'package:kawamen/features/Treatment/repository/emotion_histroy.dart';
import 'package:kawamen/features/Treatment/repository/emotion_logger.dart';
import 'emotion_detection_event.dart';
import 'emotion_detection_state.dart';
import '../repository/emotion_detection_repository.dart';
import '../service/audio_recorder_service.dart';

class EmotionDetectionBloc
    extends Bloc<EmotionDetectionEvent, EmotionDetectionState> {
  final EmotionDetectionRepository repository;
  final AudioRecorderService recorderService;
  final EmotionHistoryQueue historyQueue = EmotionHistoryQueue();
  final EmotionLogger logger = EmotionLogger();
  final NotificationService notificationService = NotificationService();
  Timer? _autoStopTimer;

  EmotionDetectionBloc({
    required this.repository,
    required this.recorderService,
  }) : super(DetectionInitial()) {
    on<StartEmotionDetection>(_onStartDetection);
    on<StopEmotionDetection>(_onStopDetection);
    on<CheckAndNotifyEmotion>(_onCheckAndNotifyEmotion);

    // Initialize notification service
    notificationService.initialize();
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
        final emotionId =
            await _saveEmotionToFirebase(dominantEmotion, emotionScores);

        // After saving to Firebase, trigger the check and notify process
        if (emotionId != null) {
          add(CheckAndNotifyEmotion(
              emotionId: emotionId,
              emotion: dominantEmotion,
              intensity: (emotionScores["angry"] ?? 0.0) +
                  (emotionScores["sad"] ?? 0.0)));
        }
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

  // Update this method in your EmotionDetectionBloc class

  Future<String?> _saveEmotionToFirebase(
      String emotion, Map<String, double> scores) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      if (emotion != "angry" && emotion != "sad" && emotion != "neutral") {
        print("Ignoring emotion: $emotion as it's not in our target list");
        return null; // Don't save emotions we don't care about
      }

      final emotionId = DateTime.now().millisecondsSinceEpoch;

      // Create emotion model
      final model = EmotionModel(
        emotionId: emotionId.toString(),
        emotion: emotion,
        timestamp: DateTime.now(), // Keep this for the model
        sessionId: null,
      );

      // Convert to map
      final data = model.toMap();

      // Add scores and intensity
      data['emotionScores'] = scores;
      data['intensity'] = (scores["angry"] ?? 0.0) + (scores["sad"] ?? 0.0);
      data['treatmentStatus'] = 'pending';

      // Replace the timestamp with a Firestore Timestamp
      data['timestamp'] = FieldValue.serverTimestamp(); // Use server timestamp

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData')
          .doc(emotionId.toString())
          .set(data);

      print("Saved emotion data to Firebase");
      return emotionId.toString();
    } catch (e) {
      print("Error saving to Firebase: $e");
      return null;
    }
  }

  // After saving to Firebase, check if we should notify based on history queue
  Future<void> _onCheckAndNotifyEmotion(
      CheckAndNotifyEmotion event, Emitter<EmotionDetectionState> emit) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if this emotion is already in the history queue
      int sameEmotionCount =
          historyQueue.countSameEmotionInHistory(event.emotion);

      // Add to history queue for tracking
      Map<String, dynamic> emotionData = {
        'emotion': event.emotion,
        'timestamp': DateTime.now(),
        'emotionId': event.emotionId,
        'intensity': event.intensity,
      };

      // Log the emotion for tracking
      logger.logEmotion(event.emotion, event.intensity, DateTime.now());

      // If it appeared 3 times or first time, process it (send notification)
      if (sameEmotionCount >= 2 || sameEmotionCount == 0) {
        // Reset tracking if we reached threshold
        if (sameEmotionCount >= 2) {
          historyQueue.queue
              .removeWhere((item) => item['emotion'] == event.emotion);
        }

        // Add to cached queue
        historyQueue.addEmotion(emotionData);

        // Update treatment status to 'notified'
        await _updateTreatmentStatus(event.emotionId, 'notified');

        // Send notification through your teammate's notification service
        notificationService.bloc.add(ShowEmotionNotification(
          event.emotion,
          event.intensity,
          event.emotionId,
        ));

        print(
            "Notification sent for emotion: ${event.emotion} (ID: ${event.emotionId})");
        emit(EmotionNotified(event.emotion, event.intensity, event.emotionId));
      } else {
        // Just add to history queue if it's redundant (no notification sent)
        historyQueue.addEmotion(emotionData);

        // Update treatment status to 'skipped' (duplicate)
        await _updateTreatmentStatus(event.emotionId, 'skipped');

        print(
            "Notification skipped for emotion: ${event.emotion} (duplicate, count: ${sameEmotionCount + 1})");
        emit(EmotionSkipped(event.emotion, sameEmotionCount + 1));
      }
    } catch (e) {
      print("Error checking and notifying emotion: $e");
      emit(DetectionFailure(e.toString()));
    }
  }

  // Update treatment status in Firestore
  Future<void> _updateTreatmentStatus(String emotionId, String status) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update in your subcollection structure
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData')
          .doc(emotionId)
          .update({'treatmentStatus': status});

      print("Updated treatment status to: $status for emotion ID: $emotionId");
    } catch (e) {
      print("Error updating treatment status: $e");
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
