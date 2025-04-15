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
    StartEmotionDetection event,
    Emitter<EmotionDetectionState> emit,
  ) async {
    emit(DetectionInProgress());

    try {
      await recorderService.init();

      final file = await recorderService.recordThirtySecondSession();
      print("🎤 File path: ${file.path}");

      final uploadId = await repository.uploadAudio(file);
      print("🎯 Upload ID: $uploadId");

      final dominantEmotion =
          await repository.fetchDominantCategoricalEmotion(uploadId);

      emit(DetectionSuccess({"dominant": dominantEmotion}));
      print('🎯 Final emotion: $dominantEmotion');
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
