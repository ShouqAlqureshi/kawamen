import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawamen/core/services/cache_service.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import 'package:kawamen/features/LogIn/view/login_view.dart';
import 'package:kawamen/features/Profile/Bloc/microphone_bloc.dart';
import 'package:kawamen/features/Profile/Screens/edit_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/screen/CBT_therapy_page.dart';
import 'package:kawamen/features/Treatment/deep_breathing/screen/deep_breathing_page.dart';
import '../Bloc/profile_bloc.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ProfileBloc(context: context)..add(FetchToggleStates()),
        ),
        BlocProvider(
          create: (context) => MicrophoneBloc(),
        ),
      ],
      child: Builder(
        builder: (context) => ThemedScaffold(
          body: BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileUpdated) {
                context.read<ProfileBloc>().add(FetchToggleStates());
              } else if (state is UsernNotAuthenticated) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                    (_) => false);
              }
            },
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: LoadingScreen());
              } else if (state is ToggleStatesLoaded) {
                return StreamBuilder<Map<String, dynamic>>(
                  stream: UserCacheService().getUserStream(state.userId),
                  builder: (context, cacheSnapshot) {
                    final userData = cacheSnapshot.data ?? state.userData;
                    return _buildProfile(context, state, theme, userData);
                  },
                );
              } else if (state is ProfileError) {
                return Center(
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }
              return const SizedBox(height: 10);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, ToggleStatesLoaded state,
      ThemeData theme, Map<String, dynamic> userData) {
    String userName = userData['fullName'] ?? '';
    String userEmail = userData['email'] ?? '';
    String userAge = userData['age']?.toString() ?? '';
    String avatarText = getInitials(userName);

    return ThemedScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          " الحساب الشخصي",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.right,
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
                const SizedBox(height: 20),
                // User name with enhanced typography
                Text(
                  userName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Email with custom styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userEmail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Age info with badge styling if available
                if (userAge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$userAge سنه',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 28),
                // Cards section with improved spacing and animations
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      _buildCard(
                        context: context,
                        title: "تعديل معلومات الحساب",
                        theme: theme,
                        icon: Icons.edit_outlined,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                initialUserInfo: userData,
                                onProfileUpdated: () {
                                  if (context.mounted) {
                                    context
                                        .read<ProfileBloc>()
                                        .add(FetchUserInfo());
                                  }
                                },
                              ),
                            ),
                          );
      
                          if (result == true) {
                            context.read<ProfileBloc>().add(FetchToggleStates());
                          }
                        },
                      ),
                      _buildCard(
                        context: context,
                        title: "اختبار المشاعر",
                        theme: theme,
                        icon: Icons.record_voice_over,
                        iconBackground: theme.colorScheme.tertiaryContainer,
                        iconColor: theme.colorScheme.onTertiaryContainer,
                        onTap: () {
                          Navigator.pushNamed(context, '/emotion-test');
                        },
                      ),
                      _buildCard(
                        context: context,
                        title: "لوحة تحكم",
                        theme: theme,
                        icon: Icons.settings_outlined,
                        isSelected: state.showControlCenter,
                        onTap: () {
                          context.read<ProfileBloc>().add(ToggleControlCenter());
                        },
                      ),
                      // Control center with enhanced animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: state.showControlCenter
                            ? _buildControlCenter(context, state, theme)
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        context: context,
                        title: "تسجيل خروج",
                        theme: theme,
                        icon: Icons.logout_rounded,
                        color: Colors.red.withOpacity(0.7),
                        iconColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
                        iconBackground: Colors.red.withOpacity(0.7),
                        onTap: () {
                          _showLogoutConfirmationDialog(context, theme);
                        },
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 28),
                // Enhanced mood selector with visual feedback
                _buildMoodSelector(context, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced logout confirmation dialog
  Future<void> _showLogoutConfirmationDialog(BuildContext context, ThemeData theme) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تأكيد تسجيل الخروج',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج؟',
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
                    Navigator.of(context).pop();
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
                    'تسجيل الخروج',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<ProfileBloc>().add(Logout());
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildMoodSelector(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "كيف تشعر اليوم؟",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMoodButton(
                context: context,
                icon: Icons.sentiment_very_dissatisfied,
                label: "حزين",
                color: Colors.blue.shade700,
                theme: theme,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CBTTherapyPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 32),
              _buildMoodButton(
                context: context,
                icon: Icons.mood_bad,
                label: "غاضب",
                color: Colors.deepOrange.shade700,
                theme: theme,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeepBreathingPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required ThemeData theme,
    IconData? icon,
    bool isSelected = false,
    Color? color,
    Color? iconColor,
    Color? iconBackground,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: color ??
            (isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBackground ?? 
                          (iconColor ?? theme.colorScheme.primary).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    key: ValueKey<bool>(isSelected),
                    isSelected
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: isSelected ? 22 : 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlCenter(
    BuildContext context,
    ToggleStatesLoaded state,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'اكتشاف المشاعر',
            subtitle: "ايقاف هذه الخاصيه لن يسمح للتطبيق توفير اقتراحات العلاج",
            value: state.emotionDetectionToggle,
            onChanged: (value) {
              context.read<ProfileBloc>().add(
                    UpdateToggleState(
                      toggleName: 'emotionDetectionToggle',
                      newValue: value,
                    ),
                  );
            },
            icon: Icons.psychology_outlined,
            theme: theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          BlocBuilder<MicrophoneBloc, MicrophoneState>(
            builder: (context, micState) {
              bool isMicEnabled = micState is MicrophoneEnabled;
              return _buildSwitchTile(
                title: 'المايكروفون',
                subtitle: micState is MicrophonePermissionDenied
                    ? "يرجى السماح بإذن المايكروفون في إعدادات التطبيق"
                    : "ايقاف هذه الخاصيه لن يسمح للتطبيق من تحليل المشاعر",
                value: isMicEnabled,
                onChanged: (value) async {
                  context.read<MicrophoneBloc>().add(ToggleMicrophone());
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (context.mounted &&
                      context.read<MicrophoneBloc>().state is MicrophoneEnabled) {
                    context.read<ProfileBloc>().add(
                          UpdateToggleState(
                            toggleName: 'microphoneToggle',
                            newValue: value,
                          ),
                        );
                  }
                },
                icon: Icons.mic_outlined,
                theme: theme,
                subtitleColor: micState is MicrophonePermissionDenied
                    ? theme.colorScheme.error
                    : null,
                showWarningIcon: micState is MicrophonePermissionDenied,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required ThemeData theme,
    Color? subtitleColor,
    bool showWarningIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (showWarningIcon) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor ??
                              theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
              activeTrackColor: theme.colorScheme.primaryContainer,
              inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
              inactiveTrackColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
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