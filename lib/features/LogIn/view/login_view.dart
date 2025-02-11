import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Profile/Screens/view_profile_screen.dart';
import '../../Reset Password/bloc/bloc/screen/reset_password_screen.dart';
import '../../registration/screens/registration_screen.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocProvider(
        create: (context) => LoginBloc(),
        child: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccessState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              );
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: state.error.contains('reset')
                      ? Colors.green
                      : Colors.red,
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
                      const Text(
                        'تسجيل دخول',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'البريد الالكتروني',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible 
                                ? Icons.visibility_off
                                : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
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
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state is LoginLoading
                            ? const CircularProgressIndicator(color: Colors.white)
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
                                  builder: (_) => const RegistrationScreen(),
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
