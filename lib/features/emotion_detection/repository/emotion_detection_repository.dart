import 'dart:io';
import 'package:kawamen/core/services/api_service.dart';

/// Handles high-level emotion detection logic using APIService
class EmotionDetectionRepository {
  final APIService api = APIService();

  /// Uploads audio and processes the results, either directly or via polling
  Future<Map<String, dynamic>> uploadAndProcessAudio(File audioFile) async {
    final config = {
      "apiVersion": "4.7.0",
      "timeout": 10000,
      "modules": {
        "vad": {
          "minSegmentLength": 2.0,
          "maxSegmentLength": 30.0,
          "segmentStartDelay": 0.2,
          "segmentEndDelay": 0.4,
        },
        "expressionLarge": {
          "enableCategoricalExpressionLarge": true,
          "enableDimensionalExpressionLarge": false
        }
      }
    };

    final response = await api.uploadAudio(audioFile, config);

    if (response["result"] != null) {
      // Direct result case
      return response["result"];
    } else if (response["uploadId"] != null) {
      // Need to poll for results
      return await api.getResult(response["uploadId"]);
    } else {
      throw Exception("No result or uploadId received");
    }
  }

  /// Returns the dominant emotion from the analysis results
  Future<String> getDominantCategoricalEmotion(
      Map<String, dynamic> result) async {
    final segments = result["expressionLarge"];

    if (segments == null || segments.isEmpty) {
      throw Exception("No emotion segments found.");
    }

    Map<String, int> emotionCount = {};
    for (var segment in segments) {
      final categorical = segment["categorical"];
      if (categorical != null) {
        // Find the emotion with highest score in this segment
        String topEmotion = "";
        double maxScore = 0.0;

        categorical.forEach((emotion, score) {
          double currentScore = (score as num).toDouble();
          if (currentScore > maxScore) {
            maxScore = currentScore;
            topEmotion = emotion;
          }
        });

        if (topEmotion.isNotEmpty) {
          emotionCount[topEmotion] = (emotionCount[topEmotion] ?? 0) + 1;
        }
      }
    }

    if (emotionCount.isEmpty) {
      throw Exception("No valid categorical results found.");
    }

    // Find the most frequent emotion
    String dominantEmotion = "";
    int maxCount = 0;

    emotionCount.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantEmotion = emotion;
      }
    });

    return dominantEmotion;
  }

  /// Get anger, sadness and neutral scores from the results
  Future<Map<String, double>> getEmotionScores(
      Map<String, dynamic> result) async {
    final segments = result["expressionLarge"];

    if (segments == null || segments.isEmpty) {
      throw Exception("No emotion segments found.");
    }

    // Focus on specific emotions
    Map<String, double> emotionScores = {
      "angry": 0.0,
      "sad": 0.0,
      "neutral": 0.0
    };

    int segmentCount = 0;
    for (var segment in segments) {
      final categorical = segment["categorical"];
      if (categorical != null) {
        segmentCount++;
        for (var emotion in emotionScores.keys) {
          if (categorical[emotion] != null) {
            // Ensure we're converting to double
            emotionScores[emotion] = emotionScores[emotion]! +
                (categorical[emotion] as num).toDouble();
          }
        }
      }
    }

    // Calculate averages
    if (segmentCount > 0) {
      for (var emotion in emotionScores.keys) {
        emotionScores[emotion] = emotionScores[emotion]! / segmentCount;
      }
    }

    return emotionScores;
  }
}
