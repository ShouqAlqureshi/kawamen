import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/LogIn/view/login_page.dart';
import '../Bloc/profile_bloc.dart';

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
      create: (context) => ProfileBloc(context: context),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) async {
          if (state is ProfileNeedsReauth) {
            final credential = await Navigator.of(context).push<UserCredential>(
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
            // Ensure user actually reauthenticated before proceeding
            if (credential != null) {
              if (!context.mounted) return;
              context
                  .read<ProfileBloc>()
                  .add(ReauthenticationComplete(credential));
            }
          }

          if (state is ProfileNeedsVerification) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please verify your new email address. '
                  'A verification link has been sent to ${state.email}',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }

          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state is ProfileUpdated) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: _EditProfileScreenContent(
          initialUserInfo: initialUserInfo,
          onProfileUpdated: onProfileUpdated,
        ),
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
    final nameController =
        TextEditingController(text: initialUserInfo['fullName'] as String);
    final emailController =
        TextEditingController(text: initialUserInfo['email'] as String);
    final ageController =
        TextEditingController(text: initialUserInfo['age'].toString());

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.black, Color(0xFF3E206D)],
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "تعديل معلومات الحساب",
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.right,
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
              const SizedBox(height: 40),
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
              const SizedBox(height: 40),
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
              const SizedBox(height: 180),
              OutlinedButton(
                onPressed: () {
                  context.read<ProfileBloc>().add(DeleteAccount());
                  // Navigate to login or register screen after deletion
                },
                child: const Text(
                  'حذف الحساب',
                  style: TextStyle(
                      fontSize: 16, color: Color.fromARGB(255, 246, 20, 4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
