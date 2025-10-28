import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/notification_controller.dart';

/// A wrapper that places a global notification popup above the app UI when
/// [NotificationController.lastNewNotification] is set.
class RootNotificationWrapper extends StatelessWidget {
  final Widget child;

  const RootNotificationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Stack(
      children: [
        // 1) The main application UI
        child,

        // 2) The global notification popup
        Obx(() {
          final notification = controller.lastNewNotification.value;

          if (notification != null) {
            return Positioned(
              top: 20,
              right: 20,
              child: NotificationPopupWidget(
                title: notification.title,
                message: notification.message,
                onTap: () {
                  controller.clearPopup();
                  // Navigate to notifications screen if desired. Kept commented
                  // so integrators choose the route that fits their app.
                  // Get.toNamed('/notifications/${notification.id}');
                },
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

/// Minimal notification popup UI used by the wrapper.
class NotificationPopupWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onTap;

  const NotificationPopupWidget({
    super.key,
    required this.title,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              const Text('Tap to view', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
