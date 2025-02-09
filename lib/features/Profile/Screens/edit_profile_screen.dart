import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_bloc.dart';

class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic> initialUserInfo;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.initialUserInfo,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(),
      child: _EditProfileScreenContent(
        initialUserInfo: initialUserInfo,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }
}

class _EditProfileScreenContent extends StatelessWidget {
  final Map<String, dynamic> initialUserInfo;
  final VoidCallback onProfileUpdated;

  const _EditProfileScreenContent({
    required this.initialUserInfo,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: initialUserInfo['fullName']);
    final emailController =
        TextEditingController(text: initialUserInfo['email']);
    final ageController = TextEditingController(text: initialUserInfo['age']);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            OutlinedButton(
              onPressed: () {
                context.read<ProfileBloc>().add(UpdateUserInfo(
                      name: nameController.text,
                      email: emailController.text,
                      age: ageController.text,
                    ));
                onProfileUpdated();
              },
              child: const Text('Save Changes'),
            ),
            ListTile(
              title: const Center(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                      fontSize: 16, color: Color.fromARGB(255, 246, 20, 4)),
                ),
              ),
              onTap: () {
                context.read<ProfileBloc>().add(DeleteAccount());
                // Navigate to login or register screen after deletion
              },
            ),
          ],
        ),
      ),
    );
  }
}
