import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/bloc/CBT_therapy_bloc.dart';
import 'package:kawamen/features/Treatment/deep_breathing/bloc/deep_breathing_bloc.dart';
import 'package:intl/intl.dart';

class CBTRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CBTRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
        // Get the current user ID, throw exception if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    return user.uid;
  }
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

      print('User treatment tracking updated: $treatmentId, status: ${status.value}, userTreatmentId: $documentId');
      return documentId; // Return the ID so it can be used for resuming
    } catch (e) {
      print('Error updating user treatment tracking: $e');
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
      print('Error getting user treatment: $e');
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
      print('Error getting latest user treatment: $e');
      return null;
    }
  }

  // Fetch treatment details including steps
  Future<Map<String, dynamic>> fetchTreatmentDetails(String treatmentId) async {
    try {
      // Get treatment document
      final treatmentDoc =
          await _firestore.collection('treatments ').doc(treatmentId).get();

      if (!treatmentDoc.exists) {
        throw Exception('Treatment not found');
      }

      final treatmentData = treatmentDoc.data()!;

      // Get treatment steps
      final stepsSnapshot = await _firestore
          .collection('treatments ')
          .doc(treatmentId)
          .collection('steps')
          .orderBy('stepNumber')
          .get();

      final steps = stepsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'stepNumber': data['stepNumber'],
          'instruction': data['instruction'],
          'mediaURL': data['mediaURL'],
        };
      }).toList();

      // Get cognitive distortions (assuming they're stored as a subcollection or field)
      List<String> cognitiveDistortions =
          treatmentData['cognitiveDistortions'] != null
              ? List<String>.from(treatmentData['cognitiveDistortions'])
              : [];

      return {
        'id': treatmentDoc.id,
        'name': treatmentData['name'],
        'description': treatmentData['description'],
        'type': treatmentData['type'],
        'steps': steps,
        'cognitiveDistortions': cognitiveDistortions,
      };
    } catch (e) {
      throw Exception('Failed to fetch treatment: $e');
    }
  }

  // Fetch instructions for CBT exercise
  Future<List<String>> fetchInstructions(String treatmentId) async {
  try {
    print('Fetching instructions for treatmentId: $treatmentId');
    
    final treatmentDoc = await _firestore
        .collection('treatments ').doc(treatmentId).get();
    
    print('Treatment document exists: ${treatmentDoc.exists}');
    
    final stepsSnapshot = await _firestore
        .collection('treatments ') 
        .doc(treatmentId)
        .collection('steps')
        .orderBy('stepNumber')
        .get();
    
    print('Found ${stepsSnapshot.docs.length} steps');
    
    if (stepsSnapshot.docs.isEmpty) {
      print('No steps found for this treatment');
      return [];
    }
    
    List<String> instructions = [];
    for (var doc in stepsSnapshot.docs) {
      final data = doc.data();
      print('Step data: $data');
      if (data.containsKey('instruction')) {
        instructions.add(data['instruction'] as String);
      } else {
        print('Warning: Missing instruction field in step ${doc.id}');
      }
    }
    
    print('Parsed ${instructions.length} instructions');
    return instructions;
  } catch (e) {
    print('Error fetching instructions: $e');
    throw Exception('Failed to fetch instructions: $e');
  }
}

  // Fetch cognitive distortions
 // Direct method to fetch cognitive distortions from the specified path
Future<Map<String, bool>> fetchCognitiveDistortions() async {
  try {
    print('Attempting to fetch cognitive distortions directly from the specified path');
    
    // Also try with space
    final treatmentsSpaceSnapshot = await _firestore.collection('treatments ').get();
    print('Found ${treatmentsSpaceSnapshot.docs.length} treatments (with space)');
    
    for (var doc in treatmentsSpaceSnapshot.docs) {
      print('Found treatment (with space): ${doc.id}');
    }
    
    // Try to get the CBTtherapy document specifically
    final therapyDoc = await _firestore.collection('treatments ').doc('CBTtherapy').get();
    print('CBTtherapy document exists: ${therapyDoc.exists}');
    
    if (therapyDoc.exists) {
      // Check if cognitive distortions are stored as a field rather than a subcollection
      final therapyData = therapyDoc.data() as Map<String, dynamic>?;
      
      if (therapyData != null && therapyData.containsKey('cognitiveDistortions')) {
        print('Found cognitive distortions as a field in CBTtherapy document');
        
        // Handle different possible formats
        final distortions = <String, bool>{};
        final distortionsData = therapyData['cognitiveDistortions'];
        
        if (distortionsData is List) {
          // If it's a list of strings
          for (var item in distortionsData) {
            if (item is String) {
              distortions[item] = false;
            }
          }
        } else if (distortionsData is Map) {
          // If it's a map
          distortionsData.forEach((key, value) {
            if (key is String) {
              distortions[key] = value is bool ? value : false;
            }
          });
        }
        
        if (distortions.isNotEmpty) {
          print('Successfully processed ${distortions.length} distortions from field');
          return distortions;
        }
      }
    }
    
    // If we couldn't find them as a field, try the subcollection approach
    final distortionsCollectionSnapshot = await _firestore
        .collection('treatments ')
        .doc('CBTtherapy')
        .collection('cognitiveDistortions')
        .get();
        
    print('Subcollection exists: ${distortionsCollectionSnapshot.metadata != null}');
    print('Found ${distortionsCollectionSnapshot.docs.length} documents in subcollection');
    
    if (distortionsCollectionSnapshot.docs.isNotEmpty) {
      final distortions = <String, bool>{};
      
      for (var doc in distortionsCollectionSnapshot.docs) {
        final data = doc.data();
        print('Document data: $data');
        
        if (data.containsKey('name') && data['name'] != null) {
          distortions[data['name'] as String] = false;
        }
      }
      
      if (distortions.isNotEmpty) {
        print('Successfully processed ${distortions.length} distortions from subcollection');
        return distortions;
      }
    }
    
    // If all attempts fail, use default distortions
    print('No distortions found in any locations, using default distortions');
    return _getDefaultCognitiveDistortions();
  } catch (e) {
    print('Error fetching cognitive distortions: $e');
    return _getDefaultCognitiveDistortions();
  }
}

// Separate method for default distortions to keep code clean
Map<String, bool> _getDefaultCognitiveDistortions() {
  return {
    'التفكير الثنائي ( شيء أو لا شيء)': false,
    'التعميم المفرط': false,
    'التصفية العقلية (التركيز على السلبيات)': false,
    'القفز إلى الاستنتاجات': false,
    'التهويل أو التقليل': false,
    'الاستدلال العاطفي': false,
    'العبارات الإلزامية (يجب، ينبغي)': false,
    'التسمية الخاطئة': false,
    'لوم الذات أو الآخرين': false,
  };
}
}
