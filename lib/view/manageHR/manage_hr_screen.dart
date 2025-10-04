import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/view/settings/notification_screen.dart';
import '../../controllers/hr_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/organization.dart';
import 'hr_details_screen.dart';

String _resolveMediaUrl(String url) {
  if (url.isEmpty) return url;
  final trimmed = url.trim();
  if (trimmed.toLowerCase() == 'string') return ''; // placeholder from example payloads
  const baseRoot = 'https://stackle-djangoapp-t6rn9w-e998d7-31-97-237-244.traefik.me';

  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final path = uri.path;
    final mediaIndex = path.indexOf('/media/');
    if (mediaIndex != -1) {
      final rel = path.substring(mediaIndex + '/media/'.length);
      return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
    }
    try {
      if (Uri.parse(baseRoot).host == uri.host) return trimmed;
    } catch (_) {}
    return trimmed; // external host
  }

  if (trimmed.startsWith('/media/')) {
    return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}$trimmed';
  }
  final idx = trimmed.indexOf('/media/');
  if (idx != -1) {
    final rel = trimmed.substring(idx + '/media/'.length);
    return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
  }
  final rel = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
}

class ManageHRScreen extends StatefulWidget {
  const ManageHRScreen({Key? key}) : super(key: key);

  @override
  State<ManageHRScreen> createState() => _ManageHRScreenState();
}

class _ManageHRScreenState extends State<ManageHRScreen> {
  late HRController hrController;
  late AuthController authController;

  @override
  void initState() {
    super.initState();
    // Use Get.find if already exists, otherwise put a new one
    if (Get.isRegistered<HRController>()) {
      hrController = Get.find<HRController>();
    } else {
      hrController = Get.put(HRController());
    }
    authController = Get.find<AuthController>();
  }

  List<String> _locationOptions() {
    final Map<String, String> areaMap = {}; // normalized -> display
    areaMap['all'] = 'All';
    
    for (final org in hrController.organizations) {
      if (org.area.isNotEmpty) {
        final normalized = org.area.trim().toLowerCase();
        if (normalized.isNotEmpty && !areaMap.containsKey(normalized)) {
          // Use the first occurrence's case as the display value
          areaMap[normalized] = org.area.trim();
        }
      }
    }
    
    final list = areaMap.values.toList();
    list.sort((a, b) => a == 'All' ? -1 : (b == 'All' ? 1 : a.toLowerCase().compareTo(b.toLowerCase())));
    return list;
  }

