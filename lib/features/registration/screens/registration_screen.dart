import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Track which field is focused
  int? focusedField;

  // Track form validity
  bool isFormValid = false;

  // Track which fields have been touched by the user
  final Map<String, bool> fieldTouched = {
    'name': false,
    'email': false,
    'age': false,
    'password': false,
    'confirmPassword': false,
  };

  // Error messages for each field
  final Map<String, String> errors = {
    'name': '',
    'email': '',
    'age': '',
    'password': '',
    'confirmPassword': '',
  };

  // Control the visibility of the password fields.
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Update listeners to validate specific fields
    nameController.addListener(() {
      if (fieldTouched['name']!) {
        setState(() {
          validateName();
          _checkFormValidity();
        });
      }
    });

    emailController.addListener(() {
      if (fieldTouched['email']!) {
        setState(() {
          validateEmail();
          _checkFormValidity();
        });
      }
    });

    ageController.addListener(() {
      if (fieldTouched['age']!) {
        setState(() {
          validateAge();
          _checkFormValidity();
        });
      }
    });

    passwordController.addListener(() {
      if (fieldTouched['password']!) {
        setState(() {
          validatePassword();
          _checkFormValidity();
        });
      }
      // Also validate confirm password if it's been touched
      if (fieldTouched['confirmPassword']!) {
        setState(() {
          validateConfirmPassword();
          _checkFormValidity();
        });
      }
    });

    confirmPasswordController.addListener(() {
      if (fieldTouched['confirmPassword']!) {
        setState(() {
          validateConfirmPassword();
          _checkFormValidity();
        });
      }
    });
  }

