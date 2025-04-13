import 'package:flutter/material.dart';
import 'package:kawamen/features/emotion_detection/screens/emotion_test_screen.dart';
import 'package:kawamen/features/login/view/login_page.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import 'package:kawamen/intro_screen.dart';
import 'package:kawamen/home_page.dart';

class AppRoutes {
  static const String entry = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String emotionTest = '/emotion-test';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case entry:
        return MaterialPageRoute(builder: (_) => const EntryScreen());
      case login:
        // After login, go directly to the Emotion Test Screen
        return MaterialPageRoute(builder: (_) => const EmotionTestScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const EmotionTestScreen());
      case emotionTest:
        return MaterialPageRoute(builder: (_) => const EmotionTestScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Page not found")),
          ),
        );
    }
  }
}
