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
      appBar: AppBar(title: const Text('Reset Password')),
      body: BlocListener<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) {
          if (state.status == ResetPasswordStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset email sent successfully!'),
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
                content: Text(state.errorMessage ?? 'An error occurred'),
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
                'Enter your email address to reset your password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
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
                      : const Text('Reset Password'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}