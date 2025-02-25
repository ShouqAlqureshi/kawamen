part of 'emotion_bloc.dart';

sealed class EmotionEvent extends Equatable {
  const EmotionEvent();

  @override
  List<Object> get props => [];
}
class EmotionDetected extends EmotionEvent {
  final Map<String, dynamic> emotionData;

  EmotionDetected(this.emotionData);

  @override
  List<Object> get props => [emotionData];
}