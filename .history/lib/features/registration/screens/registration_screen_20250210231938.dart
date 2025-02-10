import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(
            child: Text("حساب جديد", style: TextStyle(color: Colors.white))),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
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
                MaterialPageRoute(builder: (context) => ViewProfileScreen()),
              );
            }
          },
          builder: (context, state) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    _buildTextField(
                      nameController,
                      "الاسم الكامل",
                      errorText: _nameError,
                    ),
                    SizedBox(height: 16),
                    // Email Field
                    _buildTextField(
                      emailController,
                      "البريد الإلكتروني",
                      errorText: _emailError,
                    ),
                    SizedBox(height: 16),
                    // Age Field
                    _buildTextField(
                      ageController,
                      "العمر",
                      isNumber: true,
                      errorText: _ageError,
                    ),
                    SizedBox(height: 16),
                    // Password Field with toggle icon
                    _buildTextField(
                      passwordController,
                      "كلمة المرور",
                      obscureText: !_passwordVisible,
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    // Confirm Password Field with toggle icon
                    _buildTextField(
                      confirmPasswordController,
                      "تأكيد كلمة المرور",
                      obscureText: !_confirmPasswordVisible,
                      errorText: _confirmPasswordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    // Terms & Conditions Checkbox
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                agreeToTerms = value!;
                              });
                            },
                            activeColor: Colors.purple,
                          ),
                          Expanded(
                            child: Text(
                              "من خلال إنشاء حساب، فإنك توافق على الشروط والأحكام الخاصة بنا",
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    // Registration Button (centered and full width)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (agreeToTerms && state is! AuthLoading)
                            ? _registerUser
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          disabledBackgroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: state is AuthLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text("إنشاء حساب جديد",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: 30), // Extra spacing at the bottom
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds a text field with right-to-left alignment and an optional error message.
  /// The [obscureText] parameter determines if the field should hide its text.
  /// [isNumber] sets the keyboard type to number.
  /// [suffixIcon] allows you to attach a widget (like a visibility toggle) at the end of the field.
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    bool isNumber = false,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorStyle: TextStyle(color: Colors.redAccent),
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: suffixIcon,
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
