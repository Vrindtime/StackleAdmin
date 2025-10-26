import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/blocked_controller.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/core/routing.dart';
import 'package:stackle_admin/view/settings/notification_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:stackle_admin/core/api_base.dart';

class BlockedUsersListScreen extends StatefulWidget {
  const BlockedUsersListScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersListScreen> createState() => _BlockedUsersListScreenState();
}

class _BlockedUsersListScreenState extends State<BlockedUsersListScreen> {
  late final BlockedController blockedController;
  String searchQuery = '';
  bool _hydrating = false; // background hydration flag

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    blockedController = Get.put(BlockedController(), permanent: false);
    // After first frame attempt hydration of entries missing nested user
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateMissingUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige background
      body: Row(
        children: [
          // Sidebar - using previously created widget
          //  const Sidebar(),

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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: _buildBlockedUsersContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Menu icon and title
        Row(
          children: [
            // Icon(
            //   Icons.menu,
            //   color: Colors.black87,
            //   size: 24,
            // ),
            // const SizedBox(width: 16),
            Text(
              'Blocked Users',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Right side - notification bell 
        Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap:(){
                   Get.toNamed(AppRoutes.notificationScreen);
                },
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildBlockedUsersContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blocked Users List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search blocked users...',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.black54,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Users count
          Obx(() => Text(
              'Total Blocked Users: ${_filteredBlocked().length}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            )),

          const SizedBox(height: 16),

          // Users list
          Expanded(child: Obx(() {
            if (blockedController.isLoadingUsers.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (blockedController.userError.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      blockedController.userError.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: blockedController.fetchBlockedUsers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final data = _filteredBlocked();
            if (data.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No blocked users'),
                ],
              );
            }
            return _buildUsersList(data);
          })),
        ],
      ),
    );
  }
  List<Map<String, dynamic>> _filteredBlocked() {
    final list = blockedController.blockedUsers;
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((row) {
      final idStr = row['user_id']?.toString() ?? '';
      if (idStr.contains(q)) return true;
      final user = row['user'] as Map<String, dynamic>?;
      if (user != null) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final role = (user['role'] ?? '').toString().toLowerCase();
        if (name.contains(q) || email.contains(q) || role.contains(q)) return true;
      }
      final client = row['client'] as Map<String, dynamic>?;
      if (client != null) {
        final pref = (client['preferred_job'] ?? '').toString().toLowerCase();
        if (pref.contains(q)) return true;
      }
      return false;
    }).toList();
  }

  Widget _buildUsersList(List<Map<String, dynamic>> data) {
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildUserCard(data[index]),
    );
  }

  Future<void> _hydrateMissingUsers() async {
    if (_hydrating) return;
    final auth = Get.find<AuthController>();
    final missing = blockedController.blockedUsers
        .where((e) => e['user'] == null && e['user_id'] != null)
        .take(10) // limit to avoid burst
        .toList();
    if (missing.isEmpty) return;
    try {
      _hydrating = true;
      await auth.checkAndRefreshToken();
      final token = auth.accessToken.value;
      // We re-use user_service via a lightweight inline import to avoid adding dependency here
      // Instead of importing service (already imported earlier in other file), perform batched sequential fetch
      for (final row in missing) {
        try {
          final userId = row['user_id'];
          final resp = await http.get(Uri.parse('$baseUrl/auth/user/$userId'), headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          });
          if (resp.statusCode == 200) {
            final parsed = json.decode(resp.body);
            row['user'] = parsed; // mutate in place, GetX will detect because list reference stays but nested map changes; force refresh
          }
        } catch (_) {}
      }
      if (mounted) setState(() {});
    } catch (_) {
      // silently ignore hydration errors
    } finally {
      _hydrating = false;
    }
  }

  Widget _buildUserCard(Map<String, dynamic> row) {
    final userId = row['user_id'] as int;
    final blockedAt = row['blocked_at'];
    final userMap = row['user'] as Map<String, dynamic>?;
    // Trigger hydration for this single row if user missing (lazy fallback)
    if (userMap == null) {
      _lazyFetchUser(userId);
    }
    final name = userMap != null ? (userMap['name'] ?? 'User #$userId').toString() : 'User #$userId';
    final email = userMap != null ? (userMap['email'] ?? '').toString() : '';
    final role = userMap != null ? (userMap['role'] ?? '').toString() : '';
  final client = row['client'] as Map<String, dynamic>?; // may be null
  final preferredJob = client != null ? (client['preferred_job'] ?? '').toString() : '';
  final initials = name
    .split(' ')
    .where((e) => e.isNotEmpty)
    .take(2)
    .map((e) => e[0])
    .join()
    .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),

