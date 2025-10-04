import 'package:flutter/material.dart';
import 'package:stackle_admin/widgets/side_bar.dart';

class ManageHRProfessionalsScreen extends StatefulWidget {
  const ManageHRProfessionalsScreen({Key? key}) : super(key: key);

  @override
  State<ManageHRProfessionalsScreen> createState() =>
      _ManageHRProfessionalsScreenState();
}

class _ManageHRProfessionalsScreenState
    extends State<ManageHRProfessionalsScreen> {
  String selectedSector = 'All Sector';
  String selectedPeriod = 'Last 30 days';
  String selectedLocation = 'All Location';
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), // Light yellow background
      body: Row(
        children: [
          // Sidebar - calling existing widget
          // Sidebar(
          //   isMobile: false,
          //   selectedIndex: 0,
          //   onItemSelected: (int index) {
          //     // Handle sidebar item selection
          //   },
          // ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSubHeader(),
                  const SizedBox(height: 24),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _buildHRProfessionalsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Menu Icon
        Icon(
          Icons.menu,
          size: 28,
          color: Colors.grey[800],
        ),
        const SizedBox(width: 16),
        // Title
        Text(
          'Manage HR Professionals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader() {
    return Row(
      children: [
        Text(
          'List of Registered HR Professionals',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3B8), // Light yellow
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFE066)),
          ),
          child: Row(
            children: [
              Text(
                'Total Job Provider',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF066),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '10,567',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: searchController,
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
        ),
        const SizedBox(width: 16),
        // Filters
        _buildFilterDropdown('All Sector', selectedSector, (value) {
          setState(() => selectedSector = value!);
        }),
        const SizedBox(width: 12),
        _buildFilterDropdown('Last 30 days', selectedPeriod, (value) {
          setState(() => selectedPeriod = value!);
        }),
        const SizedBox(width: 12),
        _buildFilterDropdown('All Location', selectedLocation, (value) {
          setState(() => selectedLocation = value!);
        }),
      ],
    );
  }

  Widget _buildFilterDropdown(
      String hint, String value, Function(String?) onChanged) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.white,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          items: [value].map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(color: Colors.grey[800])),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHRProfessionalsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          itemCount: 4, // Show 4 cards as in the image
          itemBuilder: (context, index) {
            return _buildHRCard();
          },
        );
      },
    );
  }

  Widget _buildHRCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with hospital image and menu
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=200&h=80&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4757),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'SH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hospital Name
            const Text(
              'Sunrise Hospital',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Contact Information
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '+91 123 456 7890',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'sunrise@gmail.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
