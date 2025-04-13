import 'package:flutter/material.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/registration/screens/registration_screen.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //  initialRoute: AppRoutes.entry,  // Set initial route
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
      title: 'Kawamen',
      theme: AppTheme.darkTheme,
      home: RegistrationScreen(),
    );
  }
}
