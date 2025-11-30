import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/view/settings/notification_screen.dart';
import '../../controllers/hr_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/organization.dart';
import '../../core/routing.dart';
import 'hr_details_screen.dart';

class ManageHRScreen extends StatefulWidget {
  const ManageHRScreen({Key? key}) : super(key: key);

  @override
  State<ManageHRScreen> createState() => _ManageHRScreenState();
}

class _ManageHRScreenState extends State<ManageHRScreen> {
  late HRController hrController;
  late AuthController authController;
  double _scale = 1.0;

  double _computeScale(double width) {
    const double minW = 360;
    const double maxW = 1400;
    const double minScale = 0.85;
    const double maxScale = 1.0;
    final w = width.clamp(minW, maxW);
    final t = (w - minW) / (maxW - minW);
    return (minScale + (maxScale - minScale) * t);
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<HRController>()) {
      hrController = Get.find<HRController>();
    } else {
      hrController = Get.put(HRController());
    }
    if (Get.isRegistered<AuthController>()) {
      authController = Get.find<AuthController>();
    } else {
      authController = Get.put(AuthController());
    }
  }

  List<String> _locationOptions() {
    final Map<String, String> areaMap = {};
    areaMap['all'] = 'All';

    for (final org in hrController.organizations) {
      if (org.area.isNotEmpty) {
        final normalized = org.area.trim().toLowerCase();
        if (normalized.isNotEmpty && !areaMap.containsKey(normalized)) {
          areaMap[normalized] = org.area.trim();
        }
      }
    }

    final list = areaMap.values.toList();
    list.sort((a, b) => a == 'All'
        ? -1
        : (b == 'All' ? 1 : a.toLowerCase().compareTo(b.toLowerCase())));
    return list;
  }

  List<String> _daysOptions() {
    return ['All', 'Last 7 days', 'Last 30 days', 'Last 90 days'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          bool isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1240;
          _scale = _computeScale(constraints.maxWidth);

          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 16 * _scale : 14 * _scale),
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      (isMobile ? 32 * _scale : 48 * _scale),
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
        Flexible(
          child: Text(
            'Manage HR Organizations',
            style: TextStyle(
              fontSize: 16 * _scale,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: Colors.black54, size: 20 * _scale),
          onPressed: () {
            Get.toNamed(AppRoutes.notificationScreen);
          },
        ),
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
                return _buildDropdownFromList(
                    options, hrController.selectedFilter.value, (value) {
                  hrController.updateFilter(value!);
                });
              })),
              SizedBox(width: 8 * _scale),
              Expanded(child: Obx(() {
                final options = _daysOptions();
                return _buildDropdownFromList(
                    options, hrController.selectedDays.value, (value) {
                  if (value != null) hrController.updateDaysFilter(value);
                });
              })),
            ],
          ),
          SizedBox(height: 8 * _scale),
          Obx(() {
            final options = _locationOptions();
            return _buildDropdownFromList(
                options, hrController.selectedLocation.value, (value) {
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
          return _buildDropdownFromList(
              options, hrController.selectedFilter.value, (value) {
            hrController.updateFilter(value!);
          });
        })),
        SizedBox(width: 12 * _scale),
        Expanded(child: Obx(() {
          return _buildDropdownFromList(
              _locationOptions(), hrController.selectedLocation.value, (value) {
            hrController.updateLocationFilter(value!);
          });
        })),
        SizedBox(width: 12 * _scale),
        Expanded(child: Obx(() {
          return _buildDropdownFromList(
              _daysOptions(), hrController.selectedDays.value, (value) {
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
        decoration: InputDecoration(
          hintText: 'Search organizations...',
          hintStyle: TextStyle(fontSize: 14 * _scale),
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20 * _scale),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16 * _scale, vertical: 12 * _scale),
        ),
        style: TextStyle(fontSize: 14 * _scale),
      ),
    );
  }

  Widget _buildDropdownFromList(
      List<String> options, String value, Function(String?) onChanged) {
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
          icon: Icon(Icons.keyboard_arrow_down,
              color: Colors.grey, size: 20 * _scale),
          style: TextStyle(color: Colors.black87, fontSize: 14 * _scale),
          dropdownColor: Colors.white,
          items: safeOptions.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrganizationsGrid(bool isMobile, bool isTablet) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (width < 1100) {
      crossAxisCount = 1;
    } else if (width < 1250) {
      crossAxisCount = 2;
    } else if (width < 1700) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    double childAspectRatio = 1.64 * _scale;
    if (width < 350) {
      childAspectRatio = 1.6 * _scale;
    } else if (width < 480) {
      childAspectRatio = 2 * _scale;
    } else if (width < 870) {
      childAspectRatio = 2.5 * _scale;
    } else if (width < 1100) {
      childAspectRatio = 3.3 * _scale;
    } else if (width < 1300) {
      childAspectRatio = 1.8 * _scale;
    } else {
      childAspectRatio = 1.64 * _scale;
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

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(12 * _scale),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8 * _scale,
          mainAxisSpacing: 8 * _scale,
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
      onLongPress: () {},
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
          padding: EdgeInsets.all(8 * _scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'ORG ID: ${organization.id.toString()}',
                      style: TextStyle(
                          fontSize: 12 * _scale, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8 * _scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8 * _scale, vertical: 4 * _scale),
                    decoration: BoxDecoration(
                      color: organization.isAdminApproved
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12 * _scale),
                    ),
                    child: Text(
                      organization.approvalStatus,
                      style: TextStyle(
                        fontSize: 10 * _scale,
                        fontWeight: FontWeight.w600,
                        color: organization.isAdminApproved
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 6 * _scale),

              // Profile section
              _buildProfileSection(organization),

              SizedBox(height: 8 * _scale),

              // Details section - wrapped in Flexible to prevent overflow
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization Details Section
                    _buildOrganizationDetailsSection(organization),
                    SizedBox(height: 8 * _scale),
                    // Stats
                    Row(
                      children: [
                        Icon(Icons.work_outline,
                            size: 13 * _scale, color: Colors.grey[600]),
                        SizedBox(width: 3 * _scale),
                        Flexible(
                          child: Text(
                            '${organization.activeJobCount} jobs',
                            style: TextStyle(
                                fontSize: 11 * _scale, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8 * _scale),
                        Icon(Icons.people_outline,
                            size: 13 * _scale, color: Colors.grey[600]),
                        SizedBox(width: 3 * _scale),
                        Flexible(
                          child: Text(
                            '${organization.requestsCount} req',
                            style: TextStyle(
                                fontSize: 11 * _scale, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 6 * _scale),

              // Action button
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final double height = (w < 180 ? 36 : 40) * _scale;
                  final double fontSize =
                      (w < 180 ? 11 : (w < 260 ? 12 : 13)) * _scale;
                  return SizedBox(
                    width: double.infinity,
                    height: height,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDetailScreen(organization),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: organization.isAdminApproved
                            ? Colors.blue
                            : Colors.red,
                        side: BorderSide(
                            color: organization.isAdminApproved
                                ? Colors.blue
                                : Colors.red),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 8 * _scale),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          organization.isAdminApproved
                              ? 'View Details'
                              : 'Review & Approve',
                          style: TextStyle(
                              fontSize: fontSize, fontWeight: FontWeight.w600),
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
            return img.isNotEmpty ? NetworkImage(img) : null;
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
            mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_history,
                size: 12 * _scale, color: Colors.grey[600]),
            SizedBox(width: 4 * _scale),
            Expanded(
              child: Text(
                organization.area,
                style:
                    TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
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
                style:
                    TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
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
                style:
                    TextStyle(fontSize: 11 * _scale, color: Colors.grey[600]),
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
    Get.toNamed(AppRoutes.hrDetails, arguments: organization);
  }
}