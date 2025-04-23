part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class FetchDashboard extends DashboardEvent {
  final bool forceRefresh;
  FetchDashboard({this.forceRefresh = false});
}

class ExportDashboard extends DashboardEvent {
  final GlobalKey boundrykey;
  ExportDashboard(this.boundrykey);
}