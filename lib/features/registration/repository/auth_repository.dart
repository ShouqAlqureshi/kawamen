import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawamen/features/registration/model/user_model.dart';
import '../model/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register new user with age
  Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    required int age, // ✅ Fix: Ensure age is passed
  }) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        fullName: fullName,
        email: email,
        age: age, // ✅ Fix: Ensure age is stored
      );

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }
Future<bool> isUserAuthenticated() async {
    // Check if user is logged in using Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null;
  }
  signOut() {}

  signIn({required String email, required String password}) {}
}
