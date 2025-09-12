import 'package:flutter/material.dart';

class ManageProfessionalsScreen extends StatefulWidget {
  const ManageProfessionalsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProfessionalsScreen> createState() =>
      _ManageProfessionalsScreenState();
}

class _ManageProfessionalsScreenState extends State<ManageProfessionalsScreen> {
  String selectedSector = 'All Sector';
  String selectedDays = 'Last 30 days';
  String selectedLocation = 'All Location';
  String searchQuery = '';

  final List<Professional> professionals = [
    Professional(
      name: 'Ramesh',
      location: 'Kochi, Kerala',
      phone: '+91 123 456 7890',
      email: 'sunrise@gmail.com',
      avatar: 'https://via.placeholder.com/60',
      isOnline: true,
    ),
    Professional(
      name: 'Ramesh',
      location: 'Kochi, Kerala',
      phone: '+91 123 456 7890',
      email: 'sunrise@gmail.com',
      avatar: 'https://via.placeholder.com/60',
      isOnline: true,
    ),
    Professional(
      name: 'Ramesh',
      location: 'Kochi, Kerala',
      phone: '+91 123 456 7890',
      email: 'sunrise@gmail.com',
      avatar: 'https://via.placeholder.com/60',
      isOnline: true,
    ),
    Professional(
      name: 'Sunrise Hospital',
      location: 'Kochi, Kerala',
      phone: '+91 123 456 7890',
      email: 'sunrise@gmail.com',
      avatar: 'https://via.placeholder.com/60',
      isOnline: true,
    ),
    Professional(
      name: 'Charlote B Erwin',
      location: 'New Mexico, Kochi, Kerala',
      phone: '',
      email: '',
      avatar: 'https://via.placeholder.com/60',
      isOnline: false,
      rating: 2.2,
      hasViewChat: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Cream background
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          bool isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          bool isDesktop = constraints.maxWidth >= 1024;

          return Row(
            children: [
              // // Sidebar - only show on desktop and tablet
              // if (!isMobile)
              //   const SizedBox(
              //     width: 250,
              //     child: Sidebar(), // Your existing sidebar widget
              //   ),

              // // Main content
              Expanded(
                child: _buildMainContent(isMobile, isTablet, isDesktop),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          _buildSubHeader(isMobile),
          const SizedBox(height: 24),
          _buildFiltersRow(isMobile),
          const SizedBox(height: 32),
          Expanded(
            child: _buildProfessionalsGrid(isMobile, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Handle mobile menu
            },
          ),
        const Icon(Icons.menu, color: Colors.black54),
        const SizedBox(width: 16),
        const Text(
          'Manage Professionals',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
          onPressed: () {},
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            const Text(
              'Nived Manoj',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Admin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'List of Registered Medical Professionals',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4B8), // Light yellow background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Professionals',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700), // Gold background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '10,567',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildDropdown('All Sector', selectedSector, (value) {
                setState(() => selectedSector = value!);
              })),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDropdown('Last 30 days', selectedDays, (value) {
                setState(() => selectedDays = value!);
              })),
            ],
          ),
          const SizedBox(height: 8),
          _buildDropdown('All Location', selectedLocation, (value) {
            setState(() => selectedLocation = value!);
          }),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar()),
        const SizedBox(width: 16),
        Expanded(
            child: _buildDropdown('All Sector', selectedSector, (value) {
          setState(() => selectedSector = value!);
        })),
        const SizedBox(width: 12),
        Expanded(
            child: _buildDropdown('Last 30 days', selectedDays, (value) {
          setState(() => selectedDays = value!);
        })),
        const SizedBox(width: 12),
        Expanded(
            child: _buildDropdown('All Location', selectedLocation, (value) {
          setState(() => selectedLocation = value!);
        })),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String hint, String value, Function(String?) onChanged) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          items: [value].map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProfessionalsGrid(bool isMobile, bool isTablet) {
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 4;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 0.85,
      ),
      itemCount: professionals.length,
      itemBuilder: (context, index) {
        final professional = professionals[index];

        if (index == 4) {
          // Charlote B Erwin card
          return _buildSpecialProfessionalCard(professional);
        }

        return _buildProfessionalCard(professional);
      },
    );
  }

  Widget _buildProfessionalCard(Professional professional) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 30),
                    ),
                    if (professional.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              professional.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              professional.location,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (professional.phone.isNotEmpty)
              _buildContactInfo(Icons.phone, professional.phone),
            const SizedBox(height: 8),
            if (professional.email.isNotEmpty)
              _buildContactInfo(Icons.email, professional.email),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialProfessionalCard(Professional professional) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orange[100],
              child: const Icon(Icons.person, color: Colors.orange, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              professional.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              professional.location,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${professional.rating} yr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String info) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            info,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class Professional {
  final String name;
  final String location;
  final String phone;
  final String email;
  final String avatar;
  final bool isOnline;
  final double? rating;
  final bool hasViewChat;

  Professional({
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
    required this.avatar,
    required this.isOnline,
    this.rating,
    this.hasViewChat = false,
  });
}