          const SizedBox(width: 16),

          // User details
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text('ID: $userId', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  if (role.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(role, style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                    ),
                  if (preferredJob.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(preferredJob, style: const TextStyle(fontSize: 10, color: Colors.green)),
                    ),
                ],
              ),
            ],
          )),

          // Block reason and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Blocked',
                  style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _relativeTime(blockedAt),
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              if (userMap == null)
                Padding(
                  padding: const EdgeInsets.only(top:4),
                  child: SizedBox(
                    height: 22,
                    child: TextButton(
                      onPressed: () => _lazyFetchUser(userId, force: true),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60,22)),
                      child: const Text('Load', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                )
            ],
          ),

          const SizedBox(width: 16),

          // Action buttons
          Row(
            children: [
              _buildActionButton(
                Icons.visibility,
                'View',
                Colors.blue,
                () => _viewDialog(row),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.lock_open,
                'Unblock',
                Colors.green,
                () => _unblockUser(userId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, Color color, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  void _unblockUser(int userId) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Unblock User'),
              content: Text('Are you sure you want to unblock user #$userId?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final success = await blockedController.unblockUser(userId);
                    if (mounted) Navigator.pop(context);
                    if (success) {
                      Get.snackbar('Success', 'User unblocked');
                      setState(() {});
                    } else {
                      Get.snackbar('Error', 'Failed to unblock');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Unblock'),
                ),
              ],
            ),
          );
        }

  String _relativeTime(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return timeago.format(dt, allowFromNow: true);
  }

  void _lazyFetchUser(int userId, {bool force = false}) {
    if (_hydrating && !force) return; // avoid spamming
    final row = blockedController.blockedUsers.firstWhereOrNull((e) => e['user_id'] == userId);
    if (row == null || (row['user'] != null && !force)) return;
    () async {
      try {
        final auth = Get.find<AuthController>();
        await auth.checkAndRefreshToken();
        final token = auth.accessToken.value;
        final resp = await http.get(Uri.parse('$baseUrl/auth/user/$userId'), headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        });
        if (resp.statusCode == 200) {
          row['user'] = json.decode(resp.body);
          if (mounted) setState(() {});
        }
      } catch (_) {}
    }();
  }

  void _viewDialog(Map<String, dynamic> row) {
    final user = row['user'] as Map<String, dynamic>?;
    final client = row['client'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Blocked User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${row['user_id']}'),
            if (user != null) ...[
              Text('Name: ${user['name']}'),
              Text('Email: ${user['email']}'),
              Text('Role: ${user['role']}'),
            ],
            if (client != null) ...[
              Text('Preferred Job: ${client['preferred_job']}'),
              Text('Client Approved: ${client['isAdminApproved']}'),
            ],
            Text('Blocked At: ${row['blocked_at'] ?? '-'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

// Responsive wrapper for different screen sizes
class ResponsiveBlockedUsersListScreen extends StatelessWidget {
  const ResponsiveBlockedUsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          // Mobile layout
          return _buildMobileLayout(context);
        } else if (constraints.maxWidth < 1024) {
          // Tablet layout
          return _buildTabletLayout(context);
        } else {
          // Desktop layout
          return const BlockedUsersListScreen();
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        // leading: Builder(
        //   builder: (context) => IconButton(
        //     icon: const Icon(Icons.menu, color: Colors.black87),
        //     onPressed: () => Scaffold.of(context).openDrawer(),
        //   ),
        // ),
        title: Text(
          'Blocked Users',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ],
      ),
      // drawer: Drawer(
      //   child: const Sidebar(),
      // ),
      body: const BlockedUsersListScreen(),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Row(
        children: [
          // Sidebar for tablet
          // Container(
          //   width: 240,
          //   child: const Sidebar(),
          // ),

          // Main content
          const Expanded(
            child: BlockedUsersListScreen(),
          ),
        ],
      ),
    );
  }
}
