
// Listen for email verification globally
  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void listenForEmailVerification() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null && user.emailVerified) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'email': user.email,
        });
        print('Email updated in Firestore after verification');
      }
    });
  }