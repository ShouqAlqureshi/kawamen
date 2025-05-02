import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  // Cache expiration time (in minutes)
  final int cacheExpirationMinutes = 15;

  DashboardBloc() : super(DashboardInitial()) {
    on<FetchDashboard>(_onFetchDashboard);
    // when a user clicks the share button, we only capture once and store the bytes
    // When sharing from the preview dialog, we use the already captured bytes without trying to re-capture
    on<CaptureScreenshot>(_onCaptureScreenshot);
    on<PreviewScreenshot>(_onPreviewScreenshot);
    on<ShareScreenshot>(_onShareScreenshot);
  }

  Future<void> _onFetchDashboard(
      FetchDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading()); // Emit loading state

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(UsernNotAuthenticated());
        return;
      }

      // Check cache first if not forcing refresh
      if (!event.forceRefresh) {
        final cachedData = await _getCachedData(userId);
        if (cachedData != null) {
          emit(cachedData);
          return;
        }
      }

      // Initialize maps to store emotion counts by day (1=Monday, 7=Sunday in Dart)
      final Map<int, int> angerEmotions = {
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 0
      };
      final Map<int, int> sadEmotions = {
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 0
      };

      // Calculate start date (beginning of current week - Sunday)
      final now = DateTime.now();
      final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
      final startDate = DateTime(now.year, now.month, now.day - daysToSubtract)
          .subtract(const Duration(seconds: 1)); // Start from Sunday 23:59:59
      final endDate = startDate
          .add(const Duration(days: 7, seconds: 1)); // End next Sunday 00:00:01

      // Convert to Firestore Timestamps for proper comparison
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      log('Fetching emotions from: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Query using Firestore Timestamp field for proper date comparison
      final emotionsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotionalData')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThan: endTimestamp);

      final emotionsSnapshot = await emotionsQuery.get();

      log('Total emotion records found: ${emotionsSnapshot.docs.length}');

      if (emotionsSnapshot.docs.isEmpty) {
        log('No emotion data found for the current week');
        final loadedState = DashboardLoaded(angerEmotions, sadEmotions);
        await _setCacheData(userId, loadedState);
        emit(loadedState);
        return;
      }

      // Process each emotion document
      for (var doc in emotionsSnapshot.docs) {
        final data = doc.data();
        String? emotion;
        DateTime? date;

        // Get the emotion
        if (data.containsKey('emotion')) {
          emotion = data['emotion'] as String?;
          log('Found emotion: $emotion');
        }

        // Get the timestamp (handle both Firestore Timestamp and String formats)
        if (data.containsKey('timestamp') && data['timestamp'] is Timestamp) {
          // Preferred: Use the Firestore Timestamp object
          final timestamp = data['timestamp'] as Timestamp;
          date = timestamp.toDate();
          log('Using Firestore Timestamp: ${date.toString()}');
        } else if (data.containsKey('timestamp') &&
            data['timestamp'] is String) {
          // Fallback: Parse from string format if needed
          final timestampStr = data['timestamp'] as String;
          log('Falling back to string timestamp: $timestampStr');

          try {
            date = DateTime.parse(timestampStr);
            log('Successfully parsed timestamp string to: ${date.toString()}');
          } catch (e) {
            log('Failed to parse timestamp string: $e');
          }
        }

        if (emotion != null && date != null) {
          // Get the day of the week (1-7, where 1 is Monday and 7 is Sunday in Dart)
          final dayOfWeek = date.weekday;

          log('Processing entry: Day of week: $dayOfWeek, Emotion: $emotion');

          // Categorize emotions
          if ((emotion.toLowerCase() == 'angry')) {
            angerEmotions[dayOfWeek] = (angerEmotions[dayOfWeek] ?? 0) + 1;
            log('Incremented anger for day $dayOfWeek');
          } else if ((emotion.toLowerCase() == 'sad')) {
            sadEmotions[dayOfWeek] = (sadEmotions[dayOfWeek] ?? 0) + 1;
            log('Incremented sadness for day $dayOfWeek');
          }
        } else {
          log('Skipping document due to missing emotion or date: ${doc.id}');
          if (emotion == null) log('Emotion is null');
          if (date == null) log('Date is null');
        }
      }

      // Debug log final emotions count
      log('Final anger counts: $angerEmotions');
      log('Final sadness counts: $sadEmotions');

      final loadedState = DashboardLoaded(angerEmotions, sadEmotions);
      await _setCacheData(userId, loadedState);
      emit(loadedState);
    } catch (e, stackTrace) {
      log('Error in dashboard data fetching: $e');
      log('Stack trace: $stackTrace');
      emit(DashboardError('Error fetching emotion data: $e'));
    }
  }

  Future<void> _onCaptureScreenshot(
      CaptureScreenshot event, Emitter<DashboardState> emit) async {
    log('Capturing screenshot started');

    try {
      final imageBytes = await _captureWidget(event.boundaryKey);

      if (imageBytes == null) {
        log('Failed to capture widget image');
        emit(DashboardError('Failed to capture dashboard image'));
        return;
      }

      // If preview requested, show preview
      if (event.showPreview) {
        add(PreviewScreenshot(imageBytes));
      } else {
        // Otherwise share directly
        add(ShareScreenshot(imageBytes));
      }
    } catch (e, stackTrace) {
      log('Error capturing screenshot: $e');
      log('Stack trace: $stackTrace');
      emit(DashboardError('Error capturing dashboard: $e'));
    }
  }

  //pass imageBytes to ui
  Future<void> _onPreviewScreenshot(
      PreviewScreenshot event, Emitter<DashboardState> emit) async {
    log('Previewing screenshot');
    emit(DashboardPreviewReady(event.imageBytes));
  }

  Future<void> _onShareScreenshot(
      ShareScreenshot event, Emitter<DashboardState> emit) async {
    log('Sharing screenshot started');
    emit(DashboardExporting(event.imageBytes));

    try {
      // Get temporary directory to save the file temporarily
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save the image temporarily
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(event.imageBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'اطّلع على لوحة المشاعر الخاصة بي لهذا الأسبوع!',
      );

      // Delete the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      emit(DashboardExported());
    } catch (e, stackTrace) {
      log('Error sharing image: $e');
      log('Stack trace: $stackTrace');
      emit(DashboardError('Error sharing dashboard: $e'));
    }
  }

  // Function to capture the widget as an image
