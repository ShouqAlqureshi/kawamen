import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool _isInitialized = false;

  /// Initializes the recorder and requests microphone permissions.
  Future<void> init() async {
    if (_isInitialized) return;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }

    await _recorder.openRecorder();
    _isInitialized = true;
  }

  /// Starts recording a 5-second audio session and saves it as a .wav file.
  Future<File> recordThirtySecondSession() async {
    await init(); // Ensure the recorder is initialized

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/kawamen_session.wav';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV, // PCM WAV format
      sampleRate: 16000, // Required by Audeering
      numChannels: 1, // Mono channel is required
    );

    isRecording = true;

    // Record for 5 seconds (you can increase to 30 if needed)
    await Future.delayed(const Duration(seconds: 5));

    await _recorder.stopRecorder();
    isRecording = false;

    return File(filePath);
  }

  /// Stops recording manually if needed before timeout.
  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
      isRecording = false;
    }
  }

  /// Checks if the audio file likely contains speech by checking file size.
  Future<bool> containsSpeech(String filePath) async {
    final file = File(filePath);
    final sizeInKB = await file.length() / 1024;
    return sizeInKB > 10; // Rough threshold for speech presence
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}
