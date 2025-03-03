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

  int currentInstructionIndex = 0;
  bool isPlaying = false;
  Timer? instructionTimer;
  Timer? countdownTimer;
  int countdownSeconds = 3;
  
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
      countdownSeconds = 3;
    });
    
    // Start the countdown timer
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownSeconds > 1) {
          countdownSeconds--;
        } else {
          countdownTimer?.cancel();
          cycleInstructions();
        }
      });
    });
  }

  void cycleInstructions() {
    // Start cycling through instructions
    instructionTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }
      
      setState(() {
        currentInstructionIndex = (currentInstructionIndex + 1) % instructions.length;
        countdownSeconds = 3; // Reset countdown for each instruction
      });
      
      // Reset countdown timer for each instruction
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
            countdownSeconds = 3;
          }
        });
      });
    });
  }

  void pauseExercise() {
    setState(() {
      isPlaying = false;
    });
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
                children: [
                  const SizedBox(height: 20),
                  // Breathing icon
                  const Icon(
                    Icons.air_rounded,
                    color: Color(0xFF8080FF),
                    size: 40,
                  ),
                  const SizedBox(height: 20),
                  // Exercise title
                  const Text(
                    'التنفس العميق',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Current instruction
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          instructions[currentInstructionIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Countdown circle
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF6750A4),
                          ),
                          child: Center(
                            child: Text(
                              isPlaying ? countdownSeconds.toString() : "3",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Total session progress
                  // SliderTheme(
                  //   data: SliderThemeData(
                  //     trackHeight: 4,
                  //     thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  //     overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  //     activeTrackColor: Colors.lightBlue,
                  //     inactiveTrackColor: Colors.grey[800],
                  //     thumbColor: Colors.lightBlue,
                  //   ),
                  //   child: Slider(
                  //     min: 0,
                  //     max: state.totalDuration.inSeconds.toDouble(),
                  //     value: state.currentPosition.inSeconds.toDouble(),
                  //     onChanged: (value) {
                  //       context.read<DeepBreathingBloc>().add(
                  //             DeepBreathingEvent.seekTo(
                  //               Duration(seconds: value.toInt()),
                  //             ),
                  //           );
                  //     },
                  //   ),
                  // ),
                  
                  // Duration indicators
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 25),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Text(
                  //         formatDuration(state.currentPosition),
                  //         style: const TextStyle(color: Colors.white, fontSize: 12),
                  //       ),
                  //       Text(
                  //         formatDuration(state.totalDuration),
                  //         style: const TextStyle(color: Colors.white, fontSize: 12),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  
                  const SizedBox(height: 30),
                  
                  // Play/Pause button
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
                  
                  const Spacer(),
                  
                  // Exit button
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
                  
                  const SizedBox(height: 20),
                  
                  // Bottom navigation icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}