// Replace this method in your DashboardBloc class
  Future<Uint8List?> _captureWidget(GlobalKey boundaryKey) async {
    try {
      log('Starting widget capture...');

      // Wait longer to ensure widget is properly built and fully rendered
      await Future.delayed(const Duration(milliseconds: 800));

      // First check if the boundary key has a context and is mounted
      final BuildContext? context = boundaryKey.currentContext;
      if (context == null) {
        log('RepaintBoundary not found in the widget tree');
        return null;
      }

      // Check if the render object is a RepaintBoundary
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        log('RenderRepaintBoundary not found for the given key');
        return null;
      }

      final RenderRepaintBoundary boundary = renderObject;

      log('Capturing image with pixel ratio 3.0');
      // Capture the widget as an image with higher pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      log('Image captured successfully: ${image.width}x${image.height}');

      // Create a new image with a gradient background
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Define the gradient
      final Rect rect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      const Gradient gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color.fromARGB(255, 30, 12, 48),
          ui.Color.fromARGB(255, 0, 0, 0),
        ],
      );

      // Apply the gradient as a shader to the paint
      final Paint paint = Paint()..shader = gradient.createShader(rect);

      // Draw the gradient background
      canvas.drawRect(rect, paint);

      // Draw the captured widget image on top of the gradient background
      canvas.drawImage(image, Offset.zero, Paint());

      // Convert the final image to bytes
      final ui.Image finalImage = await recorder.endRecording().toImage(
            image.width,
            image.height,
          );

      final ByteData? byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        log('Failed to convert image to byte data');
        return null;
      }

      log('Image capture completed successfully');
      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      log('Error capturing widget: $e');
      log('Stack trace: $stackTrace');
      return null;
    }
  }

  // Cache the dashboard data
  Future<void> _setCacheData(String userId, DashboardLoaded data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert maps to a format that can be stored in SharedPreferences
      final Map<String, dynamic> cacheData = {
        'angerEmotionalData': data.angerEmotionalData
            .map((key, value) => MapEntry(key.toString(), value)),
        'sadEmotionalData': data.sadEmotionalData
            .map((key, value) => MapEntry(key.toString(), value)),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(cacheData);
      await prefs.setString('dashboard_data_$userId', jsonData);
    } catch (e) {
      // Silently fail on cache errors (non-critical)
      log('Cache error: $e');
    }
  }

  // Get cached dashboard data if valid
  Future<DashboardLoaded?> _getCachedData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('dashboard_data_$userId');

      if (jsonString == null) {
        return null;
      }

      final Map<String, dynamic> decodedData = jsonDecode(jsonString);

      // Check if cache is expired
      final lastUpdated = DateTime.parse(decodedData['lastUpdated']);
      final now = DateTime.now();
      final cacheAge = now.difference(lastUpdated).inMinutes;

      if (cacheAge > cacheExpirationMinutes) {
        return null; // Cache expired
      }

      // Convert the stored data back to the required format
      final Map<int, int> angerEmotionalData = Map<int, int>.from(
          decodedData['angerEmotionalData']
              .map((key, value) => MapEntry(int.parse(key), value)));

      final Map<int, int> sadEmotionalData = Map<int, int>.from(
          decodedData['sadEmotionalData']
              .map((key, value) => MapEntry(int.parse(key), value)));

      return DashboardLoaded(angerEmotionalData, sadEmotionalData);
    } catch (e) {
      // Return null on any error reading cache
      log('Cache read error: $e');
      return null;
    }
  }
}
