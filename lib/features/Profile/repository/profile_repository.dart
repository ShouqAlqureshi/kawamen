// Listen for email verification globally
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// fetch for any changes related to user id in auth table
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

Future<bool> showdeleteaccountDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context)
            .dialogBackgroundColor, // Set dialog background to white
        title: const Text(
          textAlign: TextAlign.right,
          'حذف الحساب ',
          style: TextStyle(color: Colors.white), // Set title text color
        ),
        content: const Text(
          textAlign: TextAlign.right,
          'هل انت متاكد من حذف حسابك نهائيا ؟',
          style: TextStyle(color: Colors.white), // Set content text color
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // No
            child: const Text(
              'الغاء',
              style: TextStyle(
                  color: Colors.white), // Customize button color if desired
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Yes
            child: const Text(
              textAlign: TextAlign.right,
              'نعم، احذف الحساب نهائيا ',
              style:
                  TextStyle(color: Colors.red), // Set log out button text color
            ),
          ),
        ],
      );
    },
  ).then((value) => value ?? false); // Ensure it returns false if dismissed
}
