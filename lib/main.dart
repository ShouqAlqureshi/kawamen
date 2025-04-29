import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kawamen/core/app/app.dart';
import 'package:kawamen/features/Profile/repository/profile_repository.dart';
import 'package:kawamen/firebase_options.dart';

import 'core/services/Notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
    // Provide fallback values or handle the error
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initialize();
  listenForEmailVerification(); // Call this once at app startup

  runApp(const App());
}
