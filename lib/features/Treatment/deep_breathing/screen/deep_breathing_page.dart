import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/MainNavigator.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/features/Treatment/deep_breathing/bloc/deep_breathing_bloc.dart';
import 'dart:math';

class DeepBreathingPage extends StatelessWidget {
  final String? userTreatmentId;
  final String? treatmentId;
  const DeepBreathingPage(
      {Key? key, this.userTreatmentId, this.treatmentId = 'DeepBreathing'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract parameters from route arguments if they exist
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Use route arguments if available, otherwise use constructor parameters
    final String? routeTreatmentId = args?['treatmentId'] as String?;
    final String? routeUserTreatmentId = args?['userTreatmentId'] as String?;

    // Print debug information
    print(
        'DeepBreathingPage BUILD - Constructor userTreatmentId: $userTreatmentId');
    print(
        'DeepBreathingPage BUILD - Route userTreatmentId: $routeUserTreatmentId');

    // Prioritize route parameters over constructor parameters
    final String? effectiveTreatmentId = routeTreatmentId ?? treatmentId;
    final String? effectiveUserTreatmentId =
        routeUserTreatmentId ?? userTreatmentId;

    print(
        'DeepBreathingPage BUILD - Effective userTreatmentId: $effectiveUserTreatmentId');

    return BlocProvider(
      create: (_) {
        final bloc = DeepBreathingBloc();

        // If we have a user treatment ID, load it immediately
        if (effectiveUserTreatmentId != null &&
            effectiveUserTreatmentId.isNotEmpty) {
          print(
              'DeepBreathingPage - Loading existing treatment: $effectiveUserTreatmentId');
          bloc.add(LoadUserTreatmentEvent(
            userTreatmentId: effectiveUserTreatmentId,
            treatmentId: effectiveTreatmentId ?? 'DeepBreathing',
          ));
        } else {
          // Otherwise just load the treatment data
          print(
              'DeepBreathingPage - No userTreatmentId, loading template data only');
          bloc.add(LoadTreatmentEvent(
              treatmentId: effectiveTreatmentId ?? 'DeepBreathing'));
        }

        return bloc;
      },
      child: _DeepBreathingView(
        userTreatmentId: effectiveUserTreatmentId,
        treatmentId: effectiveTreatmentId,
      ),
    );
  }
}

class _DeepBreathingView extends StatefulWidget {
  final String? userTreatmentId;
  final String? treatmentId;

  const _DeepBreathingView({this.userTreatmentId, this.treatmentId});

  @override
  State<_DeepBreathingView> createState() => _DeepBreathingViewState();
}

class _DeepBreathingViewState extends State<_DeepBreathingView>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize breathing animation controller
    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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

    // Initialize congratulations popup animation controllers
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

