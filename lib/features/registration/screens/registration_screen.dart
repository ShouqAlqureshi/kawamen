import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/MainNavigator.dart';
import 'package:kawamen/features/LogIn/view/login_view.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controllers for the input fields.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();

  // Whether the user has agreed to the terms.
  bool agreeToTerms = false;

  // Error messages for each field. Null means no error.
  String? _nameError;
  String? _emailError;
  String? _ageError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Control the visibility of the password fields.
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.error, style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("تم التسجيل بنجاح!",
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainNavigator()),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'حساب جديد',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 32),
                        // Name Field
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'الاسم الكامل',
                            errorText: _nameError,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        // Email Field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'البريد الإلكتروني',
                            errorText: _emailError,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        // Age Field
                        TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'العمر',
                            errorText: _ageError,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            hintText: 'كلمة المرور',
                            errorText: _passwordError,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'تأكيد كلمة المرور',
                            errorText: _confirmPasswordError,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible = !_confirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        // Terms & Conditions Checkbox
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                "من خلال إنشاء حساب، فإنك توافق على الشروط والأحكام الخاصة بنا",
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Checkbox(
                              value: agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  agreeToTerms = value!;
                                });
                              },
                              activeColor: Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Registration Button
                        ElevatedButton(
                          onPressed: (agreeToTerms && state is! AuthLoading)
                              ? _registerUser
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: LoadingScreen(),
                                  ),
                                )
                              : const Text(
                                  'إنشاء حساب',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Added Text to route to Login Page
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginView(),
                                  ),
                                );
                              },
                              child: const Text(
                                'تسجيل دخول',
                                style: TextStyle(color: Colors.purple),
                              ),
                            ),
                            const Text(
                              'لديك حساب بالفعل؟',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handles user registration after validating the input fields.
  void _registerUser() {
    String? localNameError;
    String? localEmailError;
    String? localAgeError;
    String? localPasswordError;
    String? localConfirmPasswordError;
    bool hasError = false;

    // Validate full name.
    if (nameController.text.trim().isEmpty) {
      localNameError = "الرجاء إدخال الاسم الكامل";
      hasError = true;
    }

    // Validate email using a simple regex.
    String email = emailController.text.trim();
    RegExp emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(email)) {
      localEmailError = "البريد الإلكتروني غير صالح";
      hasError = true;
    }

    // Validate age.
    int? age = int.tryParse(ageController.text.trim());
    if (age == null || age <= 0) {
      localAgeError = "يرجى إدخال عمر صالح";
      hasError = true;
    }

    // Validate password strength (minimum 6 characters).
    String password = passwordController.text;
    if (password.isEmpty || password.length < 6) {
      localPasswordError = "كلمة المرور ضعيفة، يجب أن تكون على الأقل 6 أحرف";
      hasError = true;
    }

    // Validate password confirmation.
    if (password != confirmPasswordController.text) {
      localConfirmPasswordError = "كلمة المرور وتأكيدها غير متطابقين";
      hasError = true;
    }

    // Update state with errors.
    setState(() {
      _nameError = localNameError;
      _emailError = localEmailError;
      _ageError = localAgeError;
      _passwordError = localPasswordError;
      _confirmPasswordError = localConfirmPasswordError;
    });

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("يرجى تصحيح الحقول المشار إليها باللون الأحمر"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Trigger registration if validation passes.
    context.read<AuthBloc>().add(RegisterUser(
          fullName: nameController.text.trim(),
          email: email,
          password: password,
          age: age!,
        ));
  }
}