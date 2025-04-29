import 'package:equatable/equatable.dart';

abstract class EmotionDetectionEvent extends Equatable {
  const EmotionDetectionEvent();

  @override
  List<Object?> get props => [];
}

class StartEmotionDetection extends EmotionDetectionEvent {}

class StopEmotionDetection extends EmotionDetectionEvent {}

// New event for checking and notifying emotions
class CheckAndNotifyEmotion extends EmotionDetectionEvent {
  final String emotionId;
  final String emotion;
  final double intensity;

  const CheckAndNotifyEmotion({
    required this.emotionId,
    required this.emotion,
    required this.intensity,
  });

  @override
  List<Object?> get props => [emotionId, emotion, intensity];
}
