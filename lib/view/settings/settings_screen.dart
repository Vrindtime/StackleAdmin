import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/notification_controller.dart';
import 'package:stackle_admin/view/settings/privacy_policy_add_screen.dart';
import 'package:stackle_admin/view/settings/widgets/push_notification_modal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0), // Cream/beige background
      body: Row(
        children: [
          // Use the previously created Sidebar widget
          // Sidebar(
          //   isMobile: false,
          //   selectedIndex: 0,
          //   onItemSelected: (int index) {
          //     // Handle sidebar item selection
          //   },
          // ),
          // Main content area
          Expanded(
            child: _buildMainContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 40),
          _buildSettingsGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTabletOrMobile = MediaQuery.of(context).size.width < 1024;

    return Row(
      children: [
        if (isTabletOrMobile)
          IconButton(
            onPressed: () {
              // Handle menu toggle for mobile/tablet
            },
            icon: const Icon(
              Icons.menu,
              color: Color(0xFF2D3748),
              size: 28,
            ),
          ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: _getTitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),

              // User profile section
              IconButton(
                onPressed: () {
                  Get.toNamed('/notifications');
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF6B7280),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth -
        280 -
        _getHorizontalPadding(context) *
            2; // Subtract sidebar width and padding

    int crossAxisCount;
    double childAspectRatio;

    if (availableWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 2.8;
    } else if (availableWidth > 500) {
      crossAxisCount = 2;
      childAspectRatio = 2.5;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 4.0;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: [
        // _buildSettingCard(
        //   icon: Icons.people_outline,
        //   title: 'Blocked Users',
        // ),
        // _buildSettingCard(
        //   icon: Icons.chat_bubble_outline,
        //   title: 'Feedbacks',
        // ),
        _buildSettingCard(
          context: context,
          icon: Icons.shield_outlined,
          title: 'Privacy Policy',
          page: const PrivacyPolicyAddScreen(),
        ),
        _buildSettingCard(
          context: context,
          icon: Icons.notifications_outlined,
          title: 'Push notification',
          fullWidth: true,
          onTap: () => _showPushNotificationModal(context),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool fullWidth = false,
    VoidCallback? onTap,
    Widget? page,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (onTap != null) {
              onTap();
            } else if (page != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => page),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF4A5568),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 40;
    if (screenWidth > 768) return 32;
    return 24;
  }

  double _getTitleFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 32;
    if (screenWidth > 768) return 28;
    return 24;
  }

  void _showPushNotificationModal(BuildContext context) {
    final notificationController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    notificationController.clearForm();
    notificationController.fetchRecipients();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PushNotificationModal(
        controller: notificationController,
      ),
    ).then((_) {
      if (Get.isRegistered<NotificationController>()) {
        notificationController.clearForm();
      }
    });
  }
}
