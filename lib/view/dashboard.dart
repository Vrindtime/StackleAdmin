import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/controllers/feedback_controller.dart';
import 'package:stackle_admin/controllers/stats_controller.dart';
import 'package:stackle_admin/data/models/feedback_model.dart';
import 'package:stackle_admin/view/settings/notification_screen.dart';
import 'package:stackle_admin/widgets/side_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.authController});
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    // Initialize FeedbackController
    Get.put(FeedbackController());
    // Initialize StatsController for admin totals
    Get.put(StatsController());
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          bool isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

          if (isMobile) {
            return _buildMobileLayout(context);
          } else {
            return _buildDesktopLayout(isTablet, context);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: _buildMobileAppBar(context),
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
    final statsController = Get.find<StatsController>();

    return Obx(() {
      if (statsController.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      // Build card data from controller totals
      final totals = statsController.totals.value;
      final stats = [
        StatsCardData('Total Job Provider', totals.totalJobProviders.toString(),
            Icons.people, const Color(0xFFFFE69C)),
        StatsCardData('Total Job Seeker', totals.totalJobSeekers.toString(),
            Icons.people, const Color(0xFFFFE69C)),
        StatsCardData('Total Vacancies', totals.totalVacancies.toString(),
            Icons.people, const Color(0xFFFFE69C)),
        StatsCardData(
            'Total Pending\nRequests',
            totals.totalPendingRequests.toString(),
            Icons.schedule,
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
    });
  }

  Widget _buildFeedbackSection() {
    final feedbackController = Get.find<FeedbackController>();

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
          FeedbackHeader(feedbackController: feedbackController),
          const FeedbackTableHeader(),
          Obx(() {
            if (feedbackController.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (feedbackController.hasError.value) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load feedbacks',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedbackController.errorMessage.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => feedbackController.fetchFeedbacks(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!feedbackController.hasFeedbacks) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.feedback_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No feedbacks available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedbackController.sortedFeedbacks.length,
              itemBuilder: (context, index) {
                final feedback = feedbackController.sortedFeedbacks[index];
                return FeedbackRow(
                  feedback: feedback,
                );
              },
            );
          }),
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
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.currentUser.value;
      return Text(
        user?.name ?? 'Loading...',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    });
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
  const FeedbackHeader({Key? key, required this.feedbackController})
      : super(key: key);

  final FeedbackController feedbackController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Recent Feedbacks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${feedbackController.feedbackCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  )),
            ],
          ),
          IconButton(
            onPressed: feedbackController.refreshFeedbacks,
            icon: Obx(() => feedbackController.isRefreshing.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh)),
            tooltip: 'Refresh feedbacks',
          ),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey.shade300),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Text(
          //         'October',
          //         style: TextStyle(
          //           color: Colors.grey.shade600,
          //           fontSize: 14,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //       const SizedBox(width: 6),
          //       Icon(
          //         Icons.keyboard_arrow_down,
          //         color: Colors.grey.shade600,
          //         size: 20,
          //       ),
          //     ],
          //   ),
          // ),
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
          // ID column (fixed width)
          const SizedBox(
              width: 64,
              child: Center(
                  child: Text('ID',
                      style: TextStyle(fontWeight: FontWeight.w600)))),
          Expanded(flex: 3, child: _buildHeaderText('Subject & User')),
          Expanded(flex: 4, child: _buildHeaderText('Message')),
          Expanded(flex: 2, child: _buildHeaderText('Date - Time')),
          const SizedBox(
              width: 64,
              child: Center(child: Text(''))), // Actions column placeholder
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
  final FeedbackModel feedback;

  const FeedbackRow({
    Key? key,
    required this.feedback,
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
          // ID at the start (fixed width)
          SizedBox(
            width: 64,
            child: Center(
              child: Text(
                feedback.id.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      feedback.userId.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.subject.isNotEmpty
                            ? feedback.subject
                            : 'No Subject',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'User ID: ${feedback.userId}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 4,
            child: Text(
              feedback.message.isNotEmpty
                  ? (feedback.message.length > 120
                      ? '${feedback.message.substring(0, 120)}...'
                      : feedback.message)
                  : 'No message',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              feedback.formattedDate,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),

          // Actions column with View and Delete
          SizedBox(
            width: 64,
            child: PopupMenuButton<String>(
              color: Colors.white,
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              onSelected: (String action) {
                if (action == 'delete') {
                  _showDeleteConfirmation(context, feedback);
                } else if (action == 'view') {
                  _showFullFeedback(context, feedback);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FeedbackModel feedback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Feedback'),
          content: Text(
              'Are you sure you want to delete the feedback from User ${feedback.userId}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                final feedbackController = Get.find<FeedbackController>();
                feedbackController.deleteFeedback(feedback.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFullFeedback(BuildContext context, FeedbackModel feedback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title:
              Text(feedback.subject.isNotEmpty ? feedback.subject : 'Feedback'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From user: ${feedback.userId}',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(feedback.message.isNotEmpty
                    ? feedback.message
                    : 'No message provided.'),
                const SizedBox(height: 12),
                Text('Created: ${feedback.formattedDate}',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
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
