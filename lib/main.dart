import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/app/app.dart';
import 'package:kawamen/features/Profile/repository/profile_repository.dart';
import 'package:kawamen/features/registration/bloc/auth_bloc.dart';
import 'package:kawamen/features/registration/repository/auth_repository.dart';
// Import the generated Firebase options file
import 'package:kawamen/firebase_options.dart';

import 'core/services/Notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // If using Firebase CLI
  );
    await NotificationService().initialize();
    listenForEmailVerification();  // Call this once at app startup
  runApp(App());
}
