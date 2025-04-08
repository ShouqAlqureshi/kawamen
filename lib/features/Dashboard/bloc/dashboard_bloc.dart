import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<FetchDashboard>((event, emit) {
      _onFetchDashboard;
    });
  }
Future<void> _onFetchDashboard(
    FetchDashboard event, Emitter<DashboardState> emit) async {
  emit(DashboardLoading()); // Emit loading state
  
  try {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      emit(DashboardError('User not authenticated'));
      return;
    }
    
    // Initialize maps to store emotion counts by day
    final Map<int, int> angerEmotions = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final Map<int, int> sadEmotions = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    
    // Calculate the date for the start of the current week (Sunday)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    // Get the end date (7 days after start date)
    final endDate = startDate.add(const Duration(days: 7));
    
    // Fetch emotions from the current week
    final emotionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emotionalData')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate)
        .get();
    
    if (emotionsSnapshot.docs.isEmpty) {
      // If no data, still return initialized maps with zeros
      emit(DashboardLoaded(angerEmotions, sadEmotions));
      return;
    }
    
    // Process each emotion document
    for (var doc in emotionsSnapshot.docs) {
      final data = doc.data();
      final emotion = data['emotion'] as String?;
      final timestamp = data['date'] as Timestamp?;
      
      if (emotion != null && timestamp != null) {
        // Get the day of the week (1-7, where 1 is Monday and 7 is Sunday in Dart)
        // Adjust to match your UI's day numbering if needed
        final dayOfWeek = timestamp.toDate().weekday;
        
        // Categorize emotions
        if (emotion.toLowerCase() == 'anger' || emotion.toLowerCase() == 'angry') {
          angerEmotions[dayOfWeek] = (angerEmotions[dayOfWeek] ?? 0) + 1;
        } else if (emotion.toLowerCase() == 'sad' || emotion.toLowerCase() == 'sadness') {
          sadEmotions[dayOfWeek] = (sadEmotions[dayOfWeek] ?? 0) + 1;
        }
        // Add more emotion types as needed
      }
    }
    
    emit(DashboardLoaded(angerEmotions, sadEmotions));
  } catch (e) {
    emit(DashboardError('Error fetching emotion data: $e'));
  }
}
}
