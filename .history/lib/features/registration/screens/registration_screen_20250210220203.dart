import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
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
  final TextEditingController ageController = TextEditingController();
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.error,
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red),
              );
            } else if (state is AuthSuccess) {
              // ✅ Show success Snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("تم التسجيل بنجاح!",
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green,
                ),
              );

              // ✅ Navigate to Profile Screen after 1 second
              Future.delayed(Duration(seconds: 1), () {
                Navigator.pushReplacementNamed(context, AppRoutes.profile);
              });
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
                  _buildTextField(ageController, "العمر", isNumber: true),
                  SizedBox(height: 16),
                  _buildTextField(passwordController, "كلمة المرور",
                      isPassword: true),
                  SizedBox(height: 16),
                  _buildTextField(
                      confirmPasswordController, "تأكيد كلمة المرور",
                      isPassword: true),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: agreeToTerms,
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
                      backgroundColor: agreeToTerms
                          ? Colors.purple
                          : Colors.grey, // ✅ Gray when unchecked
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state is AuthLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))
                        : Text("إنشاء حساب جديد",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white), // ✅ Ensure text is visible
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.grey[800], // ✅ Improved visibility
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _registerUser() {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("كلمة المرور وتأكيدها غير متطابقين"),
            backgroundColor: Colors.red),
      );
      return;
    }

    int? age = int.tryParse(ageController.text.trim());
    if (age == null || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("يرجى إدخال عمر صالح"), backgroundColor: Colors.red),
      );
      return;
    }

    context.read<AuthBloc>().add(RegisterUser(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          age: age,
        ));
  }
}
