import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Class for logging emotion events for debugging and analysis
class EmotionLogger {
  /// Format for timestamps in logs
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Whether to save logs to a file
  final bool _saveToFile;

  /// Whether to print logs to console
  final bool _printToConsole;

  /// Constructs an EmotionLogger
  EmotionLogger({
    bool saveToFile = true,
    bool printToConsole = true,
  })  : _saveToFile = saveToFile,
        _printToConsole = printToConsole;

  /// Log an emotion detection event
  Future<void> logEmotion(
      String emotion, double intensity, DateTime timestamp) async {
    final formattedTimestamp = _dateFormat.format(timestamp);
    final logMessage =
        '$formattedTimestamp - Detected $emotion (intensity: ${intensity.toStringAsFixed(2)})';

    if (_printToConsole) {
      developer.log(logMessage, name: 'EmotionLogger');
    }

    if (_saveToFile) {
      await _appendToLogFile(logMessage);
    }
  }

  /// Append a message to the log file
  Future<void> _appendToLogFile(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/emotion_logs.txt');

      // Create file if it doesn't exist
      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      // Append to file
      await file.writeAsString('$message\n', mode: FileMode.append);
    } catch (e) {
      developer.log('Error writing to log file: $e', name: 'EmotionLogger');
    }
  }

  /// Get the path to the log file
  Future<String?> getLogFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/emotion_logs.txt';
    } catch (e) {
      developer.log('Error getting log file path: $e', name: 'EmotionLogger');
      return null;
    }
  }

  /// Clear the log file
  Future<void> clearLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/emotion_logs.txt');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      developer.log('Error clearing log file: $e', name: 'EmotionLogger');
    }
  }
}
