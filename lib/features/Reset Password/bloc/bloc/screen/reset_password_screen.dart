import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: ThemedScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'اعادة تعيين الرقم السري',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        body: BlocListener<ResetPasswordBloc, ResetPasswordState>(
          listener: (context, state) {
            if (state.status == ResetPasswordStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم ارسال بريد الكتروني لاعادة تعييت الرقم السري بنجاح !',
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(10),
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
                  content: Text(state.errorMessage ?? 'حدث خطاء'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(10),
                ),
              );
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _ResetPasswordForm(),
            ),
          ),
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
  bool _isEmailValid = false;
  bool _isFocused = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();

    setState(() {
      if (email.isEmpty) {
        _emailError = 'الرجاء ادخال البريد الالكتروني';
        _isEmailValid = false;
      } else {
        // Regular expression for email validation
        final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

        if (!emailRegExp.hasMatch(email)) {
          _emailError = 'الرجاء ادخال بريد الكتروني صحيح';
          _isEmailValid = false;
        } else {
          _emailError = null;
          _isEmailValid = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            // Hide keyboard when tapping outside text fields
            FocusScope.of(context).unfocus();
            setState(() {
              _isFocused = false;
            });
          },
          child: Form(
            key: _formKey,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon with animated decoration
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.7),
                            theme.colorScheme.secondary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.secondary,
                        child: Icon(
                          Icons.lock_reset,
                          size: 40,
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Title with enhanced styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ادخل بريدك الالكتروني المستخدم للاعادة تعيين الرقم السري',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Enhanced email field with visual feedback
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _emailError != null
                                    ? theme.colorScheme.error.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Focus(
                            onFocusChange: (hasFocus) {
                              setState(() {
                                _isFocused = hasFocus;
                                if (!hasFocus) {
                                  _validateEmail();
                                }
                              });
                            },
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'البريد الالكتروني',
                                hintText: 'أدخل البريد الالكتروني هنا',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: _emailError != null
                                      ? theme.colorScheme.error
                                      : _isFocused
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.primary
                                              .withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _emailError != null
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.outline
                                            .withOpacity(0.7),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _emailError != null
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.error,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                labelStyle: TextStyle(
                                  color: _emailError != null
                                      ? theme.colorScheme.error
                                      : _isFocused
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                ),
                                // Remove default error message display since we have our own
                                errorStyle:
                                    const TextStyle(height: 0, fontSize: 0),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              validator: (_) {
                                // We're handling validation manually via _emailError
                                return null;
                              },
                            ),
                          ),
                        ),

                        // Custom error message
                        if (_emailError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 16),
                            child: Text(
                              _emailError!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Subtitle with enhanced styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ادخل البريد الالكتروني المستخدم في تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Enhanced button with active/inactive state
                    Container(
                      width: 300,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isEmailValid
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [], // No shadow when button is inactive
                      ),
                      child: ElevatedButton(
                        onPressed: (_isEmailValid &&
                                state.status != ResetPasswordStatus.submitting)
                            ? () {
                                FocusScope.of(context).unfocus();
                                context.read<ResetPasswordBloc>().add(
                                      ResetPasswordSubmitted(
                                          _emailController.text.trim()),
                                    );
                              }
                            : null, // Button disabled when email invalid or submitting
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor:
                              theme.colorScheme.primary.withOpacity(0.3),
                          disabledForegroundColor:
                              theme.colorScheme.onPrimary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: _isEmailValid
                              ? 0
                              : 0, // No elevation when disabled
                        ),
                        child: state.status == ResetPasswordStatus.submitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: LoadingScreen(),
                              )
                            : Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send_rounded,
                                      size: 20,
                                      color: _isEmailValid
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onPrimary
                                              .withOpacity(0.5),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'اعادة تعيين الرقم السري',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: _isEmailValid
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onPrimary
                                                .withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
