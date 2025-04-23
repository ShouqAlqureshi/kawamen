import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawamen/core/services/cache_service.dart';
import 'package:kawamen/features/home/bloc/home_state.dart';

part 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserCacheService _cacheService = UserCacheService();

  HomeBloc() : super(InitialHomeState()) {
    on<FetchTreatmentHistory>(_onFetchTreatmentHistory);
  }

  Future<void> _onFetchTreatmentHistory(
    FetchTreatmentHistory event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(LoadingHomeState());

      final user = _auth.currentUser;
      if (user == null) {
        emit(const ErrorHomeState('User not authenticated'));
        return;
      }

      // Calculate date range for last 7 days
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      // Try to get cached data first
      if (!event.forceRefresh) {
        final cachedTreatments = await _cacheService.getUserTreatments(
          user.uid,
          startDate: startDate,
          endDate: endDate,
        );

        if (cachedTreatments.isNotEmpty) {
          final treatments = cachedTreatments
              .map((doc) => TreatmentData.fromMap(doc))
              .toList();

          log("Using cached treatments data");
          emit(TreatmentHistoryLoaded(treatments));
          return;
        }
      }

      // If no cache or force refresh, fetch from Firestore
      log("Fetching fresh treatments data from Firestore");
      final treatmentsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userTreatments')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .get();

      final treatments = treatmentsSnapshot.docs
          .map((doc) => TreatmentData.fromFirestore(doc))
          .toList();

      // Update cache with fresh data
      await _cacheService.updateTreatmentsCache(
        user.uid,
        'treatments_${startDate.toIso8601String()}_${endDate.toIso8601String()}',
        treatmentsSnapshot.docs.map((doc) => doc.data()).toList(),
      );

      log("is treatment fetched empty: ${treatments.isEmpty}");
      emit(TreatmentHistoryLoaded(treatments));
    } catch (e) {
      emit(ErrorHomeState('Error fetching treatment history: ${e.toString()}'));
    }
  }
}
