part of 'dashboard_bloc.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<int, int> sadEmotionalData; // map of day :count
  final Map<int, int> angerEmotionalData;
  bool get isEmpty {
  return angerEmotionalData.isEmpty && sadEmotionalData.isEmpty ||
      (angerEmotionalData.values.every((value) => value == 0) &&
      (sadEmotionalData.values.every((value) => value == 0)));
}

  DashboardLoaded(this.angerEmotionalData, this.sadEmotionalData);
}

class DashboardLoading extends DashboardState {}



class DashboardError extends DashboardState {
  final String massage;

  DashboardError(this.massage);
}
