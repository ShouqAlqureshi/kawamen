import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;

  /// Initializes the recorder and requests microphone permissions.
  Future<void> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }
    await _recorder.openRecorder();
  }

  /// Starts recording to the specified path and marks as recording.
  Future<void> startRecording(String path) async {
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
    );
    isRecording = true;
  }

  /// Stops recording if active and resets isRecording flag.
  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
      isRecording = false;
    }
  }

  /// Starts recording a full 5-minute audio session and returns the file.
  Future<File> recordFiveMinuteSession() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/kawamen_session.wav';

    await startRecording(filePath);
    await Future.delayed(const Duration(minutes: 5));
    await stopRecording();

    return File(filePath);
  }

  /// Checks if the audio file likely contains speech (based on size).
  Future<bool> containsSpeech(String filePath) async {
    final file = File(filePath);
    final sizeInKB = await file.length() / 1024;
    return sizeInKB > 10; // >10KB suggests voice content
  }

  /// Closes the recorder when no longer needed.
  void dispose() {
    _recorder.closeRecorder();
  }
}
