part of 'dashboard_bloc.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<int, int> sadEmotionalData; // map of day :count
  final Map<int, int> angerEmotionalData;

  bool get isEmpty {
    return sadEmotionalData.values.every((value) => value == 0) &&
        angerEmotionalData.values.every((value) => value == 0);
  }

  DashboardLoaded(this.angerEmotionalData, this.sadEmotionalData);
}

class DashboardLoading extends DashboardState {}

class DashboardError extends DashboardState {
  final String message; // Fixed typo in variable name (was "massage")

  DashboardError(this.message);
}

class DashboardExporting extends DashboardState {}
class DashboardExported extends DashboardState {}
class UsernNotAuthenticated extends DashboardState {}