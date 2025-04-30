import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/features/Dashboard/bloc/treatmentsDashboard_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';

class TreatmentProgressTracker extends StatelessWidget {
  const TreatmentProgressTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreatmentBloc, TreatmentState>(
      builder: (context, state) {
        if (state is TreatmentLoading || state is TreatmentInitial) {
          return Center(
            child: LoadingScreen(),
          );
        } else if (state is TreatmentLoaded) {
          // Check if the user has any treatments
          if (state.weeklyTotalTreatments == 0) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "لا تملك جلسات لهذا الاسبوع",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Center(
            child: CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 10.0,
              percent: state.weeklyProgress
                  .clamp(0.0, 1.0), // Ensure value is between 0-1
              header: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "نسبة اكتمال الجلسات العلاجية",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "${state.weeklyCompletedTreatments}/${state.weeklyTotalTreatments} آخر 7 أيام",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              center: Text(
                "${(state.weeklyProgress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              progressColor: const Color.fromARGB(255, 53, 189, 58),
              backgroundColor: Colors.grey.withOpacity(0.3),
              circularStrokeCap: CircularStrokeCap.round,
            ),
          );
        } else if (state is TreatmentError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "خطأ في تحميل البيانات",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                  onPressed: () {
                    context.read<TreatmentBloc>().add(FetchTreatmentData());
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}