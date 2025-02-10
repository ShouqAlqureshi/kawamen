
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawamen/features/Profile/Bloc/microphone_bloc.dart';
import 'package:kawamen/features/Profile/Screens/edit_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/reset_password_bloc.dart';
import 'package:kawamen/features/Reset%20Password/bloc/bloc/screen/reset_password_screen.dart';
import '../Bloc/profile_bloc.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

   @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProfileBloc(context: context)..add(FetchToggleStates()),
        ),
        BlocProvider(
          create: (context) => MicrophoneBloc(),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ToggleStatesLoaded) {
              return _buildProfile(context, state);
            } else if (state is ProfileError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.white)));
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, ToggleStatesLoaded state) {
    String userName = state.userData['fullName'] ?? '';
    String userEmail = state.userData['email'] ?? '';
    // Debug print
    if (kDebugMode) {
      print('Raw age data: ${state.userData['age']}');
    }
    if (kDebugMode) {
      print('Age type: ${state.userData['age'].runtimeType}');
    }
    String userAge =
        state.userData['age'] != null ? state.userData['age'].toString() : '';
    String avatarText = getInitials(userName);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 70,
                backgroundColor: const Color.fromARGB(255, 48, 48, 48),
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// User information///
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userAge.isNotEmpty ? '$userAge سنه' : '',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    Card(
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        title: const Center(
                          child: Text(
                            "تعديل معلومات الحساب",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        tileColor: const Color.fromARGB(255, 48, 48, 48),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                initialUserInfo: state.userData,
                                onProfileUpdated: () {
                                  context
                                      .read<ProfileBloc>()
                                      .add(FetchUserInfo());
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        title: const Center(
                          child: Text(
                            "لوحة تحكم",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        tileColor: state
                                .showControlCenter // Use state instead of local variable
                            ? const Color.fromARGB(255, 94, 94, 94)
                            : const Color.fromARGB(255, 48, 48, 48),
                        trailing: state
                                .showControlCenter // Use state instead of local variable
                            ? const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        onTap: () {  context.read<ProfileBloc>().add(ToggleControlCenter());
                        },
                      ),
                    ),
                    // Replace the if (state.showControlCenter) block with:
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  height: state.showControlCenter ? 140 : 0,
  child: SingleChildScrollView(
    child: Column(
      children: [
        const SizedBox(height: 8),
        SwitchListTile(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          title: const Text(
            'اكتشاف المشاعر',
            style: TextStyle(color: Colors.white),
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
          subtitle: const Text(
            "ايقاف هذه الخاصيه لن يسمح للتطبيق توفير اقتراحات العلاج",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
          tileColor: const Color.fromARGB(255, 48, 48, 48),
          activeColor: Colors.green,
          inactiveTrackColor: Colors.white24,
        ),
        BlocBuilder<MicrophoneBloc, MicrophoneState>(
          builder: (context, micState) {
            bool isMicEnabled = micState is MicrophoneEnabled;
            return SwitchListTile(
              title: const Text(
                'المايكروفون',
                style: TextStyle(color: Colors.white),
              ),
              value: isMicEnabled,
              onChanged: (value) async {
                context.read<MicrophoneBloc>().add(ToggleMicrophone());
                await Future.delayed(const Duration(milliseconds: 200));
                if (context.mounted && 
                    context.read<MicrophoneBloc>().state is MicrophoneEnabled) {
                  context.read<ProfileBloc>().add(UpdateToggleState(
                    toggleName: 'microphoneToggle',
                    newValue: value,
                  ));
                }
              },
              subtitle: Text(
                micState is MicrophonePermissionDenied
                    ? "يرجى السماح بإذن المايكروفون في إعدادات التطبيق"
                    : "ايقاف هذه الخاصيه لن يسمح للتطبيق من تحليل المشاعر",
                style: TextStyle(
                  fontSize: 10,
                  color: micState is MicrophonePermissionDenied
                      ? Colors.red
                      : Colors.white,
                ),
              ),
              tileColor: const Color.fromARGB(255, 48, 48, 48),
              activeColor: Colors.green,
              inactiveTrackColor: Colors.white24,
            );
          },
        ),
      ],
    ),
  ),
),
                    const SizedBox(height: 46),
                    //this should be in the sign in page 
                    Card(
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        leading: const Icon(
                          Icons.password_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: const Center(
                          child: Text(
                            "reset password",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        tileColor: const Color.fromARGB(255, 48, 48, 48),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap: () {
                        //   Navigator.of(context).push(
                        //     MaterialPageRoute(
                        //       builder: (_) => ResetPasswordPage(
                        //         onReauthenticationRequired: (context) async {
                        //           // Navigate to sign in page and wait for result
                        //           final credential = await Navigator.of(context)
                        //               .push<UserCredential>(
                        //             MaterialPageRoute(
                        //                 builder: (_) => SignInPage()),
                        //           );

                        //           // If we got credentials back, complete the reset password flow
                        //           if (credential != null) {
                        //             context.read<ResetPasswordBloc>().add(
                        //                   ResetPasswordReauthenticationComplete(
                        //                       credential),
                        //                 );
                        //           }
                        //         },
                        //       ),
                        //     ),
                        //   );
                        },
                      ),
                    ),
                    const SizedBox(height: 46),
                    Card(
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: const Center(
                          child: Text(
                            "تسجيل خروج",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        tileColor: const Color.fromARGB(255, 48, 48, 48),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap: () {
                          // context.read<ProfileBloc>().add(
                          //       logout(),
                          //     );
                        },
                      ),
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
