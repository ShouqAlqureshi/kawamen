import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kawamen/features/Treatment/deep_breathing/bloc/deep_breathing_bloc.dart';

// Treatment repository
class TreatmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TreatmentRepository() {
    // Call it immediately when repository is created
    listAllTreatmentDocuments();
  }
  // Get the current user ID, throw exception if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    return user.uid;
  }

 // Track user's treatment status
Future<String> trackUserTreatment({
  required String treatmentId,
  required TreatmentStatus status,
  String? emotionFeedback,
  double progress = 0.0,
  String? userTreatmentId, // Add optional parameter to support updating specific treatment
}) async {
  try {
    final userId = _getCurrentUserId();
    final collectionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments');
    
    // Get current timestamp
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    String documentId;
    
    if (userTreatmentId != null) {
      // Update existing specific treatment instance by ID
      documentId = userTreatmentId;
      final docRef = collectionRef.doc(userTreatmentId);
      
      final updateData = <String, dynamic>{
        'status': status.value,
        'progress': progress,
        'updatedAt': formattedDate,
      };

      // Add completedAt timestamp if treatment is completed
      if (status == TreatmentStatus.completed) {
        updateData['completedAt'] = formattedDate;
      }

      // Add emotion if provided and not already set
      final doc = await docRef.get();
      if (emotionFeedback != null && !doc.data()!.containsKey('emotion')) {
        updateData['emotion'] = emotionFeedback;
      }

      await docRef.update(updateData);
    } else {
      // Query for existing treatments with this treatmentId that are not completed
      final querySnapshot = await collectionRef
          .where('treatmentId', isEqualTo: treatmentId)
          .where('status', whereIn: [
            TreatmentStatus.started.value, 
            TreatmentStatus.inProgress.value
          ])
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create new treatment instance with auto-generated ID
        final newDocRef = await collectionRef.add({
          'treatmentId': treatmentId,
          'date': formattedDate,
          'status': status.value,
          'progress': progress,
          'updatedAt': formattedDate,
          'emotion': emotionFeedback, // Save emotion when creating document
        });
        
        // Update the document to include its own ID
        documentId = newDocRef.id;
        await newDocRef.update({'userTreatmentId': documentId});
      } else {
        // Update existing treatment instance
        final docRef = querySnapshot.docs.first.reference;
        documentId = querySnapshot.docs.first.id;
        
        final updateData = <String, dynamic>{
          'status': status.value,
          'progress': progress,
          'updatedAt': formattedDate,
          'userTreatmentId': documentId, // Ensure ID is set
        };

        // Add emotion if not already set (only on first save)
        if (emotionFeedback != null && !querySnapshot.docs.first.data().containsKey('emotion')) {
          updateData['emotion'] = emotionFeedback;
        }

        // Add completedAt timestamp if treatment is completed
        if (status == TreatmentStatus.completed) {
          updateData['completedAt'] = formattedDate;
        }

        await docRef.update(updateData);
      }
    }

    developer.log(
        'User treatment tracking updated: $treatmentId, status: ${status.value}, userTreatmentId: $documentId');
    return documentId; // Return the ID so it can be used for resuming
  } catch (e) {
    developer.log('Error updating user treatment tracking: $e');
    throw Exception('Failed to update treatment tracking: $e');
  }
}

// New method to get a specific user treatment by ID
Future<Map<String, dynamic>?> getUserTreatmentById(String userTreatmentId) async {
  try {
    final userId = _getCurrentUserId();
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .doc(userTreatmentId);
    
    final doc = await docRef.get();
    if (!doc.exists) {
      return null;
    }
    
    return doc.data();
  } catch (e) {
    developer.log('Error getting user treatment: $e');
    return null;
  }
}

// New method to get user's latest treatment for a specific treatment type
Future<Map<String, dynamic>?> getLatestUserTreatment(String treatmentId) async {
  try {
    final userId = _getCurrentUserId();
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .where('treatmentId', isEqualTo: treatmentId)
        .where('status', whereIn: [
          TreatmentStatus.started.value, 
          TreatmentStatus.inProgress.value
        ])
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      return null;
    }
    
    return querySnapshot.docs.first.data();
  } catch (e) {
    developer.log('Error getting latest user treatment: $e');
    return null;
  }
}

  Future<Treatment> getTreatmentWithSteps(String treatmentId) async {
    try {
      // Fetch the treatment document
      final treatmentDoc =
          await _firestore.collection('treatments ').doc(treatmentId).get();
      // Add some debugging
      developer.log("Looking for document with ID: $treatmentId");
      developer.log("Document exists: ${treatmentDoc.exists}");

      if (!treatmentDoc.exists) {
        throw Exception("المستند غير موجود. تحقق من المعرّف");
      }

      final treatment = Treatment.fromFirestore(treatmentDoc);

      // Fetch the steps subcollection
      final stepsSnapshot = await _firestore
          .collection('treatments ')
          .doc(treatmentId)
          .collection('steps')
          .orderBy('stepNumber')
          .get();

      if (stepsSnapshot.docs.isEmpty) {
        throw Exception("لا توجد خطوات لهذا التمرين");
      }

      final steps = stepsSnapshot.docs
          .map((doc) => TreatmentStep.fromMap(doc.data()))
          .toList();

      // Return the treatment with steps
      return Treatment(
        id: treatment.id,
        name: treatment.name,
        description: treatment.description,
        type: treatment.type,
        steps: steps,
      );
    } catch (e) {
      // Print error to the console for debugging
      developer.log("فشل تحميل التمرين: $e");
      throw Exception("فشل تحميل التمرين: ${e.toString()}");
    }
  }

  Future<void> listAllTreatmentDocuments() async {
    try {
      final querySnapshot = await _firestore.collection('treatments ').get();
      developer.log("Found ${querySnapshot.docs.length} treatment documents");

      for (var doc in querySnapshot.docs) {
        developer.log("Document ID: '${doc.id}'");
        // Print each character's code point to detect any hidden characters
        for (int i = 0; i < doc.id.length; i++) {
          developer
              .log("Character ${i}: '${doc.id[i]}' (${doc.id.codeUnitAt(i)})");
        }
      }
    } catch (e) {
      developer.log("Error listing documents: $e");
    }
  }
}
