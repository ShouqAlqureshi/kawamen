part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class FetchTreatmentHistory extends HomeEvent {
  final bool forceRefresh;

  const FetchTreatmentHistory({this.forceRefresh = false});

  @override
  List<Object> get props => [forceRefresh];
}

class InitializeUserData extends HomeEvent {
  @override
  List<Object> get props => [];
}
class StartTreatmentStreamSubscription extends HomeEvent {
  @override
  List<Object> get props => [];
}

class TreatmentsUpdated extends HomeEvent {
  final List<Map<String, dynamic>> treatmentsData;

  const TreatmentsUpdated(this.treatmentsData);

  @override
  List<Object> get props => [treatmentsData];
}
