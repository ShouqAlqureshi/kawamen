import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc/emotion_detection_bloc.dart';
import '../Bloc/emotion_detection_event.dart';
import '../Bloc/emotion_detection_state.dart';
import 'package:kawamen/core/utils/permission_handler.dart';

class EmotionTestScreen extends StatefulWidget {
  const EmotionTestScreen({Key? key}) : super(key: key);

  @override
  State<EmotionTestScreen> createState() => _EmotionTestScreenState();
}

class _EmotionTestScreenState extends State<EmotionTestScreen> {
  bool micEnabled = false;
  bool detectionEnabled = false;
  String resultMessage = '';
  bool isRecording = false;
  Timer? micStatusTimer;

  @override
  void initState() {
    super.initState();
    _startMicStatusMonitor();
  }

  @override
  void dispose() {
    micStatusTimer?.cancel();
    super.dispose();
  }

  void _startMicStatusMonitor() {
    final bloc = context.read<EmotionDetectionBloc>();
    micStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentStatus = bloc.recorderService.isRecording;
      if (currentStatus != isRecording) {
        setState(() => isRecording = currentStatus);
      }
    });
  }

  Future<void> _handleMicAccess() async {
    final granted = await AppPermissionHandler.requestMicPermission();

    if (granted) {
      setState(() => micEnabled = true);
    } else {
      final permanentlyDenied =
          await AppPermissionHandler.isMicPermanentlyDenied();
      if (permanentlyDenied) {
        await AppPermissionHandler.openSettings();
      }
    }
  }

  void _handleDetectionToggle(bool value) {
    final bloc = context.read<EmotionDetectionBloc>();
    if (!micEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enable microphone access first.")),
      );
      return;
    }
    setState(() => detectionEnabled = value);
    if (value) {
      bloc.add(StartEmotionDetection());
    } else {
      bloc.add(StopEmotionDetection());
      setState(() => resultMessage = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final micStatusText =
        isRecording ? "🎙️ Mic is recording" : "🔇 Mic is not recording";

    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Detection Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              micStatusText,
              style: TextStyle(
                fontSize: 16,
                color: isRecording ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: micEnabled ? null : _handleMicAccess,
              icon: const Icon(Icons.mic),
              label: const Text("Enable Microphone"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: (!micEnabled || detectionEnabled)
                  ? null
                  : () => _handleDetectionToggle(true),
              icon: const Icon(Icons.graphic_eq),
              label: const Text("Start Emotion Detection"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  detectionEnabled ? () => _handleDetectionToggle(false) : null,
              child: const Text("Stop Detection"),
            ),
            const SizedBox(height: 24),
            BlocConsumer<EmotionDetectionBloc, EmotionDetectionState>(
              listener: (context, state) {
                if (state is DetectionSuccess) {
                  final emotion =
                      state.categoricalResult['dominant'] ?? 'Unknown';
                  setState(() => resultMessage = 'Detected emotion: $emotion');
                } else if (state is DetectionSkippedNoSpeech) {
                  setState(() => resultMessage = 'No speech detected.');
                } else if (state is DetectionFailure) {
                  setState(() => resultMessage = 'Error: ${state.error}');
                }
              },
              builder: (context, state) {
                if (state is DetectionInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Text(
                  resultMessage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
