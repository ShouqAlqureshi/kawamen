import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Dashboard/bloc/progress_bar_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/material.dart';
class TreatmentProgressTracker extends StatelessWidget {
  const TreatmentProgressTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TreatmentProgressBloc()..add(FetchTreatmentProgress()),
      child: BlocBuilder<TreatmentProgressBloc, TreatmentProgressState>(
        builder: (context, state) {
          if (state is TreatmentProgressLoading || state is TreatmentProgressInitial) {
            return _buildProgressContainer(
              0.0,
              Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            );
          } else if (state is TreatmentProgressLoaded) {
            return _buildProgressContainer(
              state.progress,
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: state.progress,
                header: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "نسبة اكتمال الجلسات العلاجية",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                footer: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "${state.completedTreatments}/${state.totalTreatments} آخر 7 أيام",
                    style: TextStyle(fontSize: 20, color: Colors.white),
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
                    Text(
                      "خطأ في تحميل البيانات",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        context.read<TreatmentProgressBloc>().add(FetchTreatmentProgress());
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
    return Container(
      width: 330,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 42, 24, 49),
            Color.fromARGB(255, 38, 23, 48),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
