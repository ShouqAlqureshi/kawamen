import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawamen/features/Profile/Screens/edit_profile_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  bool emotionDetectionToggle = false;
  bool notificationToggle = false;
  bool microphoneToggle = false;
  bool showControlCenter = false;

  // User info variables
  String userName = 'shouq alqureshi'; //for testing purposes
  String userEmail = 'shooq@gmail.com';
  String userAge = '16';
  String avatarText = 'SB';

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  // Function to get initials from name
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

  Future<Map<String, String>> fetchUserInfo() async {
    Map<String, String> userInfo = {
      'name': '',
      'email': '',
      'age': '',
    };

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Usersinfo')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          userInfo = {
            'name': userData['name']?.toString() ?? '',
            'email': userData['email']?.toString() ?? '',
            'age': userData['age']?.toString() ?? '',
          };

          setState(() {
            userName = userInfo['name'] ?? '';
            userEmail = userInfo['email'] ?? '';
            userAge = userInfo['age'] ?? '';
            avatarText = getInitials(userName);
          });
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
    return userInfo;
  }

  void navigateToEditProfile() async {
    final userInfo = await fetchUserInfo();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            initialUserInfo: userInfo,
            onProfileUpdated: () {
              fetchUserInfo(); // Refresh profile data after update
            },
          ),
        ),
      );
    }
  }

  Widget buildProfile() {
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
                userAge.isNotEmpty ? '$userAge years old' : '',
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
                            "Edit Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        tileColor: const Color.fromARGB(255, 48, 48, 48),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap:
                            navigateToEditProfile, // Fixed: Call the function directly
                      ),
                    ),
                    Card(
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        title: const Center(
                          child: Text(
                            "Control Center",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        tileColor: showControlCenter
                            ? const Color.fromARGB(255, 94, 94, 94)
                            : const Color.fromARGB(255, 48, 48, 48),
                        trailing: showControlCenter
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
                          setState(() {
                            showControlCenter = !showControlCenter;
                          });
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
                            'Emotion Detection',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: emotionDetectionToggle,
                          onChanged: (bool value) {
                            setState(() {
                              emotionDetectionToggle = value;
                            });
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
                            'Microphone',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: microphoneToggle,
                          onChanged: (bool value) {
                            setState(() {
                              microphoneToggle = value;
                            });
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
                            'Notification',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: notificationToggle,
                          onChanged: (bool value) {
                            setState(() {
                              notificationToggle = value;
                            });
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
                            "Log out",
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
                          if (mounted) {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => logout(),
                            //   ),
                            // );
                          }
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

  @override
  Widget build(BuildContext context) {
    return buildProfile();
  }
}
