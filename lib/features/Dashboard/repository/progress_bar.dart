import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/material.dart';

class TreatmentProgressTracker extends StatelessWidget {
  final double progress; // Example: 0.8 (80%)

  const TreatmentProgressTracker({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(10), // Add padding around the progress bar
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 42, 24, 49), // Light
            Color.fromARGB(255, 38, 23, 48), // Darker
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(20), // Rounded corners
      ),
      child: CircularPercentIndicator(
        radius: 60.0,
        lineWidth: 10.0,
        percent: progress,
        header: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "نسبة اكتمال الجلسات العلاجية",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        footer: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text("آخر 7 أيام",
              style: const TextStyle(fontSize: 20, color: Colors.white)),
        ),
        center: Text(
          "${(progress * 100).toStringAsFixed(0)}%",
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        progressColor: const Color.fromARGB(255, 53, 189, 58),
        backgroundColor: Colors.transparent, // Make the background transparent
        circularStrokeCap:
            CircularStrokeCap.round, // Rounded edges for the progress bar
      ),
    );
  }
}
