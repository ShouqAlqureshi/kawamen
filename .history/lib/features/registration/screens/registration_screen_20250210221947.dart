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
        title: Center(
            child: Text("حساب جديد",
                style: TextStyle(color: Colors.white))), // ✅ Title centered
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
              textDirection: TextDirection.rtl, // ✅ Arabic right alignment
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(nameController, "الاسم الكامل"),
                          SizedBox(height: 16),
                          _buildTextField(emailController, "البريد الإلكتروني"),
                          SizedBox(height: 16),
                          _buildTextField(ageController, "العمر",
                              isNumber: true),
                          SizedBox(height: 16),
                          _buildTextField(passwordController, "كلمة المرور",
                              isPassword: true),
                          SizedBox(height: 16),
                          _buildTextField(
                              confirmPasswordController, "تأكيد كلمة المرور",
                              isPassword: true),
                          SizedBox(height: 16),

                          // ✅ Terms and Conditions Checkbox
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
                        ],
                      ),
                    ),
                  ),

                  // ✅ Register Button (Centered at the bottom)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: SizedBox(
                      width: double.infinity, // ✅ Full width, looks centered
                      child: ElevatedButton(
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
                                    AlwaysStoppedAnimation<Color>(Colors.white))
                            : Text("إنشاء حساب جديد",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// ✅ **Builds a text field with improved visibility & right alignment**
  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white), // ✅ Ensures text is visible
      textAlign: TextAlign.right, // ✅ Align text to the right
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.grey[800], // ✅ Improves visibility
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  /// ✅ **Handles registration logic**
  void _registerUser() {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("كلمة المرور وتأكيدها غير متطابقين"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? age = int.tryParse(ageController.text.trim());
    if (age == null || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("يرجى إدخال عمر صالح"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dispatch RegisterUser event with all form fields
    context.read<AuthBloc>().add(RegisterUser(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          age: age,
        ));
  }
}
