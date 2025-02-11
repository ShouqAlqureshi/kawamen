import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/reset_password_bloc.dart';

class ResetPasswordPage extends StatelessWidget {
  final Function(BuildContext) onReauthenticationRequired;

  const ResetPasswordPage({
    super.key,
    required this.onReauthenticationRequired,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPasswordBloc(),
      child: ResetPasswordView(
        onReauthenticationRequired: onReauthenticationRequired,
      ),
    );
  }
}

class ResetPasswordView extends StatelessWidget {
  final Function(BuildContext) onReauthenticationRequired;

  const ResetPasswordView({
    super.key,
    required this.onReauthenticationRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            'اعادة تعيين الرقم السري',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.headlineMedium,
          )),
      body: BlocListener<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) {
          if (state.status == ResetPasswordStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'تم ارسال بريد الكتروني لاعادة تعييت الرقم السري بنجاح !'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
    
          if (state.status == ResetPasswordStatus.requiresReauth) {
            onReauthenticationRequired(context);
          }
    
          if (state.status == ResetPasswordStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'حدث خطاء '),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _ResetPasswordForm(),
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends StatefulWidget {
  @override
  State<_ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<_ResetPasswordForm> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ادخل بريدك الالكتروني المستخدم للاعادة تعيين الرقم السري',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الالكتروني',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاد ادخال البريد الالكتروني';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'ادخل البريد الالكتروني المستخدم في تسجيل الدخول ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.status == ResetPasswordStatus.submitting
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            context.read<ResetPasswordBloc>().add(
                                  ResetPasswordSubmitted(_emailController.text),
                                );
                          }
                        },
                  child: state.status == ResetPasswordStatus.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('اعادة تعيين الرقم السري'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
