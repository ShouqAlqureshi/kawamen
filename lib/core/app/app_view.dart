import 'package:flutter/material.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import 'package:kawamen/features/login/view/login_page.dart';
import 'package:kawamen/features/registration/screens/registration_screen.dart';
import 'package:kawamen/intro_screen.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       initialRoute: AppRoutes.entry,  // Set initial route
      onGenerateRoute: AppRoutes.generateRoute, 
      debugShowCheckedModeBanner: false,
      title: 'Kawamen',
      theme: AppTheme.darkTheme,
      home: EntryScreen(),
    );
  }
}
