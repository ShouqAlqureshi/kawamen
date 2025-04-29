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

// New states for notification flow
class EmotionNotified extends EmotionDetectionState {
  final String emotion;
  final double intensity;
  final String emotionId;

  const EmotionNotified(this.emotion, this.intensity, this.emotionId);

  @override
  List<Object?> get props => [emotion, intensity, emotionId];
}

class EmotionSkipped extends EmotionDetectionState {
  final String emotion;
  final int count;

  const EmotionSkipped(this.emotion, this.count);

  @override
  List<Object?> get props => [emotion, count];
}
