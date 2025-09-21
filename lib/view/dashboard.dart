import 'package:flutter/material.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/view/settings/notification_screen.dart';
import 'package:stackle_admin/widgets/side_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.authController});
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          bool isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

          if (isMobile) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout(isTablet, context);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      // appBar: _buildMobileAppBar(),
      drawer: Sidebar(
        authController: authController,
        isMobile: true,
        selectedIndex: 0,
        onItemSelected: (index) {
          // TODO: Handle sidebar navigation here
          print("Selected menu index: $index");
        },
      ),
      body: _buildMainContent(true),
    );
  }

  Widget _buildDesktopLayout(bool isTablet, BuildContext context) {
    return Row(
      children: [
        // Sidebar(
        //   isMobile: false,
        //   selectedIndex: 0,
        //   onItemSelected: (index) {
        //     // TODO: Handle sidebar navigation here
        //     print("Selected menu index: $index");
        //   },
        // ),
        Expanded(
          child: Column(
            children: [
              _buildDesktopTopBar(context),
              Expanded(child: _buildMainContent(false)),
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F1E8),
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 24),
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
          icon:
              Icon(Icons.notifications_outlined, color: Colors.black, size: 24),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => NotificationScreen())),
        ),
        const UserProfile(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDesktopTopBar(BuildContext context) {
    return Container(
      height: 80,
      color: const Color(0xFFF5F1E8),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Icon(Icons.menu, color: Colors.black, size: 24),
          SizedBox(width: 24),
          Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: Colors.black, size: 24),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => NotificationScreen())),
          ),
          SizedBox(width: 24),
          UserProfile(),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        children: [
          _buildStatsSection(isMobile),
          const SizedBox(height: 32),
          _buildFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    final stats = [
      StatsCardData('Total Job Provider', '10,567', Icons.people,
          const Color(0xFFFFE69C)),
      StatsCardData(
          'Total Job Seeker', '10,567', Icons.people, const Color(0xFFFFE69C)),
      StatsCardData(
          'Total Vaccancies', '10,567', Icons.people, const Color(0xFFFFE69C)),
      StatsCardData('Total Pending\nRequests', '2040', Icons.schedule,
          const Color(0xFFFFB3BA)),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: StatsCard(data: stats[0])),
              const SizedBox(width: 12),
              Expanded(child: StatsCard(data: stats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatsCard(data: stats[2])),
              const SizedBox(width: 12),
              Expanded(child: StatsCard(data: stats[3])),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: stats
            .map(
              (stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: StatsCard(data: stat),
                ),
              ),
            )
            .toList()
          ..removeLast(),
      );
    }
  }

  Widget _buildFeedbackSection() {
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
          const FeedbackHeader(),
          const FeedbackTableHeader(),
          FeedbackRow(
            name: 'Apple Watch',
            location: '6096 Marjolaine Landing',
            feedback: '6096 Marjolaine Landing',
            dateTime: '12.09.2019 - 12.53 PM',
          ),
          FeedbackRow(
            name: 'Apple',
            location: '6096 Marjolaine',
            feedback: '',
            dateTime: '12.09.2019 - 12.53 PM',
          ),
        ],
      ),
    );
  }
}

// Note: Sidebar component is now in separate file (sidebar.dart)
// The Sidebar class should be imported from 'sidebar.dart'

// User Profile Component
class UserProfile extends StatelessWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Nived Manoj',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Admin',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: NetworkImage(
                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

// Stats Card Components
class StatsCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;

  StatsCardData(this.title, this.value, this.icon, this.backgroundColor);
}

class StatsCard extends StatelessWidget {
  final StatsCardData data;

  const StatsCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data.icon,
              color: Colors.grey.shade600,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// Feedback Section Components
class FeedbackHeader extends StatelessWidget {
  const FeedbackHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Feedbacks',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'October',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackTableHeader extends StatelessWidget {
  const FeedbackTableHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderText('Name')),
          Expanded(flex: 2, child: _buildHeaderText('Location')),
          Expanded(flex: 2, child: _buildHeaderText('Feedback')),
          Expanded(flex: 2, child: _buildHeaderText('Date - Time')),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class FeedbackRow extends StatelessWidget {
  final String name;
  final String location;
  final String feedback;
  final String dateTime;

  const FeedbackRow({
    Key? key,
    required this.name,
    required this.location,
    required this.feedback,
    required this.dateTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              location,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              feedback,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateTime,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// // Data Models
// class StatsCardData {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color backgroundColor;

//   StatsCardData(this.title, this.value, this.icon, this.backgroundColor);
// }
