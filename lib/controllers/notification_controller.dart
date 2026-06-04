import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/core/api_base.dart' as api_base;
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/data/models/push_notification.dart';
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/data/services/notification_service.dart';
import 'package:stackle_admin/data/services/user_service.dart';
import 'package:stackle_admin/data/services/websocket_notification_service.dart';

class NotificationController extends GetxController {
  NotificationController({
    NotificationService? notificationService,
    UserService? userService,
    // Optional WebSocket service for injection/testing
    WebSocketNotificationService? wsService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _userService = userService ?? UserService(),
       _wsService = wsService;

  final NotificationService _notificationService;
  final UserService _userService;

  // --- New WebSocket Properties ---
  WebSocketNotificationService? _wsService;
  StreamSubscription<PushNotification>? _wsSubscription;
  final Rxn<PushNotification> lastNewNotification =
      Rxn<PushNotification>(); // nullable reactive

  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final RxList<User> recipients = <User>[].obs;
  final RxList<int> selectedRecipientIds = <int>[].obs;
  final RxBool sendToAll = true.obs;

  final RxBool isLoadingRecipients = false.obs;
  final RxBool isLoadingNotifications = false.obs;
  final RxBool isSendingNotification = false.obs;

  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxString notificationsError = ''.obs;

  final RxList<PushNotification> notifications = <PushNotification>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Assuming Get.find<AuthController>() provides the necessary user details
    final authController = Get.find<AuthController>();

    // Only connect if we have an access token available
    if (authController.accessToken.value.isNotEmpty) {
      _initWebSocket(token: authController.accessToken.value);
    }

    fetchRecipients();
    fetchNotifications();
  }

  @override
  void onClose() {
    _wsSubscription?.cancel(); // Cancel subscription
    _wsService?.close(); // Close the connection

    titleController.dispose();
    messageController.dispose();
    super.onClose();
  }

  // --- New WebSocket Logic ---
  void _initWebSocket({required String token}) {
    final wsUrl = "${api_base.wsUrl}/notifications/";

    _wsService =
        _wsService ??
        WebSocketNotificationService(baseUrl: wsUrl, authToken: token);

    _wsSubscription = _wsService!.notificationsStream.listen(
      _handleIncomingNotification,
      onError: (err) {
        // Optionally handle subscription errors
        print('WebSocket subscription error: $err');
      },
    );
    _wsService!.connect();
  }

  void _handleIncomingNotification(PushNotification notification) {
    // 1. Add the new notification to the history list immediately
    notifications.insert(0, notification);

    // 2. Set the reactive variable to trigger the global popup UI
    lastNewNotification.value = notification;

    // 3. Optional: Automatically clear the popup after a short delay
    Future.delayed(const Duration(seconds: 5), () {
      if (lastNewNotification.value?.id == notification.id) {
        lastNewNotification.value = null;
      }
    });

    // 4. Update the unread count or other metrics if you track them
    // You might also want to refetch the full notifications list if needed: fetchNotifications();
  }

  // Public method to clear the notification from the global popup explicitly
  void clearPopup() {
    lastNewNotification.value = null;
  }

  Future<void> fetchRecipients({String? search}) async {
    try {
      isLoadingRecipients.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      if (token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      final fetched = await _userService.getUsers(token: token, search: search);
      recipients.assignAll(fetched);
    } catch (e) {
      errorMessage.value = e.toString();
      recipients.clear();
    } finally {
      isLoadingRecipients.value = false;
    }
  }

  Future<void> fetchNotifications() async {
    try {
      isLoadingNotifications.value = true;
      notificationsError.value = '';

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      if (token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      final fetched = await _notificationService.fetchNotifications(
        token: token,
      );
      notifications.assignAll(fetched);
    } catch (e) {
      notificationsError.value = e.toString();
      notifications.clear();
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  void updateSendToAll(bool value) {
    sendToAll.value = value;
    if (value) {
      selectedRecipientIds.clear();
    }
  }

  void toggleRecipient(User user) {
    if (sendToAll.value) return;

    if (selectedRecipientIds.contains(user.id)) {
      selectedRecipientIds.remove(user.id);
    } else {
      selectedRecipientIds.add(user.id);
    }
  }

  bool isRecipientSelected(User user) => selectedRecipientIds.contains(user.id);

  bool get canSendNotification {
    final hasTitle = titleController.text.trim().isNotEmpty;
    final hasMessage = messageController.text.trim().isNotEmpty;
    final hasRecipients = sendToAll.value || selectedRecipientIds.isNotEmpty;
    return hasTitle &&
        hasMessage &&
        hasRecipients &&
        !isSendingNotification.value;
  }

  Future<bool> sendNotification() async {
    if (!canSendNotification) {
      errorMessage.value = 'Please complete the form before sending.';
      return false;
    }

    try {
      isSendingNotification.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      if (token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      final request = PushNotificationRequest(
        title: titleController.text.trim(),
        message: messageController.text.trim(),
        broadcastToAll: sendToAll.value,
        recipientIds: List<dynamic>.from(selectedRecipientIds),
      );

      final result = await _notificationService.sendNotification(
        token: token,
        request: request,
      );

      final created = result.created;
      final requestedCount = result.requestedCount;
      final defaultMessage = 'Notification sent successfully';
      String message = result.message.isNotEmpty
          ? result.message
          : defaultMessage;

      if (created != null || requestedCount != null) {
        final processed = created ?? requestedCount ?? 0;
        final expected = requestedCount ?? created ?? 0;
        message = 'Notifications sent: $processed of $expected.';
      }

      successMessage.value = message;
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      if (result.missingUserIds.isNotEmpty) {
        final formatted = result.missingUserIds.join(', ');
        Get.snackbar(
          'Warning',
          'Skipped recipients: $formatted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
      }

      await fetchNotifications();
      clearForm();
      return true;
    } catch (e) {
      final message = e is NotificationException ? e.message : e.toString();
      errorMessage.value = message;
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isSendingNotification.value = false;
    }
  }

  void clearForm() {
    titleController.clear();
    messageController.clear();
    selectedRecipientIds.clear();
    sendToAll.value = true;
  }
}
