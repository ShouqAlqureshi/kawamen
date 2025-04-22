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

      // Fetch ALL treatments from Firestore without date filtering
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments')
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