import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawamen/features/Profile/Screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_bloc.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(FetchToggleStates()),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ToggleStatesLoaded) {
              return _buildProfile(context, state);
            } else if (state is ProfileError) {
              print(state.message);
              return Center(
                  child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ));
            } else {
              return const Center(child: Text('Something went wrong'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, ToggleStatesLoaded state) {
    String userName = state.userData['fullName'] ?? '';
    String userEmail = state.userData['email'] ?? '';
    String userAge = state.userData['age'] ?? '';
    String avatarText = getInitials(userName);
    bool showControlCenter = false;
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
                        tileColor: showControlCenter
                            // ignore: dead_code
                            ? const Color.fromARGB(255, 94, 94, 94)
                            : const Color.fromARGB(255, 48, 48, 48),
                        trailing: showControlCenter
                            // ignore: dead_code
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
                        onTap: () {
                          showControlCenter = !showControlCenter;
                        },
                      ),
                    ),
                    if (showControlCenter) ...[
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
                            "Unenabling this won't allow the app to provide treatments",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          tileColor: const Color.fromARGB(255, 48, 48, 48),
                          activeColor: Colors.green,
                          inactiveTrackColor: Colors.white24),
                      SwitchListTile(
                          title: const Text(
                            'المايكروفون',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: state.microphoneToggle,
                          onChanged: (value) {
                            context.read<ProfileBloc>().add(
                                  UpdateToggleState(
                                    toggleName: 'microphoneToggle',
                                    newValue: value,
                                  ),
                                );
                          },
                          subtitle: const Text(
                            "Unenabling this won't allow the app to passively listen and detect emotion",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          tileColor: const Color.fromARGB(255, 48, 48, 48),
                          activeColor: Colors.green,
                          inactiveTrackColor: Colors.white24),
                      SwitchListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                          title: const Text(
                            'الاشعارات',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: state.notificationToggle,
                          onChanged: (value) {
                            context.read<ProfileBloc>().add(
                                  UpdateToggleState(
                                    toggleName: 'notificationToggle',
                                    newValue: value,
                                  ),
                                );
                          },
                          subtitle: const Text(
                            "Unenabling this won't allow the app to send treatment suggestions",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          tileColor: const Color.fromARGB(255, 48, 48, 48),
                          activeColor: Colors.green,
                          inactiveTrackColor: Colors.white24),
                    ],
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
