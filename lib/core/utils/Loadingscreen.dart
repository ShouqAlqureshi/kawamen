import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'lib/core/assets/animations/KawamenloadingAnimation.json',
        width: 200,
        height: 200,
        repeat: true,
      ),
    );
  }
}
