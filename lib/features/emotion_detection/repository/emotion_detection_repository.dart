// File: emotion_detection/repository/emotion_detection_repository.dart

import 'dart:io';
import 'package:kawamen/core/services/api_service.dart';

/// Handles high-level emotion detection logic using APIService
class EmotionDetectionRepository {
  final APIService api = APIService();

  /// Uploads audio using shared API service and returns uploadId
  Future<String> uploadAudio(File audioFile) async {
    final config = {
      "apiVersion": "4.7.0",
      "timeout": 10000,
      "modules": {
        "vad": {
          "minSegmentLength": 2.0,
          "maxSegmentLength": 0.0,
          "segmentStartDelay": 0.2,
          "segmentEndDelay": 0.4,
        },
        "expression_large": {
          "enableCategoricalExpressionLarge": true,
          "enableDimensionalExpressionLarge": false
        }
      }
    };

    return await api.uploadAudio(audioFile, config);
  }

  /// Processes emotion segments and returns the dominant categorical emotion
  Future<String> fetchDominantCategoricalEmotion(String uploadId) async {
    final result = await api.getResult(uploadId);
    final segments = result["expressionLarge"];

    if (segments == null || segments.isEmpty) {
      throw Exception("No emotion segments found.");
    }

    Map<String, int> emotionCount = {};
    for (var segment in segments) {
      final categorical = segment["categorical"];
      if (categorical != null) {
        final topEmotion =
            categorical.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        emotionCount[topEmotion] = (emotionCount[topEmotion] ?? 0) + 1;
      }
    }

    if (emotionCount.isEmpty) {
      throw Exception("No valid categorical results found.");
    }

    return emotionCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
