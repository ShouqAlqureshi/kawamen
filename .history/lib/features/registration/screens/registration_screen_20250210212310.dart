import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController =
      TextEditingController(); // Added Age Field
  bool agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("حساب جديد", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              print("❌ Registration Failed: ${state.error}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            } else if (state is AuthSuccess) {
              print("✅ Registration Successful! Navigating to Home...");
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(nameController, "الاسم الكامل"),
                  SizedBox(height: 16),
                  _buildTextField(emailController, "البريد الإلكتروني"),
                  SizedBox(height: 16),
                  _buildTextField(ageController, "العمر",
                      isNumber: true), // Age Field
                  SizedBox(height: 16),
                  _buildTextField(passwordController, "كلمة المرور",
                      isPassword: true),
                  SizedBox(height: 16),
                  _buildTextField(
                      confirmPasswordController, "تأكيد كلمة المرور",
                      isPassword: true),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: agreeToTerms,
                        activeColor: Colors.purple,
                        onChanged: (value) {
                          setState(() {
                            agreeToTerms = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "من خلال إنشاء حساب، فإنك توافق على الشروط والأحكام الخاصة بنا",
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: (agreeToTerms && state is! AuthLoading)
                        ? _registerUser
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          agreeToTerms ? Colors.purple : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state is AuthLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text("إنشاء حساب جديد",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white), // ✅ Fix: Make text white
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey), // ✅ Label color
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple), // ✅ Purple border
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _registerUser() {
    print("🚀 Register button clicked!");

    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final ageText = ageController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        ageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى ملء جميع الحقول")),
      );
      return;
    }

    if (password != confirmPassword) {
      print("❌ Passwords do not match!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("كلمة المرور وتأكيدها غير متطابقين")),
      );
      return;
    }

    int? age = int.tryParse(ageText);
    if (age == null || age <= 0) {
      print("❌ Invalid Age Entered: $ageText");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى إدخال عمر صالح")),
      );
      return;
    }

    print("📡 Dispatching RegisterUser event...");
    context.read<AuthBloc>().add(RegisterUser(
          fullName: fullName,
          email: email,
          password: password,
          age: age, // ✅ Ensure age is passed correctly
        ));
  }
}
