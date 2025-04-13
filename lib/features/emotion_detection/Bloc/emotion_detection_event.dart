// File: emotion_detection/Bloc/emotion_detection_event.dart

import 'package:equatable/equatable.dart';

abstract class EmotionDetectionEvent extends Equatable {
  const EmotionDetectionEvent();

  @override
  List<Object?> get props => [];
}

class StartEmotionDetection extends EmotionDetectionEvent {}

class StopEmotionDetection extends EmotionDetectionEvent {}
