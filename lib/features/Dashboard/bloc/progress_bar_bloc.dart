import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Events for Treatment Progress BLoC
abstract class TreatmentProgressEvent {}

class FetchTreatmentProgress extends TreatmentProgressEvent {}

// States for Treatment Progress BLoC
abstract class TreatmentProgressState {}

class TreatmentProgressInitial extends TreatmentProgressState {}

class TreatmentProgressLoading extends TreatmentProgressState {}

class TreatmentProgressLoaded extends TreatmentProgressState {
  final double progress;
  final int completedTreatments;
  final int totalTreatments;

  TreatmentProgressLoaded(
      this.progress, this.completedTreatments, this.totalTreatments);
}

class TreatmentProgressError extends TreatmentProgressState {
  final String message;

  TreatmentProgressError(this.message);
}

// BLoC for Treatment Progress
class TreatmentProgressBloc
    extends Bloc<TreatmentProgressEvent, TreatmentProgressState> {
  TreatmentProgressBloc() : super(TreatmentProgressInitial()) {
    on<FetchTreatmentProgress>(_onFetchTreatmentProgress);
  }

  Future<void> _onFetchTreatmentProgress(FetchTreatmentProgress event,
      Emitter<TreatmentProgressState> emit) async {
    emit(TreatmentProgressLoading());

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(TreatmentProgressError('User not authenticated'));
        return;
      }

      // Calculate date range for last 7 days
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      // Fetch treatments from Firestore for the last 7 days
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .get();

      int totalTreatments = treatmentsSnapshot.docs.length;
      int completedTreatments = 0;

      // Process each treatment document
      for (var doc in treatmentsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          completedTreatments++;
        }
      }

      // Safely calculate progress (ensures value is between 0.0 and 1.0)
      double progress = (totalTreatments > 0)
          ? (completedTreatments / totalTreatments).clamp(0.0, 1.0)
          : 0.0;
      if (progress.isNaN) {
        progress = 0.0;
      }
      emit(TreatmentProgressLoaded(
          progress, completedTreatments, totalTreatments));
    } catch (e) {
      // Only emit one state, not two consecutive states
      emit(TreatmentProgressLoaded(0.0, 0, 0)); // Safe fallback state
      // Or you could log the error but still emit a safe state
      log('Error fetching treatment data: $e');
    }
  }
}