    _breathingAnimationController.value = 0.5;
    _glowAnimationController.value = 0.3;
  }

  @override
  void dispose() {
    _breathingAnimationController.dispose();
    _glowAnimationController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Handle animation based on the current instruction phase
  void _updateAnimations(DeepBreathingState state) {
    // Only animate when both playing and the countdown is active
    if (!state.isPlaying || !state.isAnimating) {
      // Stop all animations when not in active countdown
      _breathingAnimationController.stop();
      _glowAnimationController.stop();
      return;
    }

    switch (state.currentPhase) {
      case InstructionPhase.inhale:
        _breathingAnimationController.forward();
        _glowAnimationController.forward();
        break;
      case InstructionPhase.hold:
        _breathingAnimationController.stop();
        _glowAnimationController.stop();
        break;
      case InstructionPhase.exhale:
        _breathingAnimationController.animateTo(0.5,
            duration: const Duration(seconds: 6), curve: Curves.easeOut);
        _glowAnimationController.reverse();
        break;
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showCongratulationsPopup(BuildContext context) {
    // Get reference to the bloc before showing the dialog
    final deepBreathingBloc = context.read<DeepBreathingBloc>();
    // First, explicitly ensure the treatment is marked as completed in the database
    deepBreathingBloc.add(const CompleteTrackingTreatmentEvent());
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                      color: Theme.of(dialogContext).cardColor,
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
                            color: Theme.of(dialogContext)
                                .colorScheme
                                .onBackground,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لقد أكملت تمرين التنفس العميق بنجاح',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(dialogContext)
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
                            // Repeat button - Now with outlined style
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                deepBreathingBloc
                                    .add(const ResetExerciseEvent());
                                deepBreathingBloc
                                    .add(const StartExerciseEvent());
                              },
                              icon: Icon(
                                Icons.replay_rounded,
                                color: theme.colorScheme
                                    .secondary, // Explicitly set icon color to match text
                              ),
                              label: const Text('إعادة'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(dialogContext)
                                    .colorScheme
                                    .secondary,
                                side: BorderSide(
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .secondary),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            // Okay button - Now with filled style
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  dialogContext,
                                  MaterialPageRoute(
                                      builder: (_) => const MainNavigator()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(dialogContext)
                                    .colorScheme
                                    .secondary,
                                foregroundColor: Theme.of(dialogContext)
                                    .colorScheme
                                    .onSecondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('حسنا'),
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
    return BlocConsumer<DeepBreathingBloc, DeepBreathingState>(
      listener: (context, state) {
        // Update animations based on instruction phase
        _updateAnimations(state);

        // Show completion popup when exercise is completed
        if (state.isCompleting) {
          _showCongratulationsPopup(context);
        }
      },
      builder: (context, state) {
        // Get theme colors from context
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Handle loading state
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: LoadingScreen(),
            ),
          );
        }

        // Handle error state
        if (state.errorMessage != null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل التمرين',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DeepBreathingBloc>().add(
                            const LoadTreatmentEvent(
                                treatmentId: 'DeepBreathing'),
                          );
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }
        return WillPopScope(
          onWillPop: () async {
            // Show confirmation dialog if the session is active
            if (state.isPlaying) {
              context.read<DeepBreathingBloc>().add(const PauseExerciseEvent());
              bool shouldPop = await _showExitConfirmationDialog(context);
              return shouldPop;
            }
            // If not playing, allow normal back navigation
            return true;
          },
          child: Scaffold(
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
                                  colorScheme.secondary
                                      .withOpacity(_glowAnimation.value),
                                  colorScheme.secondary
                                      .withOpacity(_glowAnimation.value * 0.3),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.secondary
                                      .withOpacity(_glowAnimation.value * 0.5),
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

                // Main UI content
                Opacity(
                  opacity: 0.9,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: LayoutBuilder(builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          return Text(
                            screenWidth < 320
                                ? 'التنفس العميق'
                                : 'جلسة التنفس العميق',
                            style: TextStyle(
                              color: theme.colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  screenWidth < 360 ? 18 : screenWidth * 0.06,
                            ),
                            textDirection: TextDirection.rtl,
                          );
                        }),
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
                              '${state.currentRepetition} / ${state.totalRepetitions}',
                              style: TextStyle(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.7),
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Instruction text with fixed height container
                            Container(
                              height: 60,
                              alignment: Alignment.center,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: state.instructionOpacity,
                                child: Text(
                                  state.currentInstruction,
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

                            // Countdown with fixed height container
                            Container(
                              height: 40,
                              alignment: Alignment.center,
                              child: AnimatedOpacity(
                                opacity: state.countdownOpacity,
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  state.countdownSeconds.toString(),
                                  style: TextStyle(
                                    color: Colors.amber,
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
                                if (state.isPlaying) {
                                  context
                                      .read<DeepBreathingBloc>()
                                      .add(const PauseExerciseEvent());
                                } else {
                                  // If we're resuming an in-progress exercise
                                  if (state.currentRepetition > 1 ||
                                      state.currentInstructionIndex > 0 ||
                                      state.totalExerciseSeconds <
                                          state.totalExerciseTime) {
                                    context.read<DeepBreathingBloc>().add(
                                          ResumeExerciseEvent(
                                            remainingTotalSeconds:
                                                state.totalExerciseSeconds,
                                            remainingCountdownSeconds:
                                                state.countdownSeconds,
                                            currentInstructionIndex:
                                                state.currentInstructionIndex,
                                            currentRepetition:
                                                state.currentRepetition,
                                          ),
                                        );
                                  } else {
                                    // Starting a fresh exercise
                                    context
                                        .read<DeepBreathingBloc>()
                                        .add(const StartExerciseEvent());
                                  }
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
                                  state.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
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
                                color: theme.scaffoldBackgroundColor
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: colorScheme.secondary, width: 1),
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
                                    formatTime(state.totalExerciseSeconds),
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'هل أنت متأكد؟',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'إذا غادرت الآن، ستفقد التقدم في جلسة العلاج الحالية.',
                  textAlign: TextAlign.right,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false); // Don't exit
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                    child: const Text('البقاء'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true); // Confirm exit
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('مغادرة'),
                  ),
                ],
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
          },
        ) ??
        false; // Default to false (don't exit) if dialog is dismissed
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