  List<String> _daysOptions() {
    return ['All', 'Last 7 days', 'Last 30 days', 'Last 90 days'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Cream background
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          bool isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (isMobile ? 32 : 48),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 24),
                    _buildSubHeader(isMobile),
                    const SizedBox(height: 24),
                    _buildFiltersRow(isMobile),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: constraints.maxHeight - (isMobile ? 300 : 280),
                      child: _buildOrganizationsGrid(isMobile, isTablet),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        const Icon(Icons.menu, color: Colors.black54),
        const SizedBox(width: 16),
        const Text(
          'Manage HR Organizations',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
          onPressed: () {
            Get.to(()=>NotificationScreen());
          },
        ),
        // const SizedBox(width: 16),
        // Obx(() {
        //   final user = authController.currentUser.value;
        //   return Row(
        //     children: [
        //       CircleAvatar(
        //         radius: 20,
        //         backgroundColor: Colors.blue,
        //         child: Text(
        //           user?.name.isNotEmpty == true
        //               ? user!.name[0].toUpperCase()
        //               : 'A',
        //           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        //         ),
        //       ),
        //       const SizedBox(width: 12),
        //       Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             user?.name ?? 'Admin',
        //             style: const TextStyle(fontWeight: FontWeight.w500),
        //           ),
        //           Text(
        //             user?.email ?? 'admin@example.com',
        //             style: const TextStyle(fontSize: 12, color: Colors.grey),
        //           ),
        //         ],
        //       ),
        //     ],
        //   );
        // }),
      ],
    );
  }

  Widget _buildSubHeader(bool isMobile) {
    return Obx(() => Text(
      hrController.filterStatus,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black54,
      ),
    ));
  }

  Widget _buildFiltersRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Obx(() {
                final options = ['All', 'Approved', 'Pending'];
                return _buildDropdownFromList(options, hrController.selectedFilter.value, (value) {
                  hrController.updateFilter(value!);
                });
              })),
              const SizedBox(width: 8),
              Expanded(child: Obx(() {
                final options = _daysOptions();
                return _buildDropdownFromList(options, 'All', (value) {
                  // Handle days filter
                });
              })),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final options = _locationOptions();
            return _buildDropdownFromList(options, 'All', (value) {
              // Handle location filter
            });
          }),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar()),
        const SizedBox(width: 16),
        Expanded(child: Obx(() {
          final options = ['All', 'Approved', 'Pending'];
          return _buildDropdownFromList(options, hrController.selectedFilter.value, (value) {
            hrController.updateFilter(value!);
          });
        })),
        const SizedBox(width: 12),
        Expanded(child: Obx(() {
          return _buildDropdownFromList(_locationOptions(), hrController.selectedLocation.value, (value) {
            hrController.updateLocationFilter(value!);
          });
        })),
        const SizedBox(width: 12),
        Expanded(child: Obx(() {
          return _buildDropdownFromList(_daysOptions(), hrController.selectedDays.value, (value) {
            hrController.updateDaysFilter(value!);
          });
        })),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        onChanged: (value) => hrController.updateSearchQuery(value),
        decoration: const InputDecoration(
          hintText: 'Search organizations...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownFromList(List<String> options, String value, Function(String?) onChanged) {
    final safeOptions = options.isNotEmpty ? options : ['All'];
    final safeValue = safeOptions.contains(value) ? value : safeOptions.first;

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
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          items: safeOptions.map((String item) {
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

  Widget _buildOrganizationsGrid(bool isMobile, bool isTablet) {
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 4;
    }

    return Obx(() {
      if (hrController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (hrController.filteredOrganizations.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No organizations found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 0.8 : 1.6, // Adjusted for better fit
        ),
        itemCount: hrController.filteredOrganizations.length,
        itemBuilder: (context, index) {
          final organization = hrController.filteredOrganizations[index];
          return _buildOrganizationCard(organization);
        },
      );
    });
  }

  Widget _buildOrganizationCard(Organization organization) {
    return GestureDetector(
      onLongPress: () {
        // Toggle selection mode like professionals
      },
      child: Container(
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
          padding: const EdgeInsets.all(14), // Same padding as professionals
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status (same as professionals)
              Row(
                children: [
                  Text('ORG ID: ${organization.id.toString()}',style: TextStyle(fontSize: 12,color: Colors.grey[600]),),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: organization.isAdminApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      organization.approvalStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: organization.isAdminApproved ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Profile section (like professionals)
              _buildProfileSection(organization),
              
              const SizedBox(height: 8),
              
              // Organization Details Section
              _buildOrganizationDetailsSection(organization),
              
              const SizedBox(height: 8),
              
              // Stats like professionals (experience and education)
              Row(
                children: [
                  Icon(Icons.work_outline, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 3),
                  Text(
                    '${organization.activeJobCount} jobs',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.people_outline, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 3),
                  Text(
                    '${organization.requestsCount} req',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action button (same style as professionals)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _navigateToDetailScreen(organization),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: organization.isAdminApproved ? Colors.blue : Colors.red,
                    side: BorderSide(color: organization.isAdminApproved ? Colors.blue : Colors.red),
                    elevation: 0,
                  ),
                  child: Text(
                    organization.isAdminApproved ? 'View Details' : 'Review & Approve',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(Organization organization) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: (() {
            final img = organization.logo ?? '';
            if (img.isEmpty) return null;
            if (img.toLowerCase() == 'string') return null; // placeholder skip
            final resolved = _resolveMediaUrl(img);
            if (resolved.isEmpty) return null;
            return NetworkImage(resolved);
          })(),
          backgroundColor: Colors.blue.shade100,
          child: (organization.logo == null || organization.logo!.isEmpty)
              ? Icon(
                  Icons.business,
                  size: 24,
                  color: Colors.blue.shade600,
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organization.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                organization.registrationNumber,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationDetailsSection(Organization organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_history, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${organization.area}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${organization.city}, ${organization.state}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.email, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                organization.email ?? 'No email',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToDetailScreen(Organization organization) {
    Get.to(() => HrDetailsScreen(organization: organization));
  }
}