import 'package:flutter/material.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/intro_screen.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kawamen',
      theme: ThemeData.dark(),
      home: EntryScreen(),
    );
  }
}
