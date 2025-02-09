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
          "تعديل معلومات الحساب",
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
                labelText: 'الاسم',
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
                  return 'الاسم مطلوب';
                }
                if (value.startsWith(' ')) {
                  return 'لا يمكن أن يبدأ الاسم بمسافات';
                }
                return null;
              },
            ),
            TextFormField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'البريد الالكتروني',
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
                  return 'البريد الالكتروني مطلوب';
                }
                if (value.startsWith(' ')) {
                  return 'البريد الإلكتروني لا يمكن أن يبدأ بمسافات';
                }
                if (!value.contains('@')) {
                  return 'أدخل عنوان بريد إلكتروني صالح';
                }
                return null;
              },
            ),
            TextFormField(
              controller: ageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'العمر',
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
                  return 'العمر مطلوب';
                }
                int? age = int.tryParse(value);
                if (age == null || age <= 0 || age > 150) {
                  return 'أدخل عمر صالح';
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
              child: const Text('حفظ التغييرات'),
            ),
            ListTile(
              title: const Center(
                child: Text(
                  'حذف الحساب',
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
