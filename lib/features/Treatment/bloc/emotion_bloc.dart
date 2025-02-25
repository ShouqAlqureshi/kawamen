import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawamen/features/Treatment/repository/emotion_histroy.dart';
part 'emotion_event.dart';
part 'emotion_state.dart';

class EmotionBloc extends Bloc<EmotionEvent, EmotionState> {
  final EmotionHistoryQueue historyQueue = EmotionHistoryQueue();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EmotionBloc() : super(EmotionInitial()) {
    on<EmotionDetected>(_handleEmotionDetected);
  }

  Future<void> _handleEmotionDetected(
      EmotionDetected event, Emitter<EmotionState> emit) async {
    try {
      // Extract the emotion data from the API response structure
      // Based on the JSON in the screenshot
      final result = event.emotionData['result'];
      if (result == null) {
        emit(EmotionError('Missing result in emotion data'));
        return;
      }

      final vad = result['vad'];
      final expressions = result['expression'];

      if (expressions == null || expressions is! List || expressions.isEmpty) {
        emit(EmotionError('Missing or invalid expressions in emotion data'));
        return;
      }

      // Get the first expression item which contains categorical emotions
      final expressionData = expressions[0];
      if (expressionData == null || expressionData is! Map) {
        emit(EmotionError('Invalid expression data format'));
        return;
      }

      final categorical = expressionData['categorical'];
      if (categorical == null || categorical is! Map) {
        emit(EmotionError('Missing categorical data'));
        return;
      }

      // Find the emotion with the highest value
      String dominantEmotion = '';
      double highestValue = 0;

      (categorical as Map).forEach((emotion, value) {
        value as num;
        if (value is num && value > highestValue) {
          highestValue = value.toDouble();
          dominantEmotion = emotion.toString();
        }
      });

      if (dominantEmotion.isEmpty) {
        emit(EmotionError('No valid emotion detected'));
        return;
      }

      // Check if this emotion is already in the history queue
      int sameEmotionCount =
          historyQueue.countSameEmotionInHistory(dominantEmotion);

      // If it appeared 3 times or first time, process it
      if (sameEmotionCount >= 2 || sameEmotionCount == 0) {
        //create a timestamp so if it exceeds certin time in thhe queue not being processed it is removed
        String emotionId = DateTime.now().millisecondsSinceEpoch.toString();
        DateTime timestamp = DateTime.now();

        // Add to cached queue
        Map<String, dynamic> emotionData = {
          'emotion': dominantEmotion,
          'timestamp': timestamp,
          'emotionId': emotionId,
          'intensity': highestValue,
        };
        //start a clean track
        if (sameEmotionCount >= 2) {
          historyQueue.queue
              .removeWhere((item) => item['emotion'] == dominantEmotion);
        }

        historyQueue.addEmotion(emotionData);

        await _trackEmotionInFirestore(
            dominantEmotion, emotionId, highestValue);

        emit(EmotionProcessed(dominantEmotion, highestValue));
      } else {
        // Just add to history queue if it is redundunt
        historyQueue.addEmotion({
          'emotion': dominantEmotion,
          'timestamp': DateTime.now(),
          'intensity': highestValue,
        });
        // the count to know the urgency of the treatment so we do not ignore the resulted detection
        emit(EmotionDetectionPending(dominantEmotion, sameEmotionCount + 1));
      }
    } catch (e) {
      emit(EmotionError('Error processing emotion: ${e.toString()}'));
    }
  }

  Future<void> _trackEmotionInFirestore(
      String emotion, String emotionId, double intensity) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final userEmotionsRef1 = _firestore
          .collection('users')
          .doc(user.uid)
          .get() as Map<String, dynamic>;

      final userEmotionsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData');
      final emotionDocRef1 = userEmotionsRef1["emotionalData"];
      

      // Get the current document to check if it exists and to update the emotion tracker


      if (emotionDocRef1.exists) {
        // Update existing emotion entry
        // final int currentTracker = data['emotionTracker'] ?? 0;

        await emotionDocRef1.update({
          'date': FieldValue.serverTimestamp(),
          'emotionTracker': FieldValue.increment(1),
          'emotionId': emotionId,
          'intensity': intensity
        });
      } else {
        // Create new emotion entry
        await emotionDocRef1.set({
          'date': FieldValue.serverTimestamp(),
          'emotionTracker': FieldValue.increment(1),
          'emotionId': emotionId,
          'intensity': intensity
        });
      }
    } catch (e) {
      print('Error saving emotion to Firestore: ${e.toString()}');
      throw e;
    }
  }
}
