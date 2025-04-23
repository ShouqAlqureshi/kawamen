part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class FetchDashboard extends DashboardEvent {
  final bool forceRefresh;
  FetchDashboard({this.forceRefresh = false});
}

class ExportDashboard extends DashboardEvent {
  final GlobalKey boundarykey;
  final bool isPreview; // Add this flag to distinguish between preview and actual export
  
  ExportDashboard(this.boundarykey, {this.isPreview = true});
}
class ShareCapturedImage extends DashboardEvent {
  final Uint8List imageBytes;
  
  ShareCapturedImage(this.imageBytes);
}// Add these event classes to dashboard_event.dart
class CaptureScreenshot extends DashboardEvent {
  final GlobalKey boundaryKey;
  final bool showPreview;
  
  CaptureScreenshot(this.boundaryKey, {this.showPreview = true});
}

class PreviewScreenshot extends DashboardEvent {
  final Uint8List imageBytes;
  
  PreviewScreenshot(this.imageBytes);
}

class ShareScreenshot extends DashboardEvent {
  final Uint8List imageBytes;
  
  ShareScreenshot(this.imageBytes);
}