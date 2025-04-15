import 'package:flutter/material.dart';
import 'core/services/Notification_service.dart';

class HomePage extends StatelessWidget {
  // Add an optional parameter to control whether to show the bottom nav
  final bool showBottomNav;
  
  const HomePage({super.key, this.showBottomNav = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Icon(Icons.menu, color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage("lib/core/assets/images/profile.png"),
              radius: 20,
            ),
          )
        ],
        title: const Text(
          'الرئيسية',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ ',
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                  children: [
                    TextSpan(
                      text: 'القلوب',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.auto_awesome, color: Colors.greenAccent),
            const SizedBox(height: 30),
            const Text(
              "جلساتك",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSessionCard(
              label: 'القلق',
              title: 'التنفس العميق والاسترخاء العضلي',
              icon: Icons.self_improvement,
              isActive: true,
            ),
            _buildSessionCard(
              label: 'الحزن',
              title: 'الكتابة التأملية',
              icon: Icons.edit_note,
            ),
            _buildSessionCard(
              label: 'القلق',
              title: 'إعادة التركيز وتحدي الأفكار السلبية',
              icon: Icons.sync_alt,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      // Only show the bottom navigation bar if showBottomNav is true
      bottomNavigationBar: showBottomNav ? BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
        ],
      ) : null,
    );
  }

  Widget _buildSessionCard({
    required String label,
    required String title,
    required IconData icon,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'استئناف',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          const TreatmentNavigator(),
        ],
      ),
    );
  }
}