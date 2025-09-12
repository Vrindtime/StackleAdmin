import 'package:flutter/material.dart';

class BlockedUsersListScreen extends StatefulWidget {
  const BlockedUsersListScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersListScreen> createState() => _BlockedUsersListScreenState();
}

class _BlockedUsersListScreenState extends State<BlockedUsersListScreen> {
  // Sample blocked users data
  final List<BlockedUser> blockedUsers = [
    BlockedUser(
      id: '1',
      name: 'John Smith',
      email: 'john.smith@email.com',
      organization: 'Tech Corp',
      blockedDate: DateTime.now().subtract(const Duration(days: 5)),
      reason: 'Inappropriate behavior',
      avatarColor: const Color(0xFFFFE4E4),
      textColor: const Color(0xFFFF6B6B),
    ),
    BlockedUser(
      id: '2',
      name: 'Sarah Johnson',
      email: 'sarah.johnson@company.com',
      organization: 'Healthcare Inc',
      blockedDate: DateTime.now().subtract(const Duration(days: 12)),
      reason: 'Spam activities',
      avatarColor: const Color(0xFFE4F0FF),
      textColor: const Color(0xFF4A90E2),
    ),
    BlockedUser(
      id: '3',
      name: 'Michael Brown',
      email: 'michael.brown@business.org',
      organization: 'Business Solutions',
      blockedDate: DateTime.now().subtract(const Duration(days: 8)),
      reason: 'Policy violation',
      avatarColor: const Color(0xFFE8F5E8),
      textColor: const Color(0xFF4CAF50),
    ),
    BlockedUser(
      id: '4',
      name: 'Emily Davis',
      email: 'emily.davis@startup.com',
      organization: 'StartUp Hub',
      blockedDate: DateTime.now().subtract(const Duration(days: 20)),
      reason: 'Multiple warnings',
      avatarColor: const Color(0xFFFFF4E6),
      textColor: const Color(0xFFFF9800),
    ),
    BlockedUser(
      id: '5',
      name: 'David Wilson',
      email: 'david.wilson@enterprise.net',
      organization: 'Enterprise Ltd',
      blockedDate: DateTime.now().subtract(const Duration(days: 3)),
      reason: 'Terms of service breach',
      avatarColor: const Color(0xFFF3E5F5),
      textColor: const Color(0xFF9C27B0),
    ),
  ];

  String searchQuery = '';

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
            Icon(
              Icons.menu,
              color: Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 16),
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

        // Right side - notification bell and user profile
        Row(
          children: [
            Container(
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
            const SizedBox(width: 16),

            // User profile section
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Nived Manoj',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          Text(
            'Total Blocked Users: ${_getFilteredUsers().length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Users list
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  List<BlockedUser> _getFilteredUsers() {
    if (searchQuery.isEmpty) {
      return blockedUsers;
    }
    return blockedUsers.where((user) {
      return user.name.toLowerCase().contains(searchQuery) ||
          user.email.toLowerCase().contains(searchQuery) ||
          user.organization.toLowerCase().contains(searchQuery);
    }).toList();
  }

  Widget _buildUsersList() {
    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No blocked users found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(BlockedUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: user.avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name
                    .split(' ')
                    .map((e) => e[0])
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: user.textColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.organization,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Block reason and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFD32F2F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(user.blockedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
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
                () => _viewUser(user),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.block_outlined,
                'Unblock',
                Colors.green,
                () => _unblockUser(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String tooltip, Color color, VoidCallback onPressed) {
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
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else if (difference < 30) {
      return '${(difference / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _viewUser(BlockedUser user) {
    // Show user details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            Text('Organization: ${user.organization}'),
            Text('Blocked Date: ${_formatDate(user.blockedDate)}'),
            Text('Reason: ${user.reason}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _unblockUser(BlockedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                blockedUsers.removeWhere((u) => u.id == user.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} has been unblocked successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Unblock'),
          ),
        ],
      ),
    );
  }
}

// Model class for blocked user
class BlockedUser {
  final String id;
  final String name;
  final String email;
  final String organization;
  final DateTime blockedDate;
  final String reason;
  final Color avatarColor;
  final Color textColor;

  BlockedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.organization,
    required this.blockedDate,
    required this.reason,
    required this.avatarColor,
    required this.textColor,
  });
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
