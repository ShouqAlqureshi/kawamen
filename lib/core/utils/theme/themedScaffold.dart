import 'package:flutter/material.dart';
import 'package:kawamen/core/utils/theme/animated_background.dart';

class ThemedScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const ThemedScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glowColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // Background glow animation
          AnimatedGlowBackground(glowColor: glowColor),
          // Main content
          Positioned.fill(child: body),
        ],
      ),
    );
  }
}
