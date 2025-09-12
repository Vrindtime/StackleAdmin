import 'package:flutter/material.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final List<ProfessionalRequest> requests = [
    ProfessionalRequest(
      id: '1',
      name: 'Minerva Barnett',
      isSelected: true,
      isFavorite: false,
      status: RequestStatus.pending,
      hasApprove: true,
      hasReject: true,
      timestamp: '8:13 AM',
    ),
    ProfessionalRequest(
      id: '2',
      name: 'Minerva Barnett',
      isSelected: true,
      isFavorite: false,
      status: RequestStatus.pending,
      hasApprove: true,
      hasReject: true,
      timestamp: '8:13 AM',
    ),
    ProfessionalRequest(
      id: '3',
      name: 'Minerva Barnett',
      isSelected: false,
      isFavorite: false,
      status: RequestStatus.pending,
      hasApprove: true,
      hasReject: true,
      timestamp: 'Yesterday 10:11 AM',
    ),
    ProfessionalRequest(
      id: '4',
      name: 'Minerva Barnett',
      isSelected: false,
      isFavorite: false,
      status: RequestStatus.pending,
      hasApprove: true,
      hasReject: true,
      timestamp: '10 April 2025',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Row(
        children: [
          // Sidebar (using existing widget)
          // Sidebar(
          //   isMobile: false,
          //   selectedIndex: 0,
          //   onItemSelected: (int index) {
          //     // Handle sidebar item selection
          //   },
          // ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu,
            color: Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 24),
        Text(
          'Manage Professionals',
          style: TextStyle(
            fontSize: isDesktop ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Nived Manoj',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentHeader(),
                _buildFiltersRow(context),
                _buildRequestsList(),
              ],
            ),
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 24),
          _buildTotalRequestsCard(),
        ],
      ],
    );
  }

  Widget _buildContentHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'List of Registered Medical Professionals',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown('All Sector')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterDropdown('Last 30 days')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown('All Location'),
              ],
            )
          : Row(
              children: [
                _buildFilterDropdown('All Sector'),
                const SizedBox(width: 16),
                _buildFilterDropdown('Last 30 days'),
                const SizedBox(width: 16),
                _buildFilterDropdown('All Location'),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(String text) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return Column(
      children: [
        const SizedBox(height: 24),
        ...requests.map((request) => _buildRequestRow(request)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRequestRow(ProfessionalRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: request.isSelected,
            onChanged: (value) {
              setState(() {
                request.isSelected = value ?? false;
              });
            },
            activeColor: Colors.green,
            side: BorderSide(color: Colors.grey[400]!),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.star_border,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              request.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          _buildStarRating(),
          const SizedBox(width: 20),
          if (request.hasApprove) ...[
            _buildActionButton('Approve', Colors.green, Icons.check),
            const SizedBox(width: 8),
          ],
          if (request.hasReject) ...[
            _buildActionButton('Reject', Colors.red, Icons.close),
            const SizedBox(width: 20),
          ],
          Text(
            request.timestamp,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          5,
          (index) => Icon(
                Icons.star,
                color: const Color(0xFFFFD54F),
                size: 16,
              )),
    );
  }

  Widget _buildActionButton(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            color: color,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRequestsCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Requests',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.grey[700],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '10,567',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class ProfessionalRequest {
  final String id;
  final String name;
  bool isSelected;
  bool isFavorite;
  final RequestStatus status;
  final bool hasApprove;
  final bool hasReject;
  final String timestamp;

  ProfessionalRequest({
    required this.id,
    required this.name,
    required this.isSelected,
    required this.isFavorite,
    required this.status,
    required this.hasApprove,
    required this.hasReject,
    required this.timestamp,
  });
}

enum RequestStatus {
  pending,
  approved,
  rejected,
}
