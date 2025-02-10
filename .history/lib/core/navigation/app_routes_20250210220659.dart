import 'package:flutter/material.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String profile = '/profile'; // ✅ Define the profile route

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      //  case home:
      //    return MaterialPageRoute(builder: (_) => const );
      // case login:
      //   return MaterialPageRoute(builder: (_) => const );
      case profile: // ✅ Add Profile Route
        return MaterialPageRoute(builder: (_) => const ViewProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Page not found")),
          ),
        );
    }
  }
}
