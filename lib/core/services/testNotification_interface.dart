
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart'; // Add this dependency if not already added
import 'package:kawamen/core/services/Notification_service.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({Key? key}) : super(key: key);

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Emotion Notifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // Information text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Use these buttons to simulate emotion detection and test the notification flow.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Button for Sadness emotion
            _buildEmotionButton(
              emotion: 'sad',
              color: Colors.blue,
              icon: Icons.sentiment_dissatisfied,
            ),
            
            const SizedBox(height: 20),
            
            // Button for Anger emotion
            _buildEmotionButton(
              emotion: 'angry',
              color: Colors.red,
              icon: Icons.sentiment_very_dissatisfied,
            ),

            // You can add more buttons for other emotions if needed
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionButton({
    required String emotion,
    required Color color,
    required IconData icon,
  }) {
    String displayName = emotion.substring(0, 1).toUpperCase() + emotion.substring(1);
    
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          displayName,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _isLoading ? null : () => _simulateEmotionDetection(emotion),
      ),
    );
  }

  Future<void> _simulateEmotionDetection(String emotion) async {
    // Check if user is logged in
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to test notifications')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create an emotion document in Firestore
      final emotionId = const Uuid().v4(); // Generate a unique ID
      final intensity = emotion == 'anger' ? 0.8 : 0.6; // Mock intensity
      
      // Create emotion document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('emotionalData')
          .doc(emotionId)
          .set({
        'emotion': emotion,
        'intensity': intensity,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Directly trigger the notification through the NotificationBloc
      final notificationBloc = NotificationService().bloc;
      notificationBloc.add(ShowEmotionNotification(emotion, intensity, emotionId));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$emotion notification triggered'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}