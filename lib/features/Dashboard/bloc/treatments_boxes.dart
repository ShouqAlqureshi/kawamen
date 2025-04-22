import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawamen/core/utils/theme/theme.dart';

// Treatment Stats Event/State
abstract class TreatmentStatsEvent {}

class FetchTreatmentStats extends TreatmentStatsEvent {}

abstract class TreatmentStatsState {}

class TreatmentStatsInitial extends TreatmentStatsState {}

class TreatmentStatsLoading extends TreatmentStatsState {}

class TreatmentStatsError extends TreatmentStatsState {
  final String message;
  TreatmentStatsError(this.message);
}

class TreatmentStatsLoaded extends TreatmentStatsState {
  final int allTreatments;
  final int completedTreatments;
  final int acceptedTreatments;
  final int rejectedTreatments;

  TreatmentStatsLoaded({
    required this.allTreatments,
    required this.completedTreatments,
    required this.acceptedTreatments,
    required this.rejectedTreatments,
  });
}

// BLoC for Treatment Stats
class TreatmentStatsBloc
    extends Bloc<TreatmentStatsEvent, TreatmentStatsState> {
  TreatmentStatsBloc() : super(TreatmentStatsInitial()) {
    on<FetchTreatmentStats>(_onFetchTreatmentStats);
  }

  Future<void> _onFetchTreatmentStats(
      FetchTreatmentStats event, Emitter<TreatmentStatsState> emit) async {
    emit(TreatmentStatsLoading());

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(TreatmentStatsError('User not authenticated'));
        return;
      }

      // Calculate date range for current week
      final now = DateTime.now();
      final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
      final startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
      final endDate = startDate.add(const Duration(days: 7));

      // Fetch treatments from Firestore for the current week
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .get();

      int allTreatments = treatmentsSnapshot.docs.length;
      int completedTreatments = 0;
      int acceptedTreatments = 0;
      int rejectedTreatments = 0;

      // Process each treatment document
      for (var doc in treatmentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        if (status == 'completed') {
          completedTreatments++;
        }
        if (status == 'accepted') {
          acceptedTreatments++;
        }
        if (status == 'rejected') {
          rejectedTreatments++;
        }
      }

      emit(TreatmentStatsLoaded(
        allTreatments: allTreatments,
        completedTreatments: completedTreatments,
        acceptedTreatments: acceptedTreatments,
        rejectedTreatments: rejectedTreatments,
      ));
    } catch (e) {
      emit(TreatmentStatsError('Error fetching treatment stats: $e'));
    }
  }
}

// Widget to display treatment statistics in boxes
class TreatmentStatsBoxes extends StatelessWidget {
  const TreatmentStatsBoxes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TreatmentStatsBloc()..add(FetchTreatmentStats()),
      child: BlocBuilder<TreatmentStatsBloc, TreatmentStatsState>(
        builder: (context, state) {
          if (state is TreatmentStatsLoading) {
            return const Center(
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
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
    // Get chart colors from theme
    final customColors = Theme.of(context).extension<CustomColors>();
    final chartColors = customColors?.chartColors ??
        [Colors.orange, Colors.purple, Colors.green, Colors.red];

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
                  color: chartColors[1], // Purple from theme
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المكتملة",
                  value: state.completedTreatments.toString(),
                  icon: Icons.check_circle,
                  color: chartColors[2], // Green from theme
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
                  title: "الجلسات المقبولة",
                  value: state.acceptedTreatments.toString(),
                  icon: Icons.thumb_up,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary, // Secondary color from theme
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المرفوضة",
                  value: state.rejectedTreatments.toString(),
                  icon: Icons.thumb_down,
                  color: chartColors[3], // Red from theme
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
      height: 56, // Reduced height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.6),
            color.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // Slightly tighter corners
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.background.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 0, vertical: 0), // Smaller padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11, // Smaller font
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Smaller font
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              color: theme.colorScheme.onPrimary,
              size: 20, // Smaller icon
            ),
          ],
        ),
      ),
    );
  }
}
