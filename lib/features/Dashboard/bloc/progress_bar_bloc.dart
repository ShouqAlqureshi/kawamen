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

  TreatmentProgressLoaded(this.progress, this.completedTreatments, this.totalTreatments);
}

class TreatmentProgressError extends TreatmentProgressState {
  final String message;

  TreatmentProgressError(this.message);
}

// BLoC for Treatment Progress
class TreatmentProgressBloc extends Bloc<TreatmentProgressEvent, TreatmentProgressState> {
  TreatmentProgressBloc() : super(TreatmentProgressInitial()) {
    on<FetchTreatmentProgress>(_onFetchTreatmentProgress);
  }

  Future<void> _onFetchTreatmentProgress(
      FetchTreatmentProgress event, Emitter<TreatmentProgressState> emit) async {
    emit(TreatmentProgressLoading());
    
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(TreatmentProgressError('User not authenticated'));
        return;
      }
      
      // Print user ID to confirm it's correct
      print('Fetching data for user ID: $userId');
      
      // Get ALL treatments regardless of date to confirm data exists
      final allTreatmentsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments');
          
      final allTreatmentsSnapshot = await allTreatmentsQuery.get();
      print('Total treatments in database: ${allTreatmentsSnapshot.docs.length}');
      
      // Print first few documents to check their structure
      if (allTreatmentsSnapshot.docs.isNotEmpty) {
        print('Sample document data:');
        final sampleDoc = allTreatmentsSnapshot.docs.first.data();
        print(sampleDoc);
        
        // Check the date field type and value
        if (sampleDoc.containsKey('date')) {
          final dateField = sampleDoc['date'];
          print('Date field type: ${dateField.runtimeType}');
          print('Date value: $dateField');
          
          if (dateField is Timestamp) {
            // Convert to DateTime for comparison
            final dateTime = dateField.toDate();
            print('Converted to DateTime: $dateTime');
          }
        } else {
          print('Warning: No date field found in document!');
        }
      }
      
      // Calculate start date (beginning of current week - Sunday)
      final now = DateTime.now();
      final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
      final startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
      
      // Get the end date (7 days after start date)
      final endDate = startDate.add(const Duration(days: 7));
      
      // Debug log dates
      print('Current date: ${now.toIso8601String()}');
      print('Start date for query: ${startDate.toIso8601String()}');
      print('End date for query: ${endDate.toIso8601String()}');

      // Fetch treatments from Firestore for the current week
      final treatmentsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate);
          
      final treatmentsSnapshot = await treatmentsQuery.get();
      
      // Debug log
      print('Found ${treatmentsSnapshot.docs.length} treatment records for current week');
      
      if (treatmentsSnapshot.docs.isEmpty) {
        print('No treatment data found for the current week');
        
        // Check every document's date to see if it's within range
        if (allTreatmentsSnapshot.docs.isNotEmpty) {
          print('Checking all documents for date range issues:');
          for (var doc in allTreatmentsSnapshot.docs) {
            final data = doc.data();
            if (data.containsKey('date')) {
              final dateField = data['date'];
              if (dateField is Timestamp) {
                final dateTime = dateField.toDate();
                print('Doc ID: ${doc.id}, Date: $dateTime, In range: ${dateTime.isAfter(startDate) && dateTime.isBefore(endDate)}');
              } else {
                print('Doc ID: ${doc.id}, Date is not a Timestamp: ${dateField.runtimeType}');
              }
            } else {
              print('Doc ID: ${doc.id}, No date field found');
            }
          }
        }
        
        emit(TreatmentProgressLoaded(0.0, 0, 0));
        return;
      }
      
      // Count total and completed treatments
      int totalTreatments = treatmentsSnapshot.docs.length;
      int completedTreatments = 0;
      
      // Process each treatment document
      for (var doc in treatmentsSnapshot.docs) {
        final data = doc.data();
        
        // Check if treatment is completed
        if (data.containsKey('status') && data['status'] == 'completed') {
          completedTreatments++;
        }
      }
      
      // Calculate progress
      double progress = totalTreatments > 0 ? completedTreatments / totalTreatments : 0.0;
      
      // Debug log final progress
      print('Total treatments: $totalTreatments');
      print('Completed treatments: $completedTreatments');
      print('Progress: $progress');
      
      emit(TreatmentProgressLoaded(progress, completedTreatments, totalTreatments));
    } catch (e, stackTrace) {
      print('Error in treatment progress fetching: $e');
      print('Stack trace: $stackTrace');
      emit(TreatmentProgressError('Error fetching treatment data: $e'));
    }
  }
}