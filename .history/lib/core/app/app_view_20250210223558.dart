import 'package:flutter/material.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import 'package:kawamen/features/registration/screens/registration_screen.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kawamen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: RegistrationScreen(), // Force app to start at registration screen
    );
  }
}
