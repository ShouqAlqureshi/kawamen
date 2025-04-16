import 'dart:async';
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
part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<FetchDashboard>(_onFetchDashboard);
    on<ExportDashboard>(_onExportDashboard);
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
      final startDate = DateTime(now.year, now.month, now.day - daysToSubtract);

      // Debug log
      print(
          'Fetching emotions from: ${startDate.toIso8601String()} to current date');

      // Get the end date (7 days after start date)
      final endDate = startDate.add(const Duration(days: 7));

      // Fetch emotions from Firestore for the current week
      final emotionsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotionalData')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate);

      final emotionsSnapshot = await emotionsQuery.get();

      // Debug log
      print('Found ${emotionsSnapshot.docs.length} emotion records');

      if (emotionsSnapshot.docs.isEmpty) {
        print('No emotion data found for the current week');
        emit(DashboardLoaded(angerEmotions, sadEmotions));
        return;
      }

      // Process each emotion document
      for (var doc in emotionsSnapshot.docs) {
        final data = doc.data();
        String? emotion;
        DateTime? date;

        // Handle different possible date formats
        if (data.containsKey('emotion')) {
          emotion = data['emotion'] as String?;
        }

        // Handle different possible date formats in Firestore
        if (data.containsKey('date')) {
          final dateField = data['date'];
          if (dateField is Timestamp) {
            date = dateField.toDate();
          } else if (dateField is String) {
            // Try to parse date from string
            try {
              date = DateTime.parse(dateField);
            } catch (e) {
              print('Failed to parse date string: $dateField');
            }
          }
        }

        // Debug log
        print('Processing emotion: $emotion, date: $date');

        if (emotion != null && date != null) {
          // Get the day of the week (1-7, where 1 is Monday and 7 is Sunday in Dart)
          final dayOfWeek = date.weekday;

          // Debug log
          print('Day of week: $dayOfWeek, Emotion: $emotion');

          // Categorize emotions - be more flexible with emotion names
          if (emotion.toLowerCase().contains('ang')) {
            angerEmotions[dayOfWeek] = (angerEmotions[dayOfWeek] ?? 0) + 1;
            print('Incremented anger for day $dayOfWeek');
          } else if (emotion.toLowerCase().contains('sad')) {
            sadEmotions[dayOfWeek] = (sadEmotions[dayOfWeek] ?? 0) + 1;
            print('Incremented sadness for day $dayOfWeek');
          }
        } else {
          print('Skipping document due to missing emotion or date: ${doc.id}');
        }
      }

      // Debug log final emotions count
      print('Final anger counts: $angerEmotions');
      print('Final sadness counts: $sadEmotions');

      emit(DashboardLoaded(angerEmotions, sadEmotions));
    } catch (e, stackTrace) {
      print('Error in dashboard data fetching: $e');
      print('Stack trace: $stackTrace');
      emit(DashboardError('Error fetching emotion data: $e'));
    }
  }

  Future<void> _onExportDashboard(
      ExportDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardExporting());

    final Uint8List? imageBytes = await _captureWidget(event.boundrykey);

    if (imageBytes != null) {
      try {
        // Get temporary directory to save the file temporarily
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';

        // Save the image temporarily
        final File tempFile = File(tempPath);
        await tempFile.writeAsBytes(imageBytes);

        // Share the image
        await Share.shareXFiles(
          [XFile(tempPath)],
          text: 'Check out my Emotional Dashboard for this week!',
        );

        // Delete the temporary file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        emit(DashboardExported());
      } catch (e) {
        log(e.toString());
        emit(DashboardError(e.toString()));
      }
    }
  }

// Function to capture the widget as an image
  Future<Uint8List?> _captureWidget(GlobalKey boundaryKey) async {
    try {
      final RenderRepaintBoundary boundary = boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture the widget as an image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

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

      final Uint8List? pngBytes = byteData?.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      log(e.toString());
      log('Error capturing widget: $e');
      return null;
    }
  }
}
