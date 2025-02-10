import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Profile/Screens/view_profile_screen.dart';
import '../../registration/screens/registration_screen.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
class LoginView extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocProvider(
        create: (context) => LoginBloc(context),
        child: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ViewProfileScreen()));
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
              child: Padding(
                padding: EdgeInsets.all(16.0),
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
                    SizedBox(height: 32),
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
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    TextButton(
                      onPressed: () {
                        // Send the event with the current email value
                        context.read<LoginBloc>().add(
                          LoginButtonPressed(
                            email: _emailController.text,
                            password: _passwordController.text,
                          )
                        );
                        context.read<LoginBloc>().add(ForgotPasswordPressed());
                      },
                      child: const Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                    SizedBox(height: 16),
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
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state is LoginLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'تسجيل دخول',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationScreen()));
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
            );
          },
        ),
      ),
    );
  }
}
