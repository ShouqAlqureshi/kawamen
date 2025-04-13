// File: emotion_detection/Bloc/emotion_detection_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
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
      StartEmotionDetection event, Emitter<EmotionDetectionState> emit) async {
    emit(DetectionInProgress());
    try {
      final file = await recorderService.recordFiveMinuteSession();
      final isSpeech = await recorderService.containsSpeech(file.path);
      if (!isSpeech) {
        emit(DetectionSkippedNoSpeech());
        return;
      }
      final uploadId = await repository.uploadAudio(file);
      final dominantEmotion =
          await repository.fetchDominantCategoricalEmotion(uploadId);
      emit(DetectionSuccess({"dominant": dominantEmotion}));
    } catch (e) {
      emit(DetectionFailure(e.toString()));
    }
  }

  void _onStopDetection(
      StopEmotionDetection event, Emitter<EmotionDetectionState> emit) {
    recorderService.stopRecording();
    emit(DetectionStopped());
  }
}
