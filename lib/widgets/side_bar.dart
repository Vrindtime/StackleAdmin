import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class Sidebar extends StatelessWidget {
  final bool isMobile;
  final int selectedIndex;
  final AuthController authController;

  const Sidebar({
    super.key,
    required this.isMobile,
    required this.selectedIndex,
    required this.authController,
  });

  // Map menu index to route path
  static const Map<int, String> indexToRoute = {
    0: '/dashboard',
    1: '/dashboard/hr',
    2: '/dashboard/professionals',
    3: '/dashboard/accounts',
    4: '/dashboard/blocked',
    5: '/dashboard/settings',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? 250 : 240,
      color: const Color(0xFF2D2D2D),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'STACKLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(context, Icons.dashboard, 'Dashboard', 0),
                _buildMenuItem(context, Icons.people_outline, 'Manage HR', 1),
                _buildMenuItem(context, Icons.person_outline, 'Manage Professionals', 2),
                _buildMenuItem(context, Icons.account_circle_outlined, 'Account', 3),
                _buildMenuItem(context, Icons.lock_outline, 'Blocked', 4),
                _buildMenuItem(context, Icons.settings, 'Settings', 5),
              ],
            ),
          ),

          // Logout
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: authController.logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC3545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, int index) {
    bool isActive = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFFFFD700) : Colors.white,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFFFD700) : Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        tileColor: isActive ? const Color(0xFFFFD700) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dense: true,
        onTap: () {
          // Close drawer if mobile
          if (isMobile) {
            Navigator.pop(context);
          }
          // Navigate to the route for this menu item
          final route = indexToRoute[index] ?? '/dashboard';
          Get.toNamed(route);
        },
      ),
    );
  }

}
