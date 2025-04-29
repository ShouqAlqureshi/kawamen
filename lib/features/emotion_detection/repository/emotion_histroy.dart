import 'dart:collection';

/// Class for tracking emotion history to prevent duplicate treatments
class EmotionHistoryQueue {
  /// Queue to store recent emotions detected
  final List<Map<String, dynamic>> queue = [];

  /// Maximum number of emotions to track in history
  final int maxSize = 10;

  /// Maximum age of emotions to keep in queue (in minutes)
  final int maxAgeMinutes = 60; // 1 hour

  /// Add an emotion to the history queue
  void addEmotion(Map<String, dynamic> emotionData) {
    // Prune old emotions first
    _pruneOldEmotions();

    // Add to queue
    queue.add(emotionData);

    // Trim if exceeding max size
    if (queue.length > maxSize) {
      queue.removeAt(0);
    }
  }

  /// Count how many times the same emotion appears in the history
  int countSameEmotionInHistory(String emotion) {
    // Prune old emotions first to ensure accurate count
    _pruneOldEmotions();

    // Count occurrences of this emotion
    return queue.where((item) => item['emotion'] == emotion).length;
  }

  /// Remove emotions that are older than maxAgeMinutes
  void _pruneOldEmotions() {
    final now = DateTime.now();
    queue.removeWhere((item) {
      final timestamp = item['timestamp'] as DateTime;
      final difference = now.difference(timestamp).inMinutes;
      return difference > maxAgeMinutes;
    });
  }

  /// Clear the entire queue
  void clear() {
    queue.clear();
  }
}
