part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class FetchDashboard extends DashboardEvent {}

class ExportDashboard extends DashboardEvent {
    GlobalKey boundrykey;
  ExportDashboard(this.boundrykey);
}