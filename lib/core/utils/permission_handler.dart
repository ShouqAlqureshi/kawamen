// File: lib/core/utils/permission_handler.dart

import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  /// Requests microphone permission and returns `true` if granted
  static Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Checks if microphone permission is permanently denied
  static Future<bool> isMicPermanentlyDenied() async {
    return await Permission.microphone.isPermanentlyDenied;
  }

  /// Opens app settings to allow the user to enable permissions
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
