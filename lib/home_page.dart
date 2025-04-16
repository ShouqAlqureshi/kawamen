import 'package:flutter/material.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'core/services/Notification_service.dart';

class HomePage extends StatelessWidget {
  // Add an optional parameter to control whether to show the bottom nav
  final bool showBottomNav;
  
  const HomePage({super.key, this.showBottomNav = false});

  @override
  Widget build(BuildContext context) {
    // Access the theme from the context
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    
    return Scaffold(
      // Use theme's scaffoldBackgroundColor instead of hardcoded color
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Use theme's appBarTheme properties
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: Icon(Icons.menu, color: theme.colorScheme.onBackground),
        title: Text(
          'الرئيسية',
          style: theme.textTheme.headlineMedium,
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
                text: TextSpan(
                  text: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ ',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    height: 1.8,
                  ),
                  children: [
                    TextSpan(
                      text: 'القلوب',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary.withOpacity(0.8)),
            const SizedBox(height: 30),
            Text(
              "جلساتك",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            _buildSessionCard(
              context: context,
              label: 'القلق',
              title: 'التنفس العميق والاسترخاء العضلي',
              icon: Icons.self_improvement,
              isActive: true,
            ),
            _buildSessionCard(
              context: context,
              label: 'الحزن',
              title: 'الكتابة التأملية',
              icon: Icons.edit_note,
            ),
            _buildSessionCard(
              context: context,
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
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
        ],
      ) : null,
    );
  }

  Widget _buildSessionCard({
    required BuildContext context,
    required String label,
    required String title,
    required IconData icon,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'استئناف',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          const TreatmentNavigator(),
        ],
      ),
    );
  }
}