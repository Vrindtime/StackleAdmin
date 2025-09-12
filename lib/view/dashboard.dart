import 'package:flutter/material.dart';
import 'package:stackle_admin/view/accounts/accounts_screen.dart';
import 'package:stackle_admin/view/dashboard1.dart';
import 'package:stackle_admin/view/manageHR/hr_details_screen.dart';
import 'package:stackle_admin/view/manageHR/managehr_screen.dart';
import 'package:stackle_admin/view/manage_Professionals/manage_professional_screen.dart';
import 'package:stackle_admin/view/requests/request_screen.dart';
import 'package:stackle_admin/view/settings/blocked_users_screen.dart';
import 'package:stackle_admin/view/settings/feedbacks_screen.dart';
import 'package:stackle_admin/view/settings/notification_screen.dart';
import 'package:stackle_admin/view/settings/settings_screen.dart';
import 'package:stackle_admin/widgets/side_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen1(),
    const ManageHRProfessionalsScreen(),
    const ManageProfessionalsScreen(),
    const AccountsScreen(),
    const RequestsScreen(),
    //const SettingsScreen(),
    const BlockedUsersListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          bool isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          bool isDesktop = constraints.maxWidth >= 1024;

          if (isMobile) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFFF5F1E8),
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              drawer: Sidebar(
                isMobile: true,
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() => selectedIndex = index);
                  Navigator.pop(context); // close drawer
                },
              ),
              body: _screens[selectedIndex],
            );
          } else {
            return Row(
              children: [
                Sidebar(
                  isMobile: false,
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                ),
                Expanded(
                  child: _screens[selectedIndex],
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
