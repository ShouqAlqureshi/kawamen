import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Treatment/bloc/deep_breathing_bloc.dart';
import 'dart:async';

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

class _DeepBreathingViewState extends State<_DeepBreathingView> {
  final List<String> instructions = [
    'خذ شهيقًا عميقًا لمدة 4 ثوان...',
    'احبس النفس لمدة 4 ثوان...',
    'ثم أخرج الزفير ببطء لمدة 6 ثوان...',
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
  
  // Calculate total exercise time (10 repetitions x sum of all instruction durations)
  int get totalExerciseTime {
    // Sum of all instruction durations multiplied by number of repetitions
    return totalRepetitions * instructionDurations.reduce((a, b) => a + b);
  }

  @override
  void dispose() {
    instructionTimer?.cancel();
    countdownTimer?.cancel();
    totalExerciseTimer?.cancel();
    super.dispose();
  }

  void startExercise() {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
      isCompleting = false;
      currentInstructionIndex = 0;
      countdownOpacity = 0.0;
      currentRepetition = 1;
      totalExerciseSeconds = totalExerciseTime;
    });
    showNextInstruction();
    startTotalExerciseTimer();
  }

  void startTotalExerciseTimer() {
    totalExerciseTimer?.cancel();
    totalExerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlaying) {
        return;
      }
      
      setState(() {
        if (totalExerciseSeconds > 0) {
          totalExerciseSeconds--;
        } else {
          pauseExercise();
          timer.cancel();
        }
      });
    });
  }

  void showNextInstruction() {
    if (!isPlaying || isCompleting) return;

    // First, fade out both instruction and countdown
    setState(() {
      instructionOpacity = 0.0;
      
      // Start fading out the countdown
      if (countdownOpacity > 0) {
        countdownOpacity = 0.0;
      }
    });
    
    // After allowing time for the fade out animations
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isPlaying) return;

      // Check if we need to move to the next repetition
      if (currentInstructionIndex >= instructions.length - 1) {
        if (currentRepetition >= totalRepetitions) {
          // End of exercise - Important fix here!
          setState(() {
            isCompleting = true;
          });
          
          // Give a short delay before ending the exercise
          Future.delayed(const Duration(milliseconds: 500), () {
            pauseExercise();
          });
          return;
        } else {
          // Move to next repetition
          setState(() {
            currentRepetition++;
            currentInstructionIndex = 0;
          });
        }
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
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        if (countdownSeconds > 1) {
          countdownSeconds--;
        } else {
          countdownTimer?.cancel();
          
          // Instead of immediately showing next instruction,
          // first fade out the countdown smoothly
          countdownOpacity = 0.0;
          
          // Then show next instruction after animation completes
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
      isCompleting = false;
    });
    instructionTimer?.cancel();
    countdownTimer?.cancel();
    totalExerciseTimer?.cancel();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'جلسة التنفس العميق',
          style: TextStyle(color: Colors.white),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<DeepBreathingBloc, DeepBreathingState>(
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.air_rounded,
                    color: Color(0xFF8080FF),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  
                  // Repetition counter
                  Text(
                    '$currentRepetition / $totalRepetitions',
                    style: const TextStyle(
                      color: Colors.white70,
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
                        style: const TextStyle(
                          color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        pauseExercise();
                        context.read<DeepBreathingBloc>().add(const DeepBreathingEvent.pause());
                      } else {
                        startExercise();
                        context.read<DeepBreathingBloc>().add(const DeepBreathingEvent.play());
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Total exercise time countdown display - now below the play/pause button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6750A4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Color(0xFF6750A4),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatTime(totalExerciseSeconds),
                          style: const TextStyle(
                            color: Colors.white,
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
          );
        },
      ),
    );
  }
}