import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  String? _recordingPath;

  Future<void> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) await init();

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    _recordingPath = filePath;

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );
  }

  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized) return null;

    await _recorder.stopRecorder();
    return _recordingPath;
  }

  void dispose() {
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }
  }

  bool get isRecording => _recorder.isRecording;
}
