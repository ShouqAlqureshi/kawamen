import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/features/Dashboard/bloc/progress_bar_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/material.dart';

class TreatmentProgressTracker extends StatelessWidget {
  const TreatmentProgressTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TreatmentProgressBloc()..add(FetchTreatmentProgress()),
      child: BlocBuilder<TreatmentProgressBloc, TreatmentProgressState>(
        builder: (context, state) {
          if (state is TreatmentProgressLoading ||
              state is TreatmentProgressInitial) {
            return _buildProgressContainer(
              0.0,
              const Center(
                child: LoadingScreen(),
              ),
            );
          } else if (state is TreatmentProgressLoaded) {
            // Check if the user has any treatments
            if (state.totalTreatments == 0) {
              return _buildProgressContainer(
                0.0,
                const Center(
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
                ),
              );
            }

            return _buildProgressContainer(
              state.progress.clamp(0.0, 1.0),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: state.progress
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
                    "${state.completedTreatments}/${state.totalTreatments} آخر 7 أيام",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                center: Text(
                  "${(state.progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                progressColor: const Color.fromARGB(255, 53, 189, 58),
                backgroundColor: Colors.grey.withOpacity(0.3),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            );
          } else if (state is TreatmentProgressError) {
            return _buildProgressContainer(
              0.0,
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "خطأ في تحميل البيانات",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.refresh, color: Colors.greenAccent),
                      onPressed: () {
                        context
                            .read<TreatmentProgressBloc>()
                            .add(FetchTreatmentProgress());
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildProgressContainer(double progress, Widget child) {
    // Ensure container has valid constraints
    return SizedBox(
      width: 330,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2B2B2B),
              Color(0xFF2B2B2B),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}
