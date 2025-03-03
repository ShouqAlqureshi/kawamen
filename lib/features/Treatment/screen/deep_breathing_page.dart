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
  double instructionOpacity = 1.0;
  double countdownOpacity = 0.0;
  int countdownSeconds = 0;

  @override
  void dispose() {
    instructionTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  void startExercise() {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
      currentInstructionIndex = 0;
      countdownOpacity = 0.0;
    });
    showNextInstruction();
  }

  void showNextInstruction() {
    if (!isPlaying) return;

    // First, fade out both instruction and countdown
    setState(() {
      instructionOpacity = 0.0;
      
      // Start fading out the countdown - this is the key change
      if (countdownOpacity > 0) {
        countdownOpacity = 0.0;
      }
    });
    
    // After allowing time for the fade out animations
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isPlaying) return;

      // Update the instruction and fade it in
      setState(() {
        currentInstructionIndex = (currentInstructionIndex + 1) % instructions.length;
        instructionOpacity = 1.0;
      });

      // Prepare and start fading in the countdown
      Future.delayed(const Duration(milliseconds: 500), () {
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
    setState(() => isPlaying = false);
    instructionTimer?.cancel();
    countdownTimer?.cancel();
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
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'خروج',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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