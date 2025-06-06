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

  // Overall stats data (now also last 7 days)
  final int allTreatments;
  final int completedTreatments;
  final int acceptedTreatments;
  final int rejectedTreatments;
  final int remainingTreatments;

  // Timestamp for cache validation
  final DateTime lastFetched;

  TreatmentLoaded({
    required this.weeklyProgress,
    required this.weeklyCompletedTreatments,
    required this.weeklyTotalTreatments,
    required this.allTreatments,
    required this.completedTreatments,
    required this.acceptedTreatments,
    required this.rejectedTreatments,
    required this.remainingTreatments,
    DateTime? lastFetched,
  }) : this.lastFetched = lastFetched ?? DateTime.now();
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

  // Cache related properties
  TreatmentLoaded? _cachedData;
  final Duration _cacheLifetime =
      const Duration(minutes: 5); // Cache lifetime of 5 minutes

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

  // Check if cache is valid
  bool _isCacheValid() {
    if (_cachedData == null) {
      return false;
    }

    final DateTime now = DateTime.now();
    final DateTime cacheExpiry = _cachedData!.lastFetched.add(_cacheLifetime);

    return now.isBefore(cacheExpiry);
  }

  Future<void> _onFetchTreatmentData(
      FetchTreatmentData event, Emitter<TreatmentState> emit) async {
    // First emit loading state if we don't have cached data
    if (state is! TreatmentLoaded) {
      emit(TreatmentLoading());
    }

    try {
      // Use cache if it's valid and we're not forcing a refresh
      if (!event.forceRefresh && _isCacheValid()) {
        log('Using cached treatment data');
        emit(_cachedData!);
        return;
      }

      // If we're here, we need to fetch fresh data
      log('Fetching fresh treatment data from Firestore');
      final treatmentData = await _fetchAllTreatmentData();

      if (treatmentData != null) {
        // Update cache
        _cachedData = treatmentData;
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

    // Calculate the start date (7 days ago)
    final DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    final Timestamp startTimestamp = Timestamp.fromDate(startDate);

    // Cancel any existing stream
    await _treatmentStreamSubscription?.cancel();

    // Start a new stream on the userTreatments collection
    // Only listen to treatments from the last 7 days
    _treatmentStreamSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .snapshots()
        .listen((snapshot) async {
      // When the stream updates, invalidate cache and fetch fresh data
      _cachedData = null;
      final treatmentData = await _fetchAllTreatmentData();
      if (treatmentData != null) {
        _cachedData = treatmentData;
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

    // Calculate the start date (7 days ago)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final Timestamp startTimestamp = Timestamp.fromDate(startDate);

    // Only fetch treatments from the last 7 days
    final treatmentsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .get();

    // Process treatments for the 7-day period
    int allTreatments = treatmentsSnapshot.docs.length;
    int completedTreatments = 0;
    int rejectedTreatments = 0;
    int pendingTreatments = 0;
    int weeklyCompletedTreatments = 0;

    // Process each treatment document
    for (var doc in treatmentsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';

      // Count for stats
      if (status == 'completed') {
        completedTreatments++;
        weeklyCompletedTreatments++;
      } else if (status == 'rejected') {
        rejectedTreatments++;
      } else if (status == 'pending') {
        pendingTreatments++;
      }
    }

    // Calculate accepted treatments as all treatments except rejected and pending
    int acceptedTreatments =
        allTreatments - rejectedTreatments - pendingTreatments;

    // Calculate remaining treatments: all treatments except rejected and completed
    int remainingTreatments =
        allTreatments - rejectedTreatments - completedTreatments;
    // Make sure we don't display negative numbers
    remainingTreatments = remainingTreatments < 0 ? 0 : remainingTreatments;

    // Safely calculate weekly progress (ensures value is between 0.0 and 1.0)
    double weeklyProgress = (allTreatments > 0)
        ? (weeklyCompletedTreatments / allTreatments).clamp(0.0, 1.0)
        : 0.0;
    if (weeklyProgress.isNaN) {
      weeklyProgress = 0.0;
    }

    // Create the treatment data with current timestamp
    return TreatmentLoaded(
      weeklyProgress: weeklyProgress,
      weeklyCompletedTreatments: weeklyCompletedTreatments,
      weeklyTotalTreatments: allTreatments,
      allTreatments: allTreatments,
      completedTreatments: completedTreatments,
      acceptedTreatments: acceptedTreatments,
      rejectedTreatments: rejectedTreatments,
      remainingTreatments: remainingTreatments,
      lastFetched: DateTime.now(),
    );
  }
}
