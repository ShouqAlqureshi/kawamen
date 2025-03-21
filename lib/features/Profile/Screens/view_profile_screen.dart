import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawamen/features/Profile/Bloc/microphone_bloc.dart';
import 'package:kawamen/features/Profile/Screens/edit_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/reset_password_bloc.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/screen/reset_password_screen.dart';
import 'package:kawamen/features/Treatment/screen/CBT_page';
import 'package:kawamen/features/Treatment/screen/deep_breathing_page.dart';
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
        // Add this Builder widget
        builder: (context) => Scaffold(
          // Now this context has access to the providers
          backgroundColor: theme.colorScheme.background,
          body: BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileUpdated) {
                context.read<ProfileBloc>().add(FetchToggleStates());
              }
            },
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ToggleStatesLoaded) {
                return _buildProfile(context, state, theme);
              } else if (state is ProfileError) {
                return Center(
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }
              return Center(
                child: Text(
                  'Something went wrong',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(
      BuildContext context, ToggleStatesLoaded state, ThemeData theme) {
    String userName = state.userData['fullName'] ?? '';
    String userEmail = state.userData['email'] ?? '';
    String userAge = state.userData['age']?.toString() ?? '';
    String avatarText = getInitials(userName);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          " الحساب الشخصي",
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.right,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: (){
            // Instead of simply popping, navigate to DeepBreathingPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CBTTherapyPage(),
              ),
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 70,
                backgroundColor: theme.colorScheme.secondary,
                child: Text(
                  avatarText,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              if (userAge.isNotEmpty)
                Text(
                  '$userAge سنه',
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    _buildCard(
                      context: context,
                      title: "تعديل معلومات الحساب",
                      theme: theme,
                      onTap: () async {
                        // Make this async
                        // Navigate and wait for result
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              initialUserInfo: state.userData,
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

                        // If returned with a refresh flag, update the data
                        if (result == true) {
                          context.read<ProfileBloc>().add(FetchToggleStates());
                        }
                      },
                    ),
                    _buildCard(
                      context: context,
                      title: "لوحة تحكم",
                      theme: theme,
                      isSelected: state.showControlCenter,
                      onTap: () {
                        context.read<ProfileBloc>().add(ToggleControlCenter());
                      },
                    ),
                    if (state.showControlCenter)
                      _buildControlCenter(context, state, theme),
                    const SizedBox(height: 46),
                    _buildCard(
                      context: context,
                      title: "تسجيل خروج",
                      theme: theme,
                      leading: Icons.logout,
                      onTap: () {
                        context
                            .read<ProfileBloc>()
                            .add(Logout()); // Trigger logout event
                      },
                    ),
                  ],
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
    IconData? leading,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        leading: leading != null
            ? Icon(
                leading,
                color: theme.colorScheme.onSurface,
                size: 20,
              )
            : null,
        title: Center(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        tileColor: isSelected
            ? theme.colorScheme.secondary
            : theme.colorScheme.surface,
        trailing: Icon(
          isSelected
              ? Icons.keyboard_arrow_down_rounded
              : Icons.arrow_forward_ios_rounded,
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildControlCenter(
    BuildContext context,
    ToggleStatesLoaded state,
    ThemeData theme,
  ) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      offset: const Offset(0, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: 1.0,
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surfaceVariant, // Adjust based on your theme
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              SwitchListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                title: Text(
                  'اكتشاف المشاعر',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                value: state.emotionDetectionToggle,
                onChanged: (value) {
                  context.read<ProfileBloc>().add(
                        UpdateToggleState(
                          toggleName: 'emotionDetectionToggle',
                          newValue: value,
                        ),
                      );
                },
                subtitle: Text(
                  "ايقاف هذه الخاصيه لن يسمح للتطبيق توفير اقتراحات العلاج",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                tileColor: theme.colorScheme.surfaceVariant,
                activeColor: theme.colorScheme.primary,
                inactiveTrackColor:
                    theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const Divider(height: 1, thickness: 1),
              BlocBuilder<MicrophoneBloc, MicrophoneState>(
                builder: (context, micState) {
                  bool isMicEnabled = micState is MicrophoneEnabled;
                  return SwitchListTile(
                    title: Text(
                      'المايكروفون',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    value: isMicEnabled,
                    onChanged: (value) async {
                      context.read<MicrophoneBloc>().add(ToggleMicrophone());
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (context.mounted &&
                          context.read<MicrophoneBloc>().state
                              is MicrophoneEnabled) {
                        context.read<ProfileBloc>().add(
                              UpdateToggleState(
                                toggleName: 'microphoneToggle',
                                newValue: value,
                              ),
                            );
                      }
                    },
                    subtitle: Text(
                      micState is MicrophonePermissionDenied
                          ? "يرجى السماح بإذن المايكروفون في إعدادات التطبيق"
                          : "ايقاف هذه الخاصيه لن يسمح للتطبيق من تحليل المشاعر",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: micState is MicrophonePermissionDenied
                            ? Colors.red
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    tileColor: theme.colorScheme.surfaceVariant,
                    activeColor: theme.colorScheme.primary,
                    inactiveTrackColor:
                        theme.colorScheme.onSurface.withOpacity(0.3),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required ThemeData theme,
    Color? subtitleColor,
  }) {
    return SwitchListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: subtitleColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      value: value,
      onChanged: onChanged,
      tileColor: theme.colorScheme.surface,
      activeColor: Colors.green,
      inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.3),
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
