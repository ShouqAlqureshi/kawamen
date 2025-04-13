// File: emotion_detection/Bloc/emotion_detection_state.dart

import 'package:equatable/equatable.dart';

abstract class EmotionDetectionState extends Equatable {
  const EmotionDetectionState();

  @override
  List<Object?> get props => [];
}

class DetectionInitial extends EmotionDetectionState {}

class DetectionInProgress extends EmotionDetectionState {}

class DetectionSuccess extends EmotionDetectionState {
  final Map<String, dynamic> categoricalResult;

  const DetectionSuccess(this.categoricalResult);

  @override
  List<Object?> get props => [categoricalResult];
}

class DetectionSkippedNoSpeech extends EmotionDetectionState {}

class DetectionFailure extends EmotionDetectionState {
  final String error;

  const DetectionFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class DetectionStopped extends EmotionDetectionState {}
