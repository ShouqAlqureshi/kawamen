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
  double opacity = 1.0;
  int countdownSeconds = 0;
  bool showingCountdown = false;

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
      showingCountdown = false;
    });
    showNextInstruction();
  }

  void showNextInstruction() {
    if (!isPlaying) return;

    setState(() {
      opacity = 0.0;
      showingCountdown = false;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (!isPlaying) return;

      setState(() {
        currentInstructionIndex = (currentInstructionIndex + 1) % instructions.length;
        opacity = 1.0;
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!isPlaying) return;
      setState(() {
        countdownSeconds = instructionDurations[currentInstructionIndex];
        showingCountdown = true;
      });
      startCountdown();
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
          showNextInstruction();
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
                      duration: const Duration(seconds: 1),
                      opacity: opacity,
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
                  
                  // Fixed height container for countdown
                  Container(
                    height: 40, // Fixed height for countdown
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      opacity: showingCountdown ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        showingCountdown ? countdownSeconds.toString() : "",
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