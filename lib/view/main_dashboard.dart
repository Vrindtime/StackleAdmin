import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/controllers/stats_controller.dart';
import 'package:stackle_admin/controllers/notification_controller.dart';
import 'package:stackle_admin/controllers/hr_controller.dart';
import 'package:stackle_admin/core/routing.dart';
import 'package:stackle_admin/view/accounts/accounts_screen.dart';
import 'package:stackle_admin/view/dashboard.dart';
import 'package:stackle_admin/view/manageHR/manage_hr_screen.dart';
import 'package:stackle_admin/view/manage_Professionals/manage_professional_screen.dart';
// import 'package:stackle_admin/view/requests/request_screen.dart';
import 'package:stackle_admin/view/settings/blocked_users_screen.dart';
import 'package:stackle_admin/view/settings/settings_screen.dart';
import 'package:stackle_admin/widgets/side_bar.dart';

class MainDashboard extends StatefulWidget {
  final int initialIndex;
  const MainDashboard({super.key, this.initialIndex = 0});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late int selectedIndex;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    // Initialize selected index from widget parameter
    selectedIndex = widget.initialIndex;
    // Use the globally registered AuthController; do NOT create a new one here
    // to avoid multiple instances and token/state mismatches.
    authController = Get.find<AuthController>();

    // Fetch current user data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.fetchCurrentUser();
      // Proactively refresh other controllers once token is available to avoid 401s
      if (authController.accessToken.value.isNotEmpty) {
        // Stats
        if (Get.isRegistered<StatsController>()) {
          final stats = Get.find<StatsController>();
          stats.fetchTotals();
        }
        // Notifications
        if (Get.isRegistered<NotificationController>()) {
          final notif = Get.find<NotificationController>();
          notif.fetchRecipients();
          notif.fetchNotifications();
        }
        // HR/Organizations
        if (Get.isRegistered<HRController>()) {
          final hr = Get.find<HRController>();
          hr.fetchOrganizations();
        }
      } else {
        // Listen once for token availability then trigger refreshes
        ever(authController.accessToken, (val) {
          if (val.toString().isNotEmpty) {
            if (Get.isRegistered<StatsController>()) {
              Get.find<StatsController>().fetchTotals();
            }
            if (Get.isRegistered<NotificationController>()) {
              final notif = Get.find<NotificationController>();
              notif.fetchRecipients();
              notif.fetchNotifications();
            }
            if (Get.isRegistered<HRController>()) {
              Get.find<HRController>().fetchOrganizations();
            }
          }
        });
      }
    });
  }

  // Screens are returned via _screenForIndex so we can pass layout hints.

  // Return the appropriate screen widget and pass layout hints to children
  // so they can decide whether to render desktop or mobile variants.
  Widget _screenForIndex(int index, bool outerIsMobile) {
    switch (index) {
      case 0:
        return DashboardScreen(
            authController: authController, forceDesktop: !outerIsMobile);
      case 1:
        return ManageHRScreen();
      case 2:
        return const ManageProfessionalsScreen();
      case 3:
        return const AccountsScreen();
      case 4:
        return const BlockedUsersListScreen();
      case 5:
        return const SettingsScreen();
      default:
        return DashboardScreen(
            authController: authController, forceDesktop: !outerIsMobile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;

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
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Get.toNamed(AppRoutes.notificationScreen);
                    },
                  ),
                ],
              ),
              drawer: Sidebar(
                authController: authController,
                isMobile: true,
                selectedIndex: selectedIndex,
              ),
              body: _screenForIndex(selectedIndex, isMobile),
            );
          } else {
            return Row(
              children: [
                Sidebar(
                  authController: authController,
                  isMobile: false,
                  selectedIndex: selectedIndex,
                ),
                Expanded(
                  child: _screenForIndex(selectedIndex, isMobile),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
