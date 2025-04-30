import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Events for Combined Treatment BLoC
abstract class TreatmentEvent {}

class FetchTreatmentData extends TreatmentEvent {
  final bool forceRefresh;
  FetchTreatmentData({this.forceRefresh = false});
}

class StartTreatmentStream extends TreatmentEvent {}

class StopTreatmentStream extends TreatmentEvent {}

// States for Combined Treatment BLoC
abstract class TreatmentState {}

class TreatmentInitial extends TreatmentState {}

class TreatmentLoading extends TreatmentState {}

class TreatmentLoaded extends TreatmentState {
  // Progress tracking data (last 7 days)
  final double weeklyProgress;
  final int weeklyCompletedTreatments;
  final int weeklyTotalTreatments;
  
  // Overall stats data
  final int allTreatments;
  final int completedTreatments;
  final int acceptedTreatments;
  final int rejectedTreatments;
  final int remainingTreatments;

  TreatmentLoaded({
    required this.weeklyProgress,
    required this.weeklyCompletedTreatments,
    required this.weeklyTotalTreatments,
    required this.allTreatments,
    required this.completedTreatments,
    required this.acceptedTreatments,
    required this.rejectedTreatments,
    required this.remainingTreatments,
  });
}

class TreatmentError extends TreatmentState {
  final String message;
  TreatmentError(this.message);
}

// Combined BLoC for Treatment Progress and Stats
class TreatmentBloc extends Bloc<TreatmentEvent, TreatmentState> {
  StreamSubscription<QuerySnapshot>? _treatmentStreamSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  TreatmentBloc() : super(TreatmentInitial()) {
    on<FetchTreatmentData>(_onFetchTreatmentData);
    on<StartTreatmentStream>(_onStartTreatmentStream);
    on<StopTreatmentStream>(_onStopTreatmentStream);
  }

  @override
  Future<void> close() {
    _treatmentStreamSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchTreatmentData(
      FetchTreatmentData event, Emitter<TreatmentState> emit) async {
    emit(TreatmentLoading());
    
    try {
      final treatmentData = await _fetchAllTreatmentData();
      if (treatmentData != null) {
        emit(treatmentData);
      } else {
        emit(TreatmentError('Unable to load treatment data'));
      }
    } catch (e) {
      log('Error fetching treatment data: $e');
      emit(TreatmentError('Error: $e'));
    }
  }

  Future<void> _onStartTreatmentStream(
      StartTreatmentStream event, Emitter<TreatmentState> emit) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      emit(TreatmentError('User not authenticated'));
      return;
    }

    // Cancel any existing stream
    await _treatmentStreamSubscription?.cancel();

    // Start a new stream on the userTreatments collection
    _treatmentStreamSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .snapshots()
        .listen((snapshot) async {
      // When the stream updates, fetch the complete treatment data
      final treatmentData = await _fetchAllTreatmentData();
      if (treatmentData != null) {
        emit(treatmentData);
      }
    }, onError: (error) {
      log('Treatment stream error: $error');
      emit(TreatmentError('Stream error: $error'));
    });
  }

  Future<void> _onStopTreatmentStream(
      StopTreatmentStream event, Emitter<TreatmentState> emit) async {
    await _treatmentStreamSubscription?.cancel();
    _treatmentStreamSubscription = null;
  }

  Future<TreatmentLoaded?> _fetchAllTreatmentData() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      return null;
    }

    // Fetch ALL treatments from Firestore
    final allTreatmentsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .get();

    // Calculate weekly date range (last 7 days)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final endDate =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    // Process all treatments for overall stats
    int allTreatments = allTreatmentsSnapshot.docs.length;
    int completedTreatments = 0;
    int rejectedTreatments = 0;
    int pendingTreatments = 0;
    
    // Track weekly treatments separately
    int weeklyTotalTreatments = 0;
    int weeklyCompletedTreatments = 0;

    // Process each treatment document
    for (var doc in allTreatmentsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final date = (data['date'] as Timestamp?)?.toDate();

      // Count for overall stats
      if (status == 'completed') {
        completedTreatments++;
      } else if (status == 'rejected') {
        rejectedTreatments++;
      } else if (status == 'pending') {
        pendingTreatments++;
      }

      // Additional counting for weekly stats
      if (date != null && date.isAfter(startDate) && date.isBefore(endDate)) {
        weeklyTotalTreatments++;
        if (status == 'completed') {
          weeklyCompletedTreatments++;
        }
      }
    }

    // Calculate accepted treatments as all treatments except rejected and pending
    int acceptedTreatments = allTreatments - rejectedTreatments - pendingTreatments;
    
    // Calculate remaining treatments: all treatments except rejected and completed
    int remainingTreatments = allTreatments - rejectedTreatments - completedTreatments;
    // Make sure we don't display negative numbers
    remainingTreatments = remainingTreatments < 0 ? 0 : remainingTreatments;

    // Safely calculate weekly progress (ensures value is between 0.0 and 1.0)
    double weeklyProgress = (weeklyTotalTreatments > 0)
        ? (weeklyCompletedTreatments / weeklyTotalTreatments).clamp(0.0, 1.0)
        : 0.0;
    if (weeklyProgress.isNaN) {
      weeklyProgress = 0.0;
    }
    
    return TreatmentLoaded(
      weeklyProgress: weeklyProgress,
      weeklyCompletedTreatments: weeklyCompletedTreatments,
      weeklyTotalTreatments: weeklyTotalTreatments,
      allTreatments: allTreatments,
      completedTreatments: completedTreatments,
      acceptedTreatments: acceptedTreatments,
      rejectedTreatments: rejectedTreatments,
      remainingTreatments: remainingTreatments,
    );
  }
}