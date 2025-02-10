import 'package:flutter/material.dart';
//import 'package:your_project/features/home/home_screen.dart';
//import 'package:your_project/features/auth/login_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      //return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
      //  return MaterialPageRoute(builder: (_) => const LoginScreen());
      default:
        return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text("Page not found"))));
    }
  }
}
