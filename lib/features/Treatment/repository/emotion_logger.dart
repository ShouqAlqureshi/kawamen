//for Debugging and Monitoring it is saved locally 
import 'dart:developer';

class EmotionLogger {
  final List<Map<String, dynamic>> _logs = [];
  final int maxLogSize;
  
  EmotionLogger({this.maxLogSize = 100});
  
  void logEmotion(String emotion, double intensity, DateTime timestamp) {
    if (_logs.length >= maxLogSize) {
      _logs.removeAt(0); // Remove oldest log when max size reached
    }
    
    _logs.add({
      'emotion': emotion,
      'intensity': intensity,
      'timestamp': timestamp,
      'loggedAt': DateTime.now(),
    });
    
    // Print to console for debugging
    log('Logged emotion: $emotion (${intensity.toStringAsFixed(4)}) at ${timestamp.toIso8601String()}');
    print('Logged emotion: $emotion (${intensity.toStringAsFixed(4)}) at ${timestamp.toIso8601String()}');
  }
  
  List<Map<String, dynamic>> getLogs() {
    return List.from(_logs);
  }
  
  List<Map<String, dynamic>> getLogsByEmotion(String emotion) {
    return _logs.where((log) => log['emotion'] == emotion).toList();
  }
  
  // for future work can be saved in firestore
  Future<void> exportLogs(String path) async {

  }
}