import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DashboardLoadingScreen extends StatelessWidget {
  const DashboardLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'lib/core/assets/animations/DashboardAnimation.json',
              width: 300,
              height: 300,
              repeat: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'Building your dashboard...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}