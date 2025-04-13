import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawamen/features/Treatment/screen/process_responses.dart';
import 'package:path_provider/path_provider.dart'; 
import 'package:kawamen/core/services/api_service.dart';
import 'package:kawamen/features/Treatment/bloc/emotion_bloc.dart';

class UploadFile extends StatefulWidget {
  const UploadFile({super.key});

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile> {
  File? audio;
  String statusMessage = "";
  bool isLoading = false;
  late EmotionBloc emotionBloc;

  @override
  void initState() {
    super.initState();
    emotionBloc = setupEmotionDetection();
    // Load audio file when the widget initializes
    loadAudioFile();
  }

  @override
  void dispose() {
    emotionBloc.close(); // Don't forget to close the bloc
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: isLoading || audio == null 
              ? null 
              : () => uploadAudio(),
            child: const Text("Start emotion detection")
          ),
          const SizedBox(height: 10),
          Text(statusMessage)
        ],
      ),
    );
  }
//checks constraints 
  Future<void> uploadAudio() async {
    if (audio == null) {
      setState(() {
        statusMessage = "Audio file not loaded yet";
      });
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = "Checking file size...";
    });

    try {
      // Check file size
      int fileSize = await audio!.length();
      
      if (fileSize > 350 * 1024 * 1024) {
        setState(() {
          statusMessage = "File exceeds 350MB limit";
          isLoading = false;
        });
        return;
      }

      setState(() {
        statusMessage = "Uploading audio...";
      });

      // Now upload and send the request the file
      await APIService().uploadAndProcessAudio(audio!, emotionBloc);
      
    } catch (e) {
      setState(() {
        statusMessage = "Error: $e";
        isLoading = false;
      });
    }
  }
//convert the audio
  Future<void> loadAudioFile() async {
    setState(() {
      isLoading = true;
      statusMessage = "Loading audio file...";
    });

    try {
      // Get the temporary directory to store the asset
      // final directory = await getTemporaryDirectory();
      const filePath = 'lib/core/assets/audio/sample_audio.mp3';//testing file 

      // Get the audio file from assets
      final byteData = await rootBundle.load('lib/core/assets/audio/sample_audio.mp3');
      
      // Write the byte data to the file system
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      
      setState(() {
        audio = file;
        statusMessage = "Audio file loaded: sample_audio.mp3";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error loading audio file: $e";
        isLoading = false;
      });
    }
  }
}