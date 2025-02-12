import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/LogIn/view/login_page.dart';
import 'package:kawamen/features/Profile/repository/profile_repository.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/screen/reset_password_screen.dart';
import '../../Reset Password/bloc/bloc/reset_password_bloc.dart';
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
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('سوف يعاد توجيهك لاعادة توثيق الدخول لحسابك'),
                backgroundColor: Colors.green,
              ),
            );
            final credential = await Navigator.of(context).push<UserCredential>(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );

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
                  'الرجاء اثبات البريد الالكتروني  '
                  '${state.email}: من خلال الرابط المرسل للبريد الالكتروني ',
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
          if (state is AccountDeleted) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حذف الحساب بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          }
          if (state is ProfileUpdated) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث معلومات الحساب بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            onProfileUpdated();
            Navigator.pop(context, true);
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
              const SizedBox(height: 100),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ResetPasswordPage(
                              onReauthenticationRequired: (context) async {
                                // Navigate to sign in page and wait for result
                                final credential = await Navigator.of(context)
                                    .push<UserCredential>(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );

                                // If we got credentials back, complete the reset password flow
                                if (credential != null) {
                                  context.read<ResetPasswordBloc>().add(
                                        ResetPasswordReauthenticationComplete(
                                            credential),
                                      );
                                }
                              },
                            ),
                          ),
                        );
                      },
                      child: Text(
                        " تعيين الرقم السري ",
                        style: Theme.of(context).textTheme.bodyLarge,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () async {
                        final shouldDelete =
                            await showdeleteaccountDialog(context);
                        if (shouldDelete) {
                          context.read<ProfileBloc>().add(DeleteAccount());
                        }
                      },
                      child: const Text(
                        'حذف الحساب',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 246, 20, 4)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
