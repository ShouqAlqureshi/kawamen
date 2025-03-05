import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import 'package:kawamen/features/Treatment/bloc/deep_breathing_bloc.dart';
import 'dart:async';
import 'dart:math';

class DeepBreathingPage extends StatelessWidget {
  const DeepBreathingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeepBreathingBloc(),
      child: const _DeepBreathingView(),
    );
  }
}

class _DeepBreathingView extends StatefulWidget {
  const _DeepBreathingView();

  @override
  State<_DeepBreathingView> createState() => _DeepBreathingViewState();
}

class _DeepBreathingViewState extends State<_DeepBreathingView>
    with TickerProviderStateMixin {
  final List<String> instructions = [
    'خذ شهيقًا عميقًا لمدة 4 ثوان...',
    'احبس النفس لمدة 4 ثوان...',
    'أخرج الزفير ببطء لمدة 6 ثوان...',
  ];

  final List<int> instructionDurations = [4, 4, 6];
  int currentInstructionIndex = 0;
  bool isPlaying = false;
  Timer? instructionTimer;
  Timer? countdownTimer;
  Timer? totalExerciseTimer;
  double instructionOpacity = 1.0;
  double countdownOpacity = 0.0;
  int countdownSeconds = 0;

  // Total repetitions and tracking
  final int totalRepetitions = 10;
  int currentRepetition = 1;
  int totalExerciseSeconds = 0;
  bool isCompleting = false;

  // Track remaining timers for precise resuming
  int remainingCountdownSeconds = 0;
  int remainingTotalExerciseSeconds = 0;

  // Animation controllers for congratulations popup
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;
   // New animation controller for breathing animation
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;

  // New animation controller for glow effect
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  // Calculate total exercise time (10 repetitions x sum of all instruction durations)
  int get totalExerciseTime {
    return totalRepetitions *
        (instructionDurations.reduce((a, b) => a + b) + 8)+3+6;
  }

  @override
  void initState() {
    super.initState();
// Initialize breathing animation controller
    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Match inhale duration
    );

    _breathingAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize glow animation controller
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    // Initialize animation controllers
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    // Add new controllers to dispose
    _breathingAnimationController.dispose();
    _glowAnimationController.dispose();
    instructionTimer?.cancel();
    countdownTimer?.cancel();
    totalExerciseTimer?.cancel();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void startExercise() {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
      isCompleting = false;
      
      // Use stored or initial values
      if (remainingTotalExerciseSeconds > 0) {
        totalExerciseSeconds = remainingTotalExerciseSeconds;
      } else {
        totalExerciseSeconds = totalExerciseTime;
      }

      // Set initial instruction and countdown state
      if (remainingCountdownSeconds > 0) {
        countdownSeconds = remainingCountdownSeconds;
        countdownOpacity = 1.0;
      } else {
        currentInstructionIndex = 0;
        currentRepetition = 1;
        countdownSeconds = instructionDurations[currentInstructionIndex];
        countdownOpacity = 0.0;
        instructionOpacity = 1.0;
      }
    });

    // Restart timers based on remaining time
    if (remainingCountdownSeconds > 0) {
      startCountdown();
    } else {
      // Delay to show instruction before starting countdown
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          countdownOpacity = 1.0;
          countdownSeconds = instructionDurations[currentInstructionIndex];
        });
        startCountdown();
      });
    }

    startTotalExerciseTimer();
  }

  void startTotalExerciseTimer() {
    totalExerciseTimer?.cancel();
    totalExerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        if (totalExerciseSeconds > 0) {
          totalExerciseSeconds--;
          remainingTotalExerciseSeconds = totalExerciseSeconds;
        } else {
          // Explicitly handle exercise completion
          pauseExercise();
          timer.cancel();
          
          // Ensure popup is shown when timer reaches zero
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _showCongratulationsPopup();
            }
          });
        }
      });
    });
  }


  void showNextInstruction() {
    if (!isPlaying || isCompleting) return;

    // First, fade out both instruction and countdown
    setState(() {
      instructionOpacity = 0.0;
      if (countdownOpacity > 0) {
        countdownOpacity = 0.0;
      }
    });

    // After allowing time for the fade out animations
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isPlaying) return;

      // Explicitly check for exercise completion
      if (currentRepetition >= totalRepetitions && 
          currentInstructionIndex >= instructions.length - 1) {
        // Definitely end of exercise
        setState(() {
          isCompleting = true;
          isPlaying = false;
        });

        // Immediate popup show
        _showCongratulationsPopup();
        return;
      }

      // Check if we need to move to the next repetition
      if (currentInstructionIndex >= instructions.length - 1) {
        setState(() {
          currentRepetition++;
          currentInstructionIndex = 0;
        });
      } else {
        // Move to next instruction in the current repetition
        setState(() {
          currentInstructionIndex++;
        });
      }

      // Update the instruction and fade it in
      setState(() {
        instructionOpacity = 1.0;
      });

      // Prepare and start fading in the countdown
      Future.delayed(const Duration(seconds: 2), () {
        if (!isPlaying) return;

        setState(() {
          countdownSeconds = instructionDurations[currentInstructionIndex];
          countdownOpacity = 1.0;
        });

        startCountdown();
      });
    });
  }

