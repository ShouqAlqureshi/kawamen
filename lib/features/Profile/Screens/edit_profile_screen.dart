import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/LogIn/view/login_page.dart';
import 'package:kawamen/features/Profile/repository/profile_repository.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/screen/reset_password_screen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import '../../Reset Password/bloc/bloc/reset_password_bloc.dart';
import '../Bloc/profile_bloc.dart';

class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic> initialUserInfo;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.initialUserInfo,
    required this.onProfileUpdated,
  });
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(context: context),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) async {
          if (state is ProfileNeedsReauth) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('سوف يعاد توجيهك لاعادة توثيق الدخول لحسابك'),
                backgroundColor: Colors.green,
              ),
            );
            final credential = await Navigator.of(context).push<UserCredential>(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );

            if (credential != null) {
              if (!context.mounted) return;
              context
                  .read<ProfileBloc>()
                  .add(ReauthenticationComplete(credential));
            }
          }

          if (state is ProfileNeedsVerification) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'الرجاء اثبات البريد الالكتروني  '
                  '${state.email}: من خلال الرابط المرسل للبريد الالكتروني ',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }

          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is AccountDeleted) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حذف الحساب بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          }
          if (state is ProfileUpdated) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث معلومات الحساب بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            onProfileUpdated();
            Navigator.pop(context, true);
          }
        },
        child: _EditProfileScreenContent(
          initialUserInfo: initialUserInfo,
          onProfileUpdated: onProfileUpdated,
        ),
      ),
    );
  }
}

class _EditProfileScreenContent extends StatelessWidget {
  final Map<String, dynamic> initialUserInfo;
  final VoidCallback onProfileUpdated;

  const _EditProfileScreenContent({
    required this.initialUserInfo,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameController =
        TextEditingController(text: initialUserInfo['fullName'] as String);
    final emailController =
        TextEditingController(text: initialUserInfo['email'] as String);
    final ageController =
        TextEditingController(text: initialUserInfo['age'].toString());
    
    String avatarText = getInitials(nameController.text);

    return ThemedScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "تعديل معلومات الحساب",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.right,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Enhanced profile avatar with animated decoration
                Hero(
                  tag: 'profile-avatar',
                  child: Container(
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
                      radius: 65,
                      backgroundColor: theme.colorScheme.secondary,
                      child: Text(
                        avatarText,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Form fields with enhanced styling
                _buildFormField(
                  controller: nameController,
                  label: 'الاسم',
                  icon: Icons.person_outline,
                  theme: theme,
                  maxLength: 30,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    if (value.startsWith(' ')) {
                      return 'لا يمكن أن يبدأ الاسم بمسافات';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildFormField(
                  controller: emailController,
                  label: 'البريد الالكتروني',
                  icon: Icons.email_outlined,
                  theme: theme,
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الالكتروني مطلوب';
                    }
                    if (value.startsWith(' ')) {
                      return 'البريد الإلكتروني لا يمكن أن يبدأ بمسافات';
                    }
                    if (!value.contains('@')) {
                      return 'أدخل عنوان بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildFormField(
                  controller: ageController,
                  label: 'العمر',
                  icon: Icons.cake_outlined,
                  theme: theme,
                  maxLength: 5,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'العمر مطلوب';
                    }
                    int? age = int.tryParse(value);
                    if (age == null || age <= 0 || age > 150) {
                      return 'أدخل عمر صالح';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Save changes button with enhanced style
                _buildActionButton(
                  context: context,
                  label: 'حفظ التغييرات',
                  icon: Icons.check_circle_outline,
                  theme: theme,
                  color: theme.colorScheme.primary,
                  onTap: () {
                    context.read<ProfileBloc>().add(UpdateUserInfo(
                          name: nameController.text,
                          email: emailController.text,
                          age: ageController.text,
                        ));
                    onProfileUpdated();
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Additional actions with matching style
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'تعيين الرقم السري',
                        icon: Icons.lock_outline,
                        theme: theme,
                        color: theme.colorScheme.tertiary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResetPasswordPage(
                                onReauthenticationRequired: (context) async {
                                  final credential = await Navigator.of(context)
                                      .push<UserCredential>(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                  );

                                  if (credential != null) {
                                    context.read<ResetPasswordBloc>().add(
                                          ResetPasswordReauthenticationComplete(
                                              credential),
                                        );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'حذف الحساب',
                        icon: Icons.delete_outline,
                        theme: theme,
                        color: Colors.red,
                        onTap: () async {
                          final shouldDelete = await _showDeleteAccountDialog(context, theme);
                          if (shouldDelete) {
                            context.read<ProfileBloc>().add(DeleteAccount());
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required int maxLength,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                counterText: '',
              ),
              maxLength: maxLength,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteAccountDialog(BuildContext context, ThemeData theme) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تأكيد حذف الحساب',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'حذف الحساب',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    ) ?? false;
  }

  String getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> nameParts = name.trim().split(' ');
    String initials = '';
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials;
  }
}

// This is the function that was referenced in the original code but not defined
Future<bool> showdeleteaccountDialog(BuildContext context) async {
  final theme = Theme.of(context);
  return await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'تأكيد حذف الحساب',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                ),
                child: Text(
                  'إلغاء',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'حذف الحساب',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      );
    },
  ) ?? false;
}