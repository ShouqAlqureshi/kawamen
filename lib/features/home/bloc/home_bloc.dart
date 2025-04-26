import 'dart:async';
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

  // Stream subscription to manage and dispose properly
  StreamSubscription<List<Map<String, dynamic>>>? _treatmentsSubscription;

  HomeBloc() : super(InitialHomeState()) {
    on<FetchTreatmentHistory>(_onFetchTreatmentHistory);
    on<StartTreatmentStreamSubscription>(_onStartTreatmentStream);
    on<TreatmentsUpdated>(_onTreatmentsUpdated);

    // Auto-start stream subscription when bloc is created
    add(StartTreatmentStreamSubscription());
  }

  @override
  Future<void> close() {
    // Clean up subscription when bloc is closed
    _treatmentsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchTreatmentHistory(
    FetchTreatmentHistory event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(LoadingHomeState());

      final user = _auth.currentUser;
      if (user == null) {
        emit(UsernNotAuthenticated());
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

      treatments.sort((a, b) {
        final statusOrder = {
          'in_progress': 0,
          'paused': 1,
          'completed': 2,
        };

        final aStatus = statusOrder[a.status] ?? 2;
        final bStatus = statusOrder[b.status] ?? 2;

        if (aStatus != bStatus) {
          return aStatus.compareTo(bStatus);
        }

        return b.date.compareTo(a.date);
      });

      // We don't need to update cache manually here, as the _setupTreatmentsListener
      // in UserCacheService will handle that through the Firestore snapshot listener

      log("Treatment count: ${treatments.length}");
      emit(TreatmentHistoryLoaded(treatments));
    } catch (e) {
      emit(ErrorHomeState('Error fetching treatment history: ${e.toString()}'));
    }
  }

  // New method to handle stream subscription
  Future<void> _onStartTreatmentStream(
    StartTreatmentStreamSubscription event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(UsernNotAuthenticated());
        return;
      }

      // Cancel any existing subscription
      await _treatmentsSubscription?.cancel();

      // Calculate date range for filtering
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      // Make sure the stream is set up in the cache service
      _cacheService.setupTreatmentsListener(user.uid);

      // Start listening to treatment updates
      _treatmentsSubscription =
          _cacheService.getTreatmentsStream(user.uid).listen((treatmentsData) {
        // When new data arrives from the stream, dispatch a new event
        add(TreatmentsUpdated(treatmentsData));
      });

      // Trigger an initial load to show data immediately
      add(const FetchTreatmentHistory());
    } catch (e) {
      log('Error setting up treatment stream: ${e.toString()}');
    }
  }

  // Handle treatment updates from the stream
  void _onTreatmentsUpdated(
    TreatmentsUpdated event,
    Emitter<HomeState> emit,
  ) {
    try {
      // Calculate date range for filtering
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));

      // Convert raw data to TreatmentData objects
      final allTreatments = event.treatmentsData
          .map((doc) => TreatmentData.fromMap(doc))
          .toList();

      // Filter to last 7 days
      final filteredTreatments = allTreatments.where((treatment) {
        return treatment.date.isAfter(startDate) ||
            treatment.date.isAtSameMomentAs(startDate);
      }).toList();

      // Sort by status first (in_progress > paused > completed), then by date
      filteredTreatments.sort((a, b) {
        // Status priority: in_progress (0), paused (1), completed (2)
        final statusOrder = {
          'in_progress': 0,
          'paused': 1,
          'completed': 2,
        };

        final aStatus = statusOrder[a.status] ?? 2;
        final bStatus = statusOrder[b.status] ?? 2;

        if (aStatus != bStatus) {
          return aStatus.compareTo(bStatus);
        }

        // If status is same, sort by date (newest first)
        return b.date.compareTo(a.date);
      });

      log("Stream updated with ${filteredTreatments.length} treatments");
      emit(TreatmentHistoryLoaded(filteredTreatments));
    } catch (e) {
      log('Error processing treatment updates: ${e.toString()}');
    }
  }
}
