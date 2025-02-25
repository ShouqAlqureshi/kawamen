part of 'emotion_bloc.dart';

sealed class EmotionState extends Equatable {
  const EmotionState();
  
  @override
  List<Object> get props => [];
}

final class EmotionInitial extends EmotionState {}

class EmotionProcessed extends EmotionState {
  final String emotion;
  final double intensity;

  EmotionProcessed(this.emotion, this.intensity);

  @override
  List<Object> get props => [emotion, intensity];
}
class EmotionDetectionPending extends EmotionState {
  final String emotion;
  final int count;

  EmotionDetectionPending(this.emotion, this.count);

  @override
  List<Object> get props => [emotion, count];
}
class EmotionError extends EmotionState {
  final String message;

  EmotionError(this.message);

  @override
  List<Object> get props => [message];
}