// Separate method to check overall form validity
  void _checkFormValidity() {
    // Check if all fields have content
    bool hasNameContent = nameController.text.trim().isNotEmpty;
    bool hasEmailContent = emailController.text.trim().isNotEmpty;
    bool hasAgeContent = ageController.text.trim().isNotEmpty;
    bool hasPasswordContent = passwordController.text.isNotEmpty;
    bool hasConfirmPasswordContent = confirmPasswordController.text.isNotEmpty;

    // Check if all validations pass
    bool isNameValid = errors['name']!.isEmpty;
    bool isEmailValid = errors['email']!.isEmpty;
    bool isAgeValid = errors['age']!.isEmpty;
    bool isPasswordValid = errors['password']!.isEmpty;
    bool isConfirmPasswordValid = errors['confirmPassword']!.isEmpty;

    // Form is valid only when all fields have content, pass validation, and terms are agreed
    isFormValid = hasNameContent &&
        hasEmailContent &&
        hasAgeContent &&
        hasPasswordContent &&
        hasConfirmPasswordContent &&
        isNameValid &&
        isEmailValid &&
        isAgeValid &&
        isPasswordValid &&
        isConfirmPasswordValid &&
        agreeToTerms;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // Validation functions
  bool validateName() {
    if (!fieldTouched['name']!) {
      errors['name'] = '';
      return true;
    }

    if (nameController.text.trim().isEmpty) {
      errors['name'] = 'الاسم مطلوب';
      return false;
    }
    errors['name'] = '';
    return true;
  }

  bool validateEmail() {
    if (!fieldTouched['email']!) {
      errors['email'] = '';
      return true;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    String email = emailController.text.trim();

    if (email.isEmpty) {
      errors['email'] = 'البريد الإلكتروني مطلوب';
      return false;
    } else if (!emailRegex.hasMatch(email)) {
      errors['email'] = 'البريد الإلكتروني غير صالح';
      return false;
    }
    errors['email'] = '';
    return true;
  }

  bool validateAge() {
    if (!fieldTouched['age']!) {
      errors['age'] = '';
      return true;
    }

    int? age = int.tryParse(ageController.text.trim());
    if (ageController.text.trim().isEmpty) {
      errors['age'] = 'العمر مطلوب';
      return false;
    } else if (age == null || age <= 0) {
      errors['age'] = 'يرجى إدخال عمر صالح';
      return false;
    } else if (age < 16) {
      errors['age'] = 'يجب أن يكون العمر 16 سنة على الأقل';
      return false;
    }
    errors['age'] = '';
    return true;
  }

  bool validatePassword() {
    if (!fieldTouched['password']!) {
      errors['password'] = '';
      return true;
    }

    String password = passwordController.text;
    if (password.isEmpty) {
      errors['password'] = 'كلمة المرور مطلوبة';
      return false;
    } else if (password.length < 6) {
      errors['password'] = 'كلمة المرور ضعيفة، يجب أن تكون على الأقل 6 أحرف';
      return false;
    }
    errors['password'] = '';
    return true;
  }

  bool validateConfirmPassword() {
    if (!fieldTouched['confirmPassword']!) {
      errors['confirmPassword'] = '';
      return true;
    }

    if (confirmPasswordController.text.isEmpty) {
      errors['confirmPassword'] = 'تأكيد كلمة المرور مطلوب';
      return false;
    } else if (passwordController.text != confirmPasswordController.text) {
      errors['confirmPassword'] = 'كلمة المرور وتأكيدها غير متطابقين';
      return false;
    }
    errors['confirmPassword'] = '';
    return true;
  }

  // Combined validation for the form
  void _validateForm() {
    setState(() {
      // Validate all fields
      validateName();
      validateEmail();
      validateAge();
      validatePassword();
      validateConfirmPassword();

      // Check if all fields have content
      bool hasNameContent = nameController.text.trim().isNotEmpty;
      bool hasEmailContent = emailController.text.trim().isNotEmpty;
      bool hasAgeContent = ageController.text.trim().isNotEmpty;
      bool hasPasswordContent = passwordController.text.isNotEmpty;
      bool hasConfirmPasswordContent =
          confirmPasswordController.text.isNotEmpty;

      // Check if all validations pass
      bool isNameValid = errors['name']!.isEmpty;
      bool isEmailValid = errors['email']!.isEmpty;
      bool isAgeValid = errors['age']!.isEmpty;
      bool isPasswordValid = errors['password']!.isEmpty;
      bool isConfirmPasswordValid = errors['confirmPassword']!.isEmpty;

      // Form is valid only when all fields have content, pass validation, and terms are agreed
      isFormValid = hasNameContent &&
          hasEmailContent &&
          hasAgeContent &&
          hasPasswordContent &&
          hasConfirmPasswordContent &&
          isNameValid &&
          isEmailValid &&
          isAgeValid &&
          isPasswordValid &&
          isConfirmPasswordValid &&
          agreeToTerms;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside text fields
        setState(() => focusedField = null);
        FocusScope.of(context).unfocus();
      },
      child: ThemedScaffold(
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
                          _buildFormField(
                            controller: nameController,
                            label: 'الاسم الكامل',
                            icon: Icons.person_outline,
                            fieldId: 0,
                            fieldKey: 'name',
                            errorText: errors['name'],
                            inputFormatters: [
                              // Prevent spaces at the beginning
                              FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildFormField(
                            controller: emailController,
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            fieldId: 1,
                            fieldKey: 'email',
                            errorText: errors['email'],
                            inputFormatters: [
                              // Prevent spaces in email
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Age Field
                          _buildFormField(
                            controller: ageController,
                            label: 'العمر',
                            icon: Icons.cake_outlined,
                            fieldId: 2,
                            fieldKey: 'age',
                            errorText: errors['age'],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          _buildPasswordField(
                            controller: passwordController,
                            label: 'كلمة المرور',
                            fieldId: 3,
                            fieldKey: 'password',
                            errorText: errors['password'],
                            isVisible: _passwordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          _buildPasswordField(
                            controller: confirmPasswordController,
                            label: 'تأكيد كلمة المرور',
                            fieldId: 4,
                            fieldKey: 'confirmPassword',
                            errorText: errors['confirmPassword'],
                            isVisible: _confirmPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              });
                            },
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
                                    _validateForm();
                                  });
                                },
                                activeColor: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Registration Button
                          ElevatedButton(
                            onPressed: (isFormValid && state is! AuthLoading)
                                ? _registerUser
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFormValid
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.5),
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

                          // Login Route
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
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int fieldId,
    required String fieldKey,
    String? errorText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bool isFocused = focusedField == fieldId;
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
                focusedField = hasFocus ? fieldId : focusedField;

                // Mark field as touched when focus is lost
                if (!hasFocus) {
                  fieldTouched[fieldKey] = true;
                  _validateForm();
                }
              });
            },
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required int fieldId,
    required String fieldKey,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? errorText,
  }) {
    final bool isFocused = focusedField == fieldId;
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
                focusedField = hasFocus ? fieldId : focusedField;

                // Mark field as touched when focus is lost
                if (!hasFocus) {
                  fieldTouched[fieldKey] = true;
                  _validateForm();
                }
              });
            },
            child: TextField(
              controller: controller,
              obscureText: !isVisible,
              decoration: InputDecoration(
                hintText: label,
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
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
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

  /// Handles user registration after validating the input fields.
  void _registerUser() {
    // All validation is already handled by the form validation
    // Just do a final check before submitting
    if (!isFormValid) {
      return;
    }

    // Trigger registration
    context.read<AuthBloc>().add(RegisterUser(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          age: int.parse(ageController.text.trim()),
        ));
  }
}
