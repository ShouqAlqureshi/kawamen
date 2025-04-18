import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
class TreatmentStatsBloc extends Bloc<TreatmentStatsEvent, TreatmentStatsState> {
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
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsBoxes(BuildContext context, TreatmentStatsLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المكتملة",
                  value: state.completedTreatments.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
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
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatsBox(
                  context: context,
                  title: "الجلسات المرفوضة",
                  value: state.rejectedTreatments.toString(),
                  icon: Icons.thumb_down,
                  color: Colors.red,
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
    return Container(
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.7),
            color.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end, // For RTL layout
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end, // For RTL layout
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // Space between icon and text
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}