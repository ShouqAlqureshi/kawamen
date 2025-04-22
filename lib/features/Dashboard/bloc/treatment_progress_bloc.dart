import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events for Treatment Progress BLoC
abstract class TreatmentProgressEvent {}

class FetchTreatmentProgress extends TreatmentProgressEvent {
  final bool forceRefresh;
  FetchTreatmentProgress({this.forceRefresh = false});
}

// States for Treatment Progress BLoC
abstract class TreatmentProgressState {}

class TreatmentProgressInitial extends TreatmentProgressState {}

class TreatmentProgressLoading extends TreatmentProgressState {}

class TreatmentProgressLoaded extends TreatmentProgressState {
  final double progress;
  final int completedTreatments;
  final int totalTreatments;
  final DateTime lastUpdated;

  TreatmentProgressLoaded(
    this.progress, 
    this.completedTreatments, 
    this.totalTreatments,
    this.lastUpdated,
  );

  // Convert to a map for caching
  Map<String, dynamic> toJson() {
    return {
      'progress': progress,
      'completedTreatments': completedTreatments,
      'totalTreatments': totalTreatments,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from a cached map
  factory TreatmentProgressLoaded.fromJson(Map<String, dynamic> json) {
    return TreatmentProgressLoaded(
      json['progress'],
      json['completedTreatments'],
      json['totalTreatments'],
      DateTime.parse(json['lastUpdated']),
    );
  }
}

class TreatmentProgressError extends TreatmentProgressState {
  final String message;

  TreatmentProgressError(this.message);
}

// BLoC for Treatment Progress
class TreatmentProgressBloc
    extends Bloc<TreatmentProgressEvent, TreatmentProgressState> {
  // Cache expiration time (in minutes)
  final int cacheExpirationMinutes = 15;
  
  TreatmentProgressBloc() : super(TreatmentProgressInitial()) {
    on<FetchTreatmentProgress>(_onFetchTreatmentProgress);
  }

  Future<void> _onFetchTreatmentProgress(
      FetchTreatmentProgress event,
      Emitter<TreatmentProgressState> emit) async {
    emit(TreatmentProgressLoading());

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(TreatmentProgressError('User not authenticated'));
        return;
      }

      // Check cache first if not forcing refresh
      if (!event.forceRefresh) {
        final cachedData = await _getCachedData(userId);
        if (cachedData != null) {
          emit(cachedData);
          return;
        }
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
      
      final loadedState = TreatmentProgressLoaded(
        progress, 
        completedTreatments, 
        totalTreatments,
        DateTime.now(),
      );
      
      // Cache the data
      await _cacheData(userId, loadedState);
      
      // Emit the loaded state
      emit(loadedState);
    } catch (e) {
      log('Error fetching treatment data: $e');
      emit(TreatmentProgressLoaded(0.0, 0, 0, DateTime.now())); // Safe fallback state
    }
  }
  
  // Cache the treatment progress data
  Future<void> _cacheData(String userId, TreatmentProgressLoaded data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data.toJson());
      await prefs.setString('treatment_progress_$userId', jsonData);
    } catch (e) {
      // Silently fail on cache errors (non-critical)
      log('Cache error: $e');
    }
  }

  // Get cached treatment progress data if valid
  Future<TreatmentProgressLoaded?> _getCachedData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('treatment_progress_$userId');
      
      if (jsonString == null) {
        return null;
      }

      final data = TreatmentProgressLoaded.fromJson(jsonDecode(jsonString));
      
      // Check if cache is expired
      final now = DateTime.now();
      final cacheAge = now.difference(data.lastUpdated).inMinutes;
      
      if (cacheAge > cacheExpirationMinutes) {
        return null; // Cache expired
      }
      
      return data;
    } catch (e) {
      // Return null on any error reading cache
      log('Cache read error: $e');
      return null;
    }
  }
}