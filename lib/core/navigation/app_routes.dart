import 'package:flutter/material.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import 'package:kawamen/features/emotion_detection/screens/emotion_test_screen.dart';
import 'package:kawamen/features/login/view/login_page.dart';
import 'package:kawamen/features/home/screen/home_page.dart';
import 'package:kawamen/intro_screen.dart';
import 'package:kawamen/features/emotion_detection/screens/performance_metrics_screen.dart';

import '../../features/Treatment/CBT_therapy/screen/CBT_therapy_page.dart';
import '../../features/Treatment/deep_breathing/screen/deep_breathing_page.dart';

class AppRoutes {
  static const String entry = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String emotionTest = '/emotion-test';
  static const String home = '/home';
  static const String treatment1 = '/cbt-therapy';
  static const String treatment2 = '/deep-breathing';
  static const String performanceMetrics = '/performance-metrics';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if they exist
    final args = settings.arguments as Map<String, dynamic>? ?? {};

    switch (settings.name) {
      case entry:
        return MaterialPageRoute(builder: (_) => const EntryScreen());
      case login:
        // Using LoginPage, which should navigate to profile after successful login
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ViewProfileScreen());
      case emotionTest:
        return MaterialPageRoute(builder: (_) => const EmotionTestScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case treatment1:
        // Pass userTreatmentId and other args to CBTTherapyPage
        return MaterialPageRoute(
          builder: (_) => CBTTherapyPage(
            userTreatmentId: args['userTreatmentId'] as String?,
            treatmentId: args['treatmentId'] as String? ?? 'CBTtherapy',
          ),
        );
      case treatment2:
        // Pass userTreatmentId and other args to DeepBreathingPage
        return MaterialPageRoute(
          builder: (_) => DeepBreathingPage(
            userTreatmentId: args['userTreatmentId'] as String?,
            treatmentId: args['treatmentId'] as String? ?? 'DeepBreathing',
          ),
        );
      case performanceMetrics:
        return MaterialPageRoute(
          builder: (_) => PerformanceMetricsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Page not found")),
          ),
        );
    }
  }
}
