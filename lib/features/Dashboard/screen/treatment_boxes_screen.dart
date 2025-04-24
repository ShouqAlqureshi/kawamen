import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/Dashboard/bloc/treatment_progress_bloc.dart';
import 'package:kawamen/features/Dashboard/bloc/treatments_boxes_bloc.dart';

class TreatmentStatsBoxes extends StatelessWidget {
  const TreatmentStatsBoxes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TreatmentStatsBloc()..add(FetchTreatmentStats()),
      child: BlocBuilder<TreatmentStatsBloc, TreatmentStatsState>(
        builder: (context, state) {
          if (state is TreatmentProgressLoading ||
              state is TreatmentProgressInitial) {
            return Center(
              child: LoadingScreen(),
            );
          } else if (state is TreatmentStatsLoaded) {
            return _buildStatsBoxes(context, state);
          } else if (state is TreatmentStatsError) {
            return Center(
              child: Text(
                state.message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsBoxes(BuildContext context, TreatmentStatsLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row of boxes
          Row(
            children: [
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "إجمالي الجلسات",
                  value: state.allTreatments.toString(),
                  icon: Icons.medical_services, 
                  color: const Color(0xFF4A2882), // Darker purple color
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المرفوضة",
                  value: state.rejectedTreatments.toString(),
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFF4A2882), // Darker purple color
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Second row of boxes
          Row(
            children: [
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المكتملة",
                  value: state.completedTreatments.toString(),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF4A2882), // Darker purple color
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المقبولة",
                  value: state.acceptedTreatments.toString(),
                  icon: Icons.thumb_up_outlined,
                  color: const Color(0xFF4A2882), // Darker purple color
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBox({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      height: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.7), // Darker start color
            color.withOpacity(0.55), // Mid gradient
            color.withOpacity(0.0), // Lighter end color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0], // Controls gradient distribution
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // Slightly more transparent
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),

            // Right side: Text content - right aligned for Arabic
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.greenAccent.shade200, // Slightly adjusted color
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}