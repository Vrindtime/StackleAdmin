import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/blocked_controller.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class BlockedManagementScreen extends StatelessWidget {
  BlockedManagementScreen({super.key});

  final BlockedController controller = Get.put(BlockedController(), permanent: false);

  @override
  Widget build(BuildContext context) {
    // Ensure AuthController exists
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 24),
                _sectionCard(
                  title: 'Blocked Users',
                  loading: controller.isLoadingUsers,
                  error: controller.userError,
                  emptyText: 'No blocked users',
                  child: Obx(() => _blockedUsersTable()),
                  onRefresh: controller.fetchBlockedUsers,
                ),
                const SizedBox(height: 32),
                _sectionCard(
                  title: 'Blocked Organisations',
                  loading: controller.isLoadingOrgs,
                  error: controller.orgError,
                  emptyText: 'No blocked organisations',
                  child: Obx(() => _blockedOrganisationsTable()),
                  onRefresh: controller.fetchBlockedOrganisations,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.lock_outline, size: 28, color: Colors.black),
        const SizedBox(width: 12),
        const Text(
          'Blocked Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh All',
            onPressed: controller.refreshAll,
            icon: const Icon(Icons.refresh, color: Colors.black)),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required RxBool loading,
    required RxString error,
    required String emptyText,
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return Obx(() {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            if (loading.value)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(error.value, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
                  ],
                ),
              )
            else if ((title.contains('User') && controller.blockedUsers.isEmpty) ||
                (title.contains('Organisation') && controller.blockedOrganisations.isEmpty))
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.lock_open, size: 42, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(emptyText, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              child,
          ],
        ),
      );
    });
  }

  Widget _blockedUsersTable() {
    return Column(
      children: [
        _tableHeader(['User ID', 'Blocked At', 'Action']),
        const Divider(height: 1),
        ...controller.blockedUsers.map((row) => _blockedUserRow(row)).toList(),
      ],
    );
  }

  Widget _blockedOrganisationsTable() {
    return Column(
      children: [
        _tableHeader(['Organisation ID', 'Blocked At', 'Action']),
        const Divider(height: 1),
        ...controller.blockedOrganisations.map((row) => _blockedOrganisationRow(row)).toList(),
      ],
    );
  }

  Widget _tableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: cols
            .map((c) => Expanded(
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _blockedUserRow(Map<String, dynamic> row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('${row['user_id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(child: Text(row['blocked_at'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await controller.unblockUser(row['user_id']);
                  if (success) Get.snackbar('Success', 'User unblocked');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('Unblock', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockedOrganisationRow(Map<String, dynamic> row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('${row['organisation_id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(child: Text(row['blocked_at'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await controller.unblockOrganisation(row['organisation_id']);
                  if (success) Get.snackbar('Success', 'Organisation unblocked');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('Unblock', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
