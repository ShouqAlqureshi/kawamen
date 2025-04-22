import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class InitialHomeState extends HomeState {}

class UserDataInitialized extends HomeState {}

class LoadingHomeState extends HomeState {}

class TreatmentHistoryLoaded extends HomeState {
  final List<TreatmentData> treatments;

  const TreatmentHistoryLoaded(this.treatments);

  @override
  List<Object> get props => [treatments];
}

class ErrorHomeState extends HomeState {
  final String message;

  const ErrorHomeState(this.message);

  @override
  List<Object> get props => [message];
}

class TreatmentData extends Equatable {
  final String userTreatmentId;
  final String treatmentId;
  final String emotion;
  final double progress;
  final String status;
  final DateTime? completedAt;
  final DateTime date;
  final DateTime updatedAt;

  const TreatmentData({
    required this.userTreatmentId,
    required this.treatmentId,
    required this.emotion,
    required this.progress,
    required this.status,
    this.completedAt,
    required this.date,
    required this.updatedAt,
  });

  factory TreatmentData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parseFirestoreDate(dynamic date) {
      if (date == null) {
        log(date);
        return DateTime.now();
      }
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      throw Exception('Invalid date format: $date');
    }

    try {
      return TreatmentData(
        userTreatmentId: doc.id,
        treatmentId: data['treatmentId'] ?? '',
        emotion: data['emotion'] ?? '',
        progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
        status: data['status'] ?? '',
        completedAt: data['completedAt'] != null
            ? parseFirestoreDate(data['completedAt'])
            : null,
        date: parseFirestoreDate(data['date']),
        updatedAt: parseFirestoreDate(data['updatedAt']),
      );
    } catch (e) {
      log('Error parsing treatment data: $e');
      log('Data: $data');
      rethrow;
    }
  }
  @override
  List<Object?> get props => [
        userTreatmentId,
        treatmentId,
        emotion,
        progress,
        status,
        completedAt,
        date,
        updatedAt,
      ];
}
