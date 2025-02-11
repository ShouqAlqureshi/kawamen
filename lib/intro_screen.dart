import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawamen/core/navigation/app_routes.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // For the swipe-to-start slider.
  double _dragPos = 0.0;
  final double _trackWidth = 260.0;
  final double _handleWidth = 60.0;
  late final double _maxDrag; // _trackWidth - _handleWidth

  @override
  void initState() {
    super.initState();
    _maxDrag = _trackWidth - _handleWidth;

    // Set up a fade-in animation for the screen content.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Auto navigate after 5 seconds.
    // Future.delayed(const Duration(seconds: 5), () {
    // if (mounted) {
    //  Navigator.pushReplacementNamed(context, AppRoutes.login);
    // }
    // });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      body: GestureDetector(
        // Allow horizontal swipe anywhere to navigate (optional).
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background gradient.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.black, Color(0xFF3E206D)],
                ),
              ),
            ),
            // Fade in all the content.
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Centered text with decorative green stars.
                  Stack(
                    clipBehavior:
                        Clip.none, // Allow children to overflow if needed.
                    alignment: Alignment.center,
                    children: [
                      // Positioned green stars placed outside the padded text area.
                      Positioned(
                        top: -20, // Moves the star above the container.
                        left: -20, // Moves the star to the left.
                        child: Image.asset(
                          "lib/core/assets/images/green_star.png",
                          width: 20,
                        ),
                      ),
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Image.asset(
                          "lib/core/assets/images/green_star.png",
                          width: 15,
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Image.asset(
                          "lib/core/assets/images/green_star.png",
                          width: 15,
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        right: -20,
                        child: Image.asset(
                          "lib/core/assets/images/green_star.png",
                          width: 20,
                        ),
                      ),
                      // The text is wrapped in a padded Container to give extra space.
                      Container(
                        padding: const EdgeInsets.all(30),
                        child: const Text(
                          "نفهمك لأننا نشعر\nبكوامنك!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Hands and logo in between.
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset("lib/core/assets/images/hands.png",
                          width: 280),
                      Image.asset("lib/core/assets/images/logo.png",
                          width: 280),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Page indicator.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.circle, size: 10, color: Colors.green),
                      SizedBox(width: 5),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                      SizedBox(width: 5),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Swipe-to-start slider.
                  _buildSwipeToStartSlider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeToStartSlider() {
    return SizedBox(
      width: _trackWidth,
      height: 60,
      child: Stack(
        children: [
          // The slider track.
          Container(
            width: _trackWidth,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                "اسحب للبدء",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // The draggable handle.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: _dragPos,
            top: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPos += details.delta.dx;
                  if (_dragPos < 0) _dragPos = 0;
                  if (_dragPos > _maxDrag) _dragPos = _maxDrag;
                });
              },
              onHorizontalDragEnd: (details) async {
                if (_dragPos > _maxDrag * 0.75) {
                  // Check if the user is logged in
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // If user is logged in, navigate to the profile view
                    Navigator.pushReplacementNamed(context, AppRoutes.profile);
                  } else {
                    // If user is not logged in, navigate to the login view
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                } else {
                  // If not dragged enough, animate back to the start.
                  setState(() {
                    _dragPos = 0;
                  });
                }
              },
              child: Container(
                width: _handleWidth,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
