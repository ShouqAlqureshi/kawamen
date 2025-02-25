// Emotion history queue for finding redundent emotions to avoid redundunt emotion suggestion
class EmotionHistoryQueue {
  final List<Map<String, dynamic>> queue = [];
  final int maxQueueSize = 10;

  void addEmotion(Map<String, dynamic> emotion) {
    if (queue.length >= maxQueueSize) {
      queue.removeAt(0);
    }
    queue.add(emotion);
  }

  int countSameEmotionInHistory(String emotion) {
    return queue.where((item) => item['emotion'] == emotion).length;
  }
}