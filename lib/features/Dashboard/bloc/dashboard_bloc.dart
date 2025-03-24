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

    // Simulate a 2-second delay
    await Future.delayed(Duration(seconds: 2));

    // Emit the loaded state with sample data
    emit(DashboardLoaded({1: 3, 2: 1, 3: 0, 4: 0, 5: 2, 6: 6, 7: 8},
        {1: 0, 2: 4, 3: 3, 4: 2, 5: 6, 6: 1, 7: 4}));
  }
//   Future<void> _onFetchDashboardInfo(
//     FetchDashboard event,
//     Emitter emit,
//   ) async {
//     emit(DashboardLoading());
//     try {
//       final String? userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId != null) {
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userId)
//             .get();

//         if (userDoc.exists) {
//           final userData = userDoc.data() as Map<String, dynamic>;
// // git data in two map as day:count and pass it to the state
//           emit(DashboardLoaded(<int, int>{}, <int, int>{}));
//         }
//       }
//     } catch (e) {
//       emit(DashboardError('Error fetching emotion detection info: $e'));
//     }
//   }
}
