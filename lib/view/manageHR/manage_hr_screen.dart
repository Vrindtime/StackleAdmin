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
  // Scale factor set in build based on current constraints
  double _scale = 1.0;

  // Map width -> scale in a continuous way. Adjust min/max as needed.
  double _computeScale(double width) {
    const double minW = 360; // narrow phone
    const double maxW = 1400; // large desktop
    const double minScale = 0.85;
    const double maxScale = 1.0;
    final w = width.clamp(minW, maxW);
    final t = (w - minW) / (maxW - minW);
    return (minScale + (maxScale - minScale) * t);
  }

  @override
  void initState() {
    super.initState();
    // Use Get.find if already exists, otherwise put a new one
    if (Get.isRegistered<HRController>()) {
      hrController = Get.find<HRController>();
    } else {
      hrController = Get.put(HRController());
    }
    // Guard finding AuthController to avoid exceptions if it isn't registered
    if (Get.isRegistered<AuthController>()) {
      authController = Get.find<AuthController>();
    } else {
      // Fallback: register a new instance so widgets depending on it don't crash
      // If AuthController should be provided at app start, consider removing
      // this fallback and ensuring it's registered earlier.
      authController = Get.put(AuthController());
    }
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
          // compute a continuous scale based on width so UI scales smoothly
          _scale = _computeScale(constraints.maxWidth);

          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                      padding: EdgeInsets.all(isMobile ? 16 * _scale : 24 * _scale),
                constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (isMobile ? 32 * _scale : 48 * _scale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          _buildHeader(isMobile),
                          SizedBox(height: 24 * _scale),
                          _buildSubHeader(isMobile),
                          SizedBox(height: 24 * _scale),
                          _buildFiltersRow(isMobile),
                          SizedBox(height: 32 * _scale),
                    // Let the GridView size itself inside the outer SingleChildScrollView.
                    // Use a shrink-wrapped, non-scrollable GridView so the outer scroll view
                    // handles scrolling. This avoids a fixed height which caused cropping
                    // when resizing the window to narrower widths.
                    _buildOrganizationsGrid(isMobile, isTablet),
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
            icon: Icon(Icons.menu, size: 20 * _scale),
            onPressed: () {},
          ),
        Icon(Icons.menu, color: Colors.black54, size: 20 * _scale),
        SizedBox(width: 16 * _scale),
        Text(
          'Manage HR Organizations',
          style: TextStyle(
            fontSize: 28 * _scale,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.black54, size: 20 * _scale),
          onPressed: () {
            Get.to(() => NotificationScreen());
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
          style: TextStyle(
            fontSize: 16 * _scale,
            color: Colors.black54,
          ),
        ));
  }

  Widget _buildFiltersRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: 16 * _scale),
          Row(
            children: [
              Expanded(child: Obx(() {
                final options = ['All', 'Approved', 'Pending'];
                return _buildDropdownFromList(options, hrController.selectedFilter.value, (value) {
                  hrController.updateFilter(value!);
                });
              })),
              SizedBox(width: 8 * _scale),
              Expanded(child: Obx(() {
                final options = _daysOptions();
                return _buildDropdownFromList(options, hrController.selectedDays.value, (value) {
                  if (value != null) hrController.updateDaysFilter(value);
                });
              })),
            ],
          ),
          SizedBox(height: 8 * _scale),
          Obx(() {
            final options = _locationOptions();
            return _buildDropdownFromList(options, hrController.selectedLocation.value, (value) {
              if (value != null) hrController.updateLocationFilter(value);
            });
          }),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar()),
        SizedBox(width: 16 * _scale),
        Expanded(child: Obx(() {
          final options = ['All', 'Approved', 'Pending'];
          return _buildDropdownFromList(options, hrController.selectedFilter.value, (value) {
            hrController.updateFilter(value!);
          });
        })),
        SizedBox(width: 12 * _scale),
        Expanded(child: Obx(() {
          return _buildDropdownFromList(_locationOptions(), hrController.selectedLocation.value, (value) {
            hrController.updateLocationFilter(value!);
          });
        })),
        SizedBox(width: 12 * _scale),
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
      height: 48 * _scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * _scale),
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
      height: 48 * _scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * _scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * _scale),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20 * _scale),
          style: TextStyle(color: Colors.black87, fontSize: 14 * _scale),
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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48 * _scale, color: Colors.grey),
              SizedBox(height: 16 * _scale),
              Text(
                'No organizations found',
                style: TextStyle(fontSize: 16 * _scale, color: Colors.grey),
              ),
            ],
          ),
        );
      }

  // Compute a responsive childAspectRatio so cards can grow taller on
  // narrow screens and avoid cropping action buttons.
      double childAspectRatio;
      if (isMobile) {
        // On very narrow screens, make cards taller
        childAspectRatio = 2.4; // width / height -> larger value makes them wider, so we use >1 to allow reasonable height
      } else if (isTablet) {
        childAspectRatio = 1.6;
      } else {
        // Desktop: wider cards
        childAspectRatio = 1.25;
      }

      return GridView.builder(
        shrinkWrap: true,
        // Let the outer SingleChildScrollView handle scrolling.
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16 * _scale,
          mainAxisSpacing: 16 * _scale,
          childAspectRatio: childAspectRatio,
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
          padding: EdgeInsets.all(16 * _scale), // Same padding as professionals
          child: Column(
            // Allow the column to take the available height and make the
            // middle content flexible so the bottom action button won't be
            // pushed out or cause a tiny overflow when space is tight.
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status (same as professionals)
              Row(
                children: [
                  Text('ORG ID: ${organization.id.toString()}',
                      style: TextStyle(fontSize: 12 * _scale, color: Colors.grey[600])),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * _scale, vertical: 4 * _scale),
                    decoration: BoxDecoration(
                      color: organization.isAdminApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12 * _scale),
                    ),
                    child: Text(
                      organization.approvalStatus,
                      style: TextStyle(
                        fontSize: 10 * _scale,
                        fontWeight: FontWeight.w600,
                        color: organization.isAdminApproved ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 6 * _scale),
              
              // Profile section (like professionals)
              _buildProfileSection(organization),
              
              SizedBox(height: 8 * _scale),

              // Make details + stats flexible so they can shrink slightly when
              // vertical space is constrained, avoiding RenderFlex overflow.
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization Details Section
                    _buildOrganizationDetailsSection(organization),
                    SizedBox(height: 8 * _scale),
                    // Stats like professionals (experience and education)
                    Row(
                      children: [
                        Icon(Icons.work_outline, size: 13 * _scale, color: Colors.grey[600]),
                        SizedBox(width: 3 * _scale),
                        Text(
                          '${organization.activeJobCount} jobs',
                          style: TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Icon(Icons.people_outline, size: 13 * _scale, color: Colors.grey[600]),
                        SizedBox(width: 3 * _scale),
                        Text(
                          '${organization.requestsCount} req',
                          style: TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SizedBox(height: 6 * _scale),  

              // Responsive Action button: adapts height and font size based on
              // available card width; FittedBox ensures text scales down if needed.
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final double height = w < 180 ? 36 : 40;
                  final double fontSize = w < 180 ? 11 : (w < 260 ? 12 : 13);
                  return SizedBox(
                    width: double.infinity,
                    height: height,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDetailScreen(organization),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: organization.isAdminApproved ? Colors.blue : Colors.red,
                        side: BorderSide(color: organization.isAdminApproved ? Colors.blue : Colors.red),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          organization.isAdminApproved ? 'View Details' : 'Review & Approve',
                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
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
      radius: 22 * _scale,
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
                  size: 24 * _scale,
                  color: Colors.blue.shade600,
                )
              : null,
        ),
        SizedBox(width: 10 * _scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organization.name,
                style: TextStyle(
                  fontSize: 14 * _scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                organization.registrationNumber,
                style: TextStyle(
                  fontSize: 11 * _scale,
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
            Icon(Icons.location_history, size: 12 * _scale, color: Colors.grey[600]),
            SizedBox(width: 4 * _scale),
            Expanded(
              child: Text(
                '${organization.area}',
                style: TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * _scale),
        Row(
          children: [
            Icon(Icons.location_on, size: 12 * _scale, color: Colors.grey[600]),
            SizedBox(width: 4 * _scale),
            Expanded(
              child: Text(
                '${organization.city}, ${organization.state}',
                style: TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * _scale),
        Row(
          children: [
            Icon(Icons.email, size: 12 * _scale, color: Colors.grey[600]),
            SizedBox(width: 4 * _scale),
            Expanded(
              child: Text(
                organization.email ?? 'No email',
                style: TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
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