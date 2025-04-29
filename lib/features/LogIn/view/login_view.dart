import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/MainNavigator.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import '../../Profile/Screens/edit_profile_screen.dart';
import '../../Reset Password/bloc/bloc/screen/reset_password_screen.dart';
import '../../registration/screens/registration_screen.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../../Profile/bloc/profile_bloc.dart';
import '../../Profile/repository/profile_repository.dart'; // Import to access validation method

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  int? _focusedField; // Track which field is focused (0 = email, 1 = password)
  bool _isFormValid = false;

  // Map to store validation errors
  final Map<String, String> _errors = {
    'email': '',
    'password': '',
  };

  // Track which fields have been touched by the user
  final Map<String, bool> _fieldTouched = {
    'email': false,
    'password': false,
  };

  @override
  void initState() {
    super.initState();
    // Initialize touched state
    _fieldTouched['email'] = false;
    _fieldTouched['password'] = false;

    // Add listeners to track changes
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Password validation function
  bool _validatePassword() {
    // Only show error if the field has been touched
    if (!_fieldTouched['password']!) {
      _errors['password'] = '';
      return true; // Return true to not affect form validity until touched
    }

    if (_passwordController.text.trim().isEmpty) {
      _errors['password'] = 'كلمة المرور مطلوبة';
      return false;
    } else {
      _errors['password'] = '';
      return true;
    }
  }

// Email validation function
  bool _validateEmail() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    // Only show error if the field has been touched
    if (!_fieldTouched['email']!) {
      _errors['email'] = '';
      return true; // Return true to not affect form validity until touched
    }

    if (_emailController.text.trim().isEmpty) {
      _errors['email'] = 'البريد الالكتروني مطلوب';
      return false;
    } else if (!emailRegex.hasMatch(_emailController.text)) {
      _errors['email'] = 'أدخل عنوان بريد إلكتروني صالح';
      return false;
    } else {
      _errors['email'] = '';
      return true;
    }
  }

  // Combined validation for the form
  // Combined validation for the form
  void _validateForm() {
    setState(() {
      // Only consider the form valid if both fields have content
      bool isEmailValid = _validateEmail();
      bool isPasswordValid = _validatePassword();
      bool hasEmailContent = _emailController.text.trim().isNotEmpty;
      bool hasPasswordContent = _passwordController.text.trim().isNotEmpty;

      // Form is valid only when both fields have content AND pass validation
      _isFormValid = isEmailValid &&
          isPasswordValid &&
          hasEmailContent &&
          hasPasswordContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Clear focus when tapping outside text fields
        setState(() => _focusedField = null);
        FocusScope.of(context).unfocus();
      },
      child: ThemedScaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => LoginBloc(),
            ),
            BlocProvider(
              create: (context) => ProfileBloc(context: context),
            ),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<LoginBloc, LoginState>(
                listener: (context, state) {
                  if (state is LoginSuccessState) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigator()),
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
              ),
              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileNeedsReauth) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                                initialUserInfo: const <String, dynamic>{},
                                onProfileUpdated: () {
                                  context
                                      .read<ProfileBloc>()
                                      .add(FetchUserInfo());
                                },
                              )),
                    );
                  }
                },
              ),
            ],
            child: BlocBuilder<LoginBloc, LoginState>(
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
                                'تسجيل دخول',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 32),
                              _buildFormField(
                                controller: _emailController,
                                label: 'البريد الالكتروني',
                                icon: Icons.email_outlined,
                                fieldId: 0,
                                errorText: _errors['email'],
                                inputFormatters: [
                                  // Prevent spaces in email field
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResetPasswordPage(
                                        onReauthenticationRequired:
                                            (context) {},
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: (state is LoginLoading ||
                                        !_isFormValid)
                                    ? null
                                    : () {
                                        context.read<LoginBloc>().add(
                                              LoginButtonPressed(
                                                email: _emailController.text,
                                                password:
                                                    _passwordController.text,
                                              ),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFormValid
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.5),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: state is LoginLoading
                                    ? const SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: LoadingScreen(),
                                        ),
                                      )
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
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // New method for building form fields with focus styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int fieldId,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bool isFocused = _focusedField == fieldId;
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.7)
              : isFocused
                  ? theme.colorScheme.primary.withOpacity(0.7)
                  : Colors.transparent,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _focusedField = hasFocus ? fieldId : _focusedField;

                // Mark field as touched when focus is lost
                if (!hasFocus) {
                  _fieldTouched['email'] = true; // For email field
                  _validateForm();
                }
              });
            },
            child: TextField(
              controller: controller,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: label,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  icon,
                  color: hasError ? Colors.red : Colors.grey,
                ),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
              child: Text(
                errorText,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  // Special method for password field to include visibility toggle
  Widget _buildPasswordField() {
    final bool isFocused = _focusedField == 1;
    final bool hasError =
        _errors['password'] != null && _errors['password']!.isNotEmpty;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.7)
              : isFocused
                  ? theme.colorScheme.primary.withOpacity(0.7)
                  : Colors.transparent,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _focusedField = hasFocus ? 1 : _focusedField;

                // Mark field as touched when focus is lost
                if (!hasFocus) {
                  _fieldTouched['password'] = true;
                  _validateForm();
                }
              });
            },
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: hasError ? Colors.red : Colors.grey,
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
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
              child: Text(
                _errors['password']!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}
