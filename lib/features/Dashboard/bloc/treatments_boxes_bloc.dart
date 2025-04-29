import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Treatment Stats Event/State
abstract class TreatmentStatsEvent {}

class FetchTreatmentStats extends TreatmentStatsEvent {
  final bool forceRefresh;
  FetchTreatmentStats({this.forceRefresh = false});
}

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
  final DateTime lastUpdated;

  TreatmentStatsLoaded({
    required this.allTreatments,
    required this.completedTreatments,
    required this.acceptedTreatments,
    required this.rejectedTreatments,
    required this.lastUpdated,
  });

  // Convert to a map for caching
  Map<String, dynamic> toJson() {
    return {
      'allTreatments': allTreatments,
      'completedTreatments': completedTreatments,
      'acceptedTreatments': acceptedTreatments,
      'rejectedTreatments': rejectedTreatments,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from a cached map
  factory TreatmentStatsLoaded.fromJson(Map<String, dynamic> json) {
    return TreatmentStatsLoaded(
      allTreatments: json['allTreatments'],
      completedTreatments: json['completedTreatments'],
      acceptedTreatments: json['acceptedTreatments'],
      rejectedTreatments: json['rejectedTreatments'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

// BLoC for Treatment Stats
class TreatmentStatsBloc
    extends Bloc<TreatmentStatsEvent, TreatmentStatsState> {
  // Cache expiration time (in minutes)
  final int cacheExpirationMinutes = 15;

  TreatmentStatsBloc() : super(TreatmentStatsInitial()) {
    on<FetchTreatmentStats>(_onFetchTreatmentStats);
  }

  Future<void> _onFetchTreatmentStats(
      FetchTreatmentStats event, Emitter<TreatmentStatsState> emit) async {
    // Start with loading state
    emit(TreatmentStatsLoading());

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(TreatmentStatsError('User not authenticated'));
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

      // Fetch ALL treatments from Firestore without date filtering
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments')
          .get();

      int allTreatments = treatmentsSnapshot.docs.length;
      int completedTreatments = 0;
      int rejectedTreatments = 0;
      int acceptedTreatments = 0;
      int pendingTreatments = 0;

      // Process each treatment document
      for (var doc in treatmentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        if (status == 'completed') {
          completedTreatments++;
        } else if (status == 'rejected') {
          rejectedTreatments++;
        } else if (status == 'pending') {
          pendingTreatments++;
        }
      }

      // Calculate accepted treatments as all treatments except rejected and pending
      acceptedTreatments =
          allTreatments - rejectedTreatments - pendingTreatments;
      // Create the loaded state with current timestamp
      final loadedState = TreatmentStatsLoaded(
        allTreatments: allTreatments,
        completedTreatments: completedTreatments,
        acceptedTreatments: acceptedTreatments,
        rejectedTreatments: rejectedTreatments,
        lastUpdated: DateTime.now(),
      );

      // Cache the data
      await _cacheData(userId, loadedState);

      // Emit the loaded state
      emit(loadedState);
    } catch (e) {
      emit(TreatmentStatsError('Error fetching treatment stats: $e'));
    }
  }

  // Cache the treatment stats data
  Future<void> _cacheData(String userId, TreatmentStatsLoaded data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data.toJson());
      await prefs.setString('treatment_stats_$userId', jsonData);
    } catch (e) {
      // Silently fail on cache errors (non-critical)
      print('Cache error: $e');
    }
  }

  // Get cached treatment stats data if valid
  Future<TreatmentStatsLoaded?> _getCachedData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('treatment_stats_$userId');

      if (jsonString == null) {
        return null;
      }

      final data = TreatmentStatsLoaded.fromJson(jsonDecode(jsonString));

      // Check if cache is expired
      final now = DateTime.now();
      final cacheAge = now.difference(data.lastUpdated).inMinutes;

      if (cacheAge > cacheExpirationMinutes) {
        return null; // Cache expired
      }

      return data;
    } catch (e) {
      // Return null on any error reading cache
      print('Cache read error: $e');
      return null;
    }
  }
}
