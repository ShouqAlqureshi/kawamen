import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawamen/features/home/bloc/home_state.dart';

part 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      log("is treatmet fetched empty :${treatments.isEmpty}");
      emit(TreatmentHistoryLoaded(treatments));
    } catch (e) {
      emit(ErrorHomeState('Error fetching treatment history: ${e.toString()}'));
    }
  }
}
