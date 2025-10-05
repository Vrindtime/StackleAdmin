import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/notification_controller.dart';
import 'package:stackle_admin/data/models/user.dart';

class PushNotificationModal extends StatefulWidget {
  const PushNotificationModal({super.key, required this.controller});

  final NotificationController controller;

  @override
  State<PushNotificationModal> createState() => _PushNotificationModalState();
}

class _PushNotificationModalState extends State<PushNotificationModal> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  NotificationController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      controller.fetchRecipients(search: value);
    });
  }

  Future<void> _handleSendPressed() async {
    final success = await controller.sendNotification();
    if (success && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Title',
                    hintText: 'Enter notification title',
                    controller: controller.titleController,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Message',
                    hintText: 'Enter notification message',
                    controller: controller.messageController,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 24),
                  _buildRecipientToggle(),
                  const SizedBox(height: 12),
                  _buildRecipientPicker(),
                  const SizedBox(height: 24),
                  _buildErrorMessage(),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Send Push Notification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildRecipientToggle() {
    return Obx(() {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: controller.sendToAll.value,
        title: const Text(
          'Send to all users',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Disable this to pick specific recipients',
          style: TextStyle(color: Colors.black54),
        ),
        onChanged: controller.updateSendToAll,
      );
    });
  }

  Widget _buildRecipientPicker() {
    return Obx(() {
      if (controller.sendToAll.value) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Obx(() {
              final isLoading = controller.isLoadingRecipients.value;
              final recipients = controller.recipients.toList();
              final selectedIds = controller.selectedRecipientIds.toSet();

              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (recipients.isEmpty) {
                return const Center(
                  child: Text(
                    'No users found for the current filter.',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              return Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipients.length,
                  itemBuilder: (context, index) {
                    final user = recipients[index];
                    final isSelected = selectedIds.contains(user.id);
                    return _RecipientTile(
                      user: user,
                      isSelected: isSelected,
                      onChanged: (_) => controller.toggleRecipient(user),
                    );
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final selectedCount = controller.selectedRecipientIds.length;
            if (selectedCount == 0) {
              return const Text(
                'Select at least one recipient.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              );
            }
            return Text(
              '$selectedCount recipient(s) selected',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            );
          }),
        ],
      );
    });
  }

  Widget _buildErrorMessage() {
    return Obx(() {
      final error = controller.errorMessage.value;
      if (error.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          error,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    });
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Obx(() {
        final isLoading = controller.isSendingNotification.value;
        final canSend = controller.canSendNotification && !isLoading;
        return ElevatedButton(
          onPressed: canSend ? _handleSendPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            disabledBackgroundColor: Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Send Notification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.user,
    required this.isSelected,
    required this.onChanged,
  });

  final User user;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        user.name.isNotEmpty ? user.name : user.email,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        user.email,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
