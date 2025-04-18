// File: emotion_detection/model/emotion_model.dart

class EmotionModel {
  final String emotionId; // unique ID for this emotion record
  final String emotion; // dominant emotion detected (e.g., "sad", "happy")
  final DateTime timestamp; // when emotion was detected
  final String? sessionId; // optional: link to treatment or session grouping

  EmotionModel({
    required this.emotionId,
    required this.emotion,
    required this.timestamp,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'emotionId': emotionId,
      'emotion': emotion,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
    };
  }

  factory EmotionModel.fromMap(Map<String, dynamic> map) {
    return EmotionModel(
      emotionId: map['emotionId'] ?? '',
      emotion: map['emotion'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      sessionId: map['sessionId'],
    );
  }
}
