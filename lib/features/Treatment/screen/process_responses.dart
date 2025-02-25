
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kawamen/features/Treatment/bloc/emotion_bloc.dart';


Future<void> processApiResponse(http.Response response, EmotionBloc emotionBloc) async {
  if (response.statusCode == 200) {
    final Map<String, dynamic> apiResponse = jsonDecode(response.body);
    emotionBloc.add(EmotionDetected(apiResponse));
  } else {
    print('Error: HTTP status ${response.statusCode}');
  }
}
void setupEmotionDetection() {
  final emotionBloc = EmotionBloc();
  
  // Listen to state changes
  emotionBloc.stream.listen((state) {
    if (state is EmotionProcessed) {
      print('Processed emotion: ${state.emotion} with intensity: ${state.intensity}');
    } else if (state is EmotionError) {
      print('Error: ${state.message}');
    } else if (state is EmotionDetectionPending) {
      print('Emotion ${state.emotion} detected ${state.count} times');
    }
  });
}