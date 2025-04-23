import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/permission_handler.dart';
import '../Bloc/emotion_detection_bloc.dart';
import '../Bloc/emotion_detection_event.dart';
import '../Bloc/emotion_detection_state.dart';

class EmotionTestScreen extends StatefulWidget {
  const EmotionTestScreen({Key? key}) : super(key: key);

  @override
  State<EmotionTestScreen> createState() => _EmotionTestScreenState();
}

class _EmotionTestScreenState extends State<EmotionTestScreen> {
  bool micEnabled = false;
  bool detectionEnabled = false;
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
    context.read<EmotionDetectionBloc>().recorderService.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone access granted.")),
      );
    } else {
      final permanentlyDenied =
          await AppPermissionHandler.isMicPermanentlyDenied();
      if (permanentlyDenied) {
        await AppPermissionHandler.openSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required.")),
        );
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
            BlocBuilder<EmotionDetectionBloc, EmotionDetectionState>(
              builder: (context, state) {
                if (state is DetectionInProgress) {
                  return const Center(child: LoadingScreen());
                }

                if (state is DetectionSuccess) {
                  final result = state.categoricalResult;
                  final topEmotion = result.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Detected Emotion:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        topEmotion.toUpperCase(),
                        style:
                            const TextStyle(fontSize: 32, color: Colors.teal),
                      ),
                    ],
                  );
                }

                if (state is DetectionSkippedNoSpeech) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('No speech detected. Please try again.'),
                  );
                }

                if (state is DetectionFailure) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${state.error}'),
                  );
                }

                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Press start to begin emotion detection.'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
