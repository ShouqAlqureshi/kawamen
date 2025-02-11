import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/registration/screens/registration_screen.dart';
import '../../Profile/Screens/view_profile_screen.dart';
import '../../Reset Password/bloc/bloc/screen/reset_password_screen.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginView extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme background color
      body: BlocProvider(
        create: (context) => LoginBloc(),
        child: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccessState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ViewProfileScreen()),
              );
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor:
                      state.error.contains('reset') ? Colors.green : Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'تسجيل دخول',
                        style: Theme.of(context).textTheme.headlineMedium, // Use theme text style
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 32),
                      // Email Text Field with card-like style
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'البريد الالكتروني',
                          filled: true,
                          fillColor: Theme.of(context).cardColor, // Match the card color
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), // Match the card border radius
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                      // Password Text Field with card-like style
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          filled: true,
                          fillColor: Theme.of(context).cardColor, // Match the card color
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), // Match the card border radius
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResetPasswordPage(
                                onReauthenticationRequired: (context) {
                                  // Handle reauthentication if needed
                                },
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state is LoginLoading
                            ? null
                            : () {
                                context.read<LoginBloc>().add(
                                      LoginButtonPressed(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      ),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary, // Use theme secondary color
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state is LoginLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'تسجيل دخول',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegistrationScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'قم بإنشاء حساب',
                              style: TextStyle(color: Colors.purple),
                            ),
                          ),
                          const Text(
                            'لا تمتلك حساب؟',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