void startCountdown() {
  countdownTimer?.cancel();
  
  // Update breathing and glow animations based on instruction
  if (currentInstructionIndex == 0) { // Inhale
    _breathingAnimationController.forward();
    _glowAnimationController.forward();
  } else if (currentInstructionIndex == 1) { // Hold
    _breathingAnimationController.stop();
    _glowAnimationController.stop();
  } else if (currentInstructionIndex == 2) { // Exhale
    // Create a new animation that takes the full exhale duration
    _breathingAnimationController.animateTo(
      0.5, // Contract back to original size
      duration: const Duration(seconds: 6), // Match full exhale duration
      curve: Curves.easeOut
    );
    _glowAnimationController.reverse();
  }
  // Use remaining countdown seconds or reset to instruction duration
  int currentCountdown = remainingCountdownSeconds > 0 
      ? remainingCountdownSeconds 
      : instructionDurations[currentInstructionIndex];

  setState(() {
    countdownSeconds = currentCountdown;
  });

  countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!isPlaying) {
      timer.cancel();
      return;
    }

    setState(() {
      if (countdownSeconds > 1) {
        countdownSeconds--;
        remainingCountdownSeconds = countdownSeconds;
      } else {
        countdownTimer?.cancel();
        remainingCountdownSeconds = 0;

        // Fade out countdown smoothly
        countdownOpacity = 0.0;

        // Show next instruction after animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (isPlaying) {
            showNextInstruction();
          }
        });
      }
    });
  });
}

  void pauseExercise() {
    setState(() {
      isPlaying = false;
      // Store the current state for potential resuming
      // Keep track of remaining times
      remainingTotalExerciseSeconds = totalExerciseSeconds;
      // If countdown is active, store its remaining time
      remainingCountdownSeconds = countdownSeconds;
    });
    
    // Cancel all timers
    instructionTimer?.cancel();
    countdownTimer?.cancel();
    totalExerciseTimer?.cancel();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Show congratulations popup with animation
  void _showCongratulationsPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Reset and start animations
        _scaleController.reset();
        _confettiController.reset();
        _scaleController.forward();
        _confettiController.forward();

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Confetti animation overlay
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _confettiAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ConfettiPainter(
                          progress: _confettiAnimation.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),

                // Main popup card with scale animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon with glow effect
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Congratulations text
                        Text(
                          'تهانينا!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لقد أكملت تمرين التنفس العميق بنجاح',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Repeat button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Reset exercise state
                                setState(() {
                                  currentRepetition = 1;
                                  currentInstructionIndex = 0;
                                  isCompleting = false;
                                });
                                startExercise();
                              },
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text('إعادة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            // Okay button
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ViewProfileScreen()),
                                );
                              },
                              child: const Text('حسنا'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  // Get theme colors from context
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    body: Stack(
      children: [
        // Breathing Background Animation
        Center(
          child: AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 300 * _breathingAnimation.value,
                    height: 300 * _breathingAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.secondary.withOpacity(_glowAnimation.value),
                          colorScheme.secondary.withOpacity(_glowAnimation.value * 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Existing page content (with slight opacity adjustment)
        Opacity(
          opacity: 0.9,
          child: BlocBuilder<DeepBreathingBloc, DeepBreathingState>(
            builder: (context, state) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      'جلسة التنفس العميق',
                      style: TextStyle(color: theme.colorScheme.onBackground),
                      textDirection: TextDirection.rtl,
                    ),
                    centerTitle: true,
                  ),
                  backgroundColor: Colors.transparent,
                  body: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.air_rounded,
                          color: colorScheme.primary,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        
                        // Repetition counter
                        Text(
                          '$currentRepetition / $totalRepetitions',
                          style: TextStyle(
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Fixed height container for instruction text
                        Container(
                          height: 60, // Fixed height for instruction text
                          alignment: Alignment.center,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: instructionOpacity,
                            child: Text(
                              instructions[currentInstructionIndex],
                              style: TextStyle(
                                color: theme.colorScheme.onBackground,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Fixed height container for countdown with smooth animations
                        Container(
                          height: 40, // Fixed height for countdown
                          alignment: Alignment.center,
                          child: AnimatedOpacity(
                            opacity: countdownOpacity,
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              countdownSeconds.toString(),
                              style: TextStyle(
                                color: Colors.amber, // Keeping amber for countdown visibility
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        
                        // Play/Pause Button
                        GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              pauseExercise();
                              context
                                  .read<DeepBreathingBloc>()
                                  .add(const DeepBreathingEvent.pause());
                            } else {
                              startExercise();
                              context
                                  .read<DeepBreathingBloc>()
                                  .add(const DeepBreathingEvent.play());
                            }
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: colorScheme.onSecondary,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Total exercise time countdown display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.secondary, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatTime(totalExerciseSeconds),
                                style: TextStyle(
                                  color: theme.colorScheme.onBackground,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random random = Random();

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Number of confetti pieces
    final int count = 100;

    for (int i = 0; i < count; i++) {
      // Random position and color for each confetti piece
      final double x = random.nextDouble() * canvasSize.width;
      // Initial y position at top, moves down with animation progress
      final double y =
          -20 + progress * (canvasSize.height + 40) * random.nextDouble();

      // Random color from a festive palette
      final List<Color> colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
      ];
      final Color color = colors[random.nextInt(colors.length)];

      // Random size for each piece
      final double pieceSize = 5 + random.nextDouble() * 10;

      // Draw square or circle confetti
      final paint = Paint()..color = color;

      if (i % 2 == 0) {
        // Square confetti
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: pieceSize, height: pieceSize),
          paint,
        );
      } else {
        // Circle confetti
        canvas.drawCircle(
          Offset(x, y),
          pieceSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
