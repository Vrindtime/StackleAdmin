import 'package:flutter/material.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/view/accounts/accounts_screen.dart';
import 'package:stackle_admin/view/dashboard.dart';
import 'package:stackle_admin/view/manageHR/managehr_screen.dart';
import 'package:stackle_admin/view/manage_Professionals/manage_professional_screen.dart';
import 'package:stackle_admin/view/requests/request_screen.dart';
import 'package:stackle_admin/view/settings/blocked_users_screen.dart';
import 'package:stackle_admin/widgets/side_bar.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int selectedIndex = 0;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    authController = AuthController();
  }

  List<Widget> get _screens => [
        DashboardScreen(authController: authController),
        const ManageHRProfessionalsScreen(),
        const ManageProfessionalsScreen(),
        const AccountsScreen(),
        const RequestsScreen(),
        const BlockedUsersListScreen(),
        //const SettingsScreen(),
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
                authController: authController,
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
                  authController: authController,
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
