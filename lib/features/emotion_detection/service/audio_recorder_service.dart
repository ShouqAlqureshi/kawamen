// File: emotion_detection/service/audio_recorder_service.dart

import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  /// Initializes the recorder and requests microphone permissions.
  Future<void> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }
    await _recorder.openRecorder();
  }

  /// Starts recording a 5-minute audio session and saves it as a .wav file.
  Future<File> recordFiveMinuteSession() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/kawamen_session.wav';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
    );

    // Wait for 5 minutes (300 seconds)
    await Future.delayed(const Duration(minutes: 5));

    await _recorder.stopRecorder();
    return File(filePath);
  }

  /// Stops recording manually if needed before 5 minutes.
  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
  }

  /// Checks if the audio file likely contains speech by checking file size.
  Future<bool> containsSpeech(String filePath) async {
    final file = File(filePath);
    final sizeInKB = await file.length() / 1024;
    return sizeInKB > 10; // >10KB suggests voice content present
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}
