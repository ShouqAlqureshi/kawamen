import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> initialUserInfo;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.initialUserInfo,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController ageController;
  bool isLoading = false;
  bool isdeleteLoading = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.initialUserInfo['name']);
    emailController =
        TextEditingController(text: widget.initialUserInfo['email']);
    ageController = TextEditingController(text: widget.initialUserInfo['age']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // Function to update user info in Firestore
  Future<void> updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore
            .instance //this might change depending on the registration saving method
            .collection('Usersinfo')
            .doc(userId)
            .update({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'age': ageController.text.trim(),
        });

        widget.onProfileUpdated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }

    setState(() => isLoading = false);
  }

  // Function to delete user Account in Firestore
  Future<void> deleteAccount() async {
    setState(() => isdeleteLoading = true);

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      final String? userId = user?.uid;

      if (userId == null) {
        throw Exception("User is not authenticated or UID is null.");
      }

      // Delete the user's document from Firestore
      await FirebaseFirestore.instance
          .collection('Usersinfo')
          .doc(userId)
          .delete();

      // Delete the user from Firebase Authentication
      await user?.delete();

      // Check if the widget is still mounted before showing a SnackBar or navigating
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );

        //  navigate to a RegisterPage after deletion
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => RegisterPage(),
        //   ),
        // );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isdeleteLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                maxLength: 30,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.startsWith(' ')) {
                    return 'Name cannot start with spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (value.startsWith(' ')) {
                    return 'Email cannot start with spaces';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                maxLength: 5,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  int? age = int.tryParse(value);
                  if (age == null || age <= 0 || age > 150) {
                    return 'Enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: isLoading ? null : updateUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 48, 48, 48),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 100),
              // OutlinedButton(
              //   onPressed: isdeleteLoading ? null : deleteAccount,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: const Color.fromARGB(255, 48, 48, 48),
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //   ),
              //   child: isdeleteLoading
              //       ? const CircularProgressIndicator(color: Colors.white)
              //       : const Text(
              //           'Delete Account',
              //           style: TextStyle(fontSize: 16, color: Colors.red),
              //         ),
              // ),
              ListTile(
                title: Center(
                  child: isdeleteLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Delete Account',
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 246, 20, 4)),
                        ),
                ),
                tileColor: const Color.fromARGB(255, 48, 48, 48),
                onTap: isdeleteLoading ? null : deleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
