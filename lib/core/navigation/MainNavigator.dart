import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:kawamen/features/Dashboard/screen/dashboard_screen.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import '../../home_page.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  
  // We'll create modified versions of your pages that don't have their own bottom navigation
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize pages - removing their individual bottom navigation bars
    _pages = [
      _buildHomePageWithoutBottomNav(),
      const DashboardScreen(),
      const ViewProfileScreen(),
    ];
  }
  
  // This wraps your HomePage but removes its bottom navigation
  Widget _buildHomePageWithoutBottomNav() {
    return Builder(
      builder: (context) {
        // Use a nested builder to get the correct context
        return Scaffold(
          body: HomePage(
            // If needed, you can pass props here
          ),
          // Remove the bottom navigation bar by setting it to null
          bottomNavigationBar: null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: _pages[_selectedIndex], // Show the selected page
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,
        backgroundColor: Colors.black, // Match your app's color scheme
        activeColor: Colors.green, // Match your active color
        color: Colors.white, // Match your inactive color
        items: const [
          TabItem(icon: Icons.home,),
          TabItem(icon: Icons.bar_chart, ),
          TabItem(icon: Icons.person,),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}