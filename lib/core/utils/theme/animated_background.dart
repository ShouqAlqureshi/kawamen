import 'package:flutter/material.dart';

class AnimatedGlowBackground extends StatefulWidget {
  final Color glowColor;
  final Widget? child;

  const AnimatedGlowBackground({
    Key? key,
    required this.glowColor,
    this.child,
  }) : super(key: key);

  @override
  _AnimatedGlowBackgroundState createState() => _AnimatedGlowBackgroundState();
}

class _AnimatedGlowBackgroundState extends State<AnimatedGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.glowColor.withOpacity(_glowAnimation.value * 0.6),
                      widget.glowColor.withOpacity(_glowAnimation.value * 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          widget.glowColor.withOpacity(_glowAnimation.value * 0.3),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}
