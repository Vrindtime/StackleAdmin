import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/professional_controller.dart';
import 'package:stackle_admin/controllers/stats_controller.dart';
import 'package:stackle_admin/controllers/user_controller.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/data/models/client.dart';
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/view/manage_Professionals/professional_details_screen.dart';
import 'package:stackle_admin/core/api_base.dart';
import 'dart:math' as math;

  String _resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    final trimmed = url.trim();
    final baseRoot = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final path = uri.path;
      final mediaIndex = path.indexOf('/media/');
      if (mediaIndex != -1) {
        final rel = path.substring(mediaIndex + '/media/'.length);
        return '${baseRoot.replaceAll(RegExp(r'\/+\$'), '')}/media/$rel';
      }
      try {
        final baseHost = Uri.parse(baseRoot).host;
        if (uri.host == baseHost) return trimmed;
      } catch (_) {}
      return trimmed;
    }

    if (trimmed.startsWith('/media/')) {
      return '${baseRoot.replaceAll(RegExp(r'\/+\$'), '')}$trimmed';
    }

    final idx = trimmed.indexOf('/media/');
    if (idx != -1) {
      final rel = trimmed.substring(idx + '/media/'.length);
      return '${baseRoot.replaceAll(RegExp(r'\/+\$'), '')}/media/$rel';
    }

    final rel = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${baseRoot.replaceAll(RegExp(r'\/+\$'), '')}/media/$rel';
  }

class ManageProfessionalsScreen extends StatefulWidget {
  const ManageProfessionalsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProfessionalsScreen> createState() =>
      _ManageProfessionalsScreenState();
}

class _ManageProfessionalsScreenState extends State<ManageProfessionalsScreen> {
  late ProfessionalController professionalController;
  late StatsController statsController;
  late UserController userController;
  late AuthController authController;
  
  // Cache for user data to avoid repeated API calls
  final Map<int, User?> _userCache = {};

  double _computeScale(double width) {
    const double baseWidth = 1200;
    double scale = width / baseWidth;
    const double minScale = 0.7;
    const double maxScale = 1.07;
    scale = math.max(minScale, math.min(maxScale, scale));
    // Apply non-linear easing for smoother scaling
    scale = math.pow(scale, 0.8) as double;
    return scale;
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    professionalController = Get.put(ProfessionalController());
    statsController = Get.isRegistered<StatsController>() 
        ? Get.find<StatsController>() 
        : Get.put(StatsController());
    // Use Get.find or Get.put with permanent flag to avoid conflicts
    userController = Get.isRegistered<UserController>() 
        ? Get.find<UserController>() 
        : Get.put(UserController(), permanent: true);
    authController = Get.find<AuthController>();
    
    // Preload user data when clients are loaded
    _setupUserDataListener();
    // Ensure displayedClients updates when allClients loads so dropdowns can be built
    ever(professionalController.allClients, (_) => setState(() {}));
  }

  List<String> _sectorOptions() {
    final set = <String>{};
    set.add('All');
    for (final c in professionalController.allClients) {
      if (c.preferredJob != null && c.preferredJob!.isNotEmpty) set.add(c.preferredJob!);
    }
    return set.toList();
  }

  List<String> _locationOptions() {
    final set = <String>{};
    set.add('All');
    for (final c in professionalController.allClients) {
      if (c.place != null && c.place!.isNotEmpty) set.add(c.place!);
    }
    return set.toList();
  }

  List<String> _daysOptions() {
    return ['All', 'Last 7 days', 'Last 30 days', 'Last 90 days'];
  }

  void _setupUserDataListener() {
    // Listen to changes in client list and preload user data
    ever(professionalController.allClients, (List<Client> clients) {
      _preloadUserData(clients);
    });
  }

  void _preloadUserData(List<Client> clients) {
    // Preload user data for first 20 clients to improve UX
    final clientsToPreload = clients.take(20).toList();
    for (final client in clientsToPreload) {
      if (!_userCache.containsKey(client.userId)) {
        _fetchUserData(client.userId);
      }
    }
  }

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
          // FIND SCALE MAIN
          double scale = _computeScale(constraints.maxWidth) * 0.78;

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
                child: _buildMainContent(isMobile, isTablet, isDesktop, scale, constraints.maxWidth),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet, bool isDesktop, double scale, double maxWidth) {
    return Container(
      padding: EdgeInsets.all((isMobile ? 16 : 24) * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile, scale),
          SizedBox(height: 24 * scale),
          _buildSubHeader(isMobile, scale, maxWidth),
          SizedBox(height: 24 * scale),
          _buildFiltersRow(isMobile, scale),
          SizedBox(height: 32 * scale),
          Expanded(
            child: _buildProfessionalsGrid(isMobile, isTablet, scale, maxWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, double scale) {
    return Row(
      children: [
        Text(
          'Manage Professionals',
          style: TextStyle(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        // const Spacer(),
        // IconButton(
        //   icon: Icon(Icons.notifications_outlined, color: Colors.black54, size: 24 * scale),
        //   onPressed: () {},
        // ),
        // SizedBox(width: 16 * scale),
        // Obx(() {
        //   final user = authController.currentUser.value;
        //   return Row(
        //     children: [
        //       Text(
        //         user?.name ?? 'Loading...',
        //         style: TextStyle(
        //           fontSize: 16 * scale,
        //           fontWeight: FontWeight.w500,
        //           color: Colors.black87,
        //         ),
        //       ),
        //       SizedBox(width: 12 * scale),
        //       CircleAvatar(
        //         radius: 20 * scale,
        //         backgroundColor: Colors.grey[300],
        //         child: user?.name != null 
        //             ? Text(
        //                 user!.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
        //                 style: TextStyle(
        //                   color: Colors.white,
        //                   fontWeight: FontWeight.bold,
        //                   fontSize: 14 * scale,
        //                 ),
        //               )
        //             : Icon(Icons.person, color: Colors.white, size: 16 * scale),
        //       ),
        //     ],
        //   );
        // }),
      ],
    );
  }

  Widget _buildSubHeader(bool isMobile, double scale, double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              professionalController.currentFilterText,
              style: TextStyle(
                fontSize: 21 * scale,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            )),
            const SizedBox(height: 4),
            Obx(() => Text(
              '${professionalController.displayedClients.length} professionals',
              style: TextStyle(
                fontSize: 16 * scale,
                color: Colors.grey[600],
              ),
            )),
          ],
        ),
        width < 450 ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter buttons in a row
            Wrap(
              spacing: 8 * scale,
              runSpacing: 8 * scale,
              children: [
                _buildFilterButton('All', ProfessionalFilter.all, scale*1.2),
                _buildFilterButton('Approved', ProfessionalFilter.approved, scale),
                _buildFilterButton('Rejected', ProfessionalFilter.rejected, scale),
              ],
            ),
            SizedBox(height: 16 * scale),
            // Total professionals display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4B8), // Light yellow background
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Professionals',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700), // Gold background
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Obx(() => Text(
                      statsController.totals.value.totalJobSeekers.toString(),
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ) : Row(
          children: [
            // Filter buttons
            _buildFilterButton('All', ProfessionalFilter.all, scale),
            SizedBox(width: 8 * scale),
            _buildFilterButton('Approved', ProfessionalFilter.approved, scale),
            SizedBox(width: 8 * scale),
            _buildFilterButton('Rejected', ProfessionalFilter.rejected, scale),
            SizedBox(width: 16 * scale),
            // Total professionals display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4B8), // Light yellow background
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Professionals',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700), // Gold background
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Obx(() => Text(
                      statsController.totals.value.totalJobSeekers.toString(),
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(String text, ProfessionalFilter filter, double scale) {
    scale = scale * 1.4;
    return Obx(() => ElevatedButton(
      onPressed: () => professionalController.applyFilter(filter),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: professionalController.currentFilter.value == filter
            ? Colors.black87
            : Colors.grey[600],
        side: BorderSide(
          color: professionalController.currentFilter.value == filter
              ? Colors.black87
              : Colors.grey[300]!,
          width: professionalController.currentFilter.value == filter ? 2 : 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        minimumSize: Size(0, 36 * scale),
        elevation: 0,
      ),
      child: Text(text, style: TextStyle(fontSize: 12 * scale)),
    ));
  }

  Widget _buildFiltersRow(bool isMobile, double scale) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchBar(scale),
          SizedBox(height: 16 * scale),
          Row(
            children: [
              Expanded(child: Obx(() {
                final options = _sectorOptions();
                return _buildDropdownFromList(options, professionalController.selectedSector.value, (value) {
                  professionalController.selectedSector.value = value!;
                }, scale);
              })),
              SizedBox(width: 8 * scale),
              Expanded(child: Obx(() {
                final options = _daysOptions();
                return _buildDropdownFromList(options, professionalController.selectedDays.value, (value) {
                  professionalController.selectedDays.value = value!;
                }, scale);
              })),
            ],
          ),
          SizedBox(height: 8 * scale),
          Obx(() {
            final options = _locationOptions();
            return _buildDropdownFromList(options, professionalController.selectedLocation.value, (value) {
              professionalController.selectedLocation.value = value!;
            }, scale);
          }),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar(scale)),
        SizedBox(width: 16 * scale),
        Expanded(child: Obx(() {
          final options = _sectorOptions();
          return _buildDropdownFromList(options, professionalController.selectedSector.value, (value) {
            professionalController.selectedSector.value = value!;
          }, scale);
        })),
        SizedBox(width: 12 * scale),
        Expanded(child: Obx(() {
          final options = _daysOptions();
          return _buildDropdownFromList(options, professionalController.selectedDays.value, (value) {
            professionalController.selectedDays.value = value!;
          }, scale);
        })),
        SizedBox(width: 12 * scale),
        Expanded(child: Obx(() {
          final options = _locationOptions();
          return _buildDropdownFromList(options, professionalController.selectedLocation.value, (value) {
            professionalController.selectedLocation.value = value!;
          }, scale);
        })),
      ],
    );
  }

  Widget _buildSearchBar(double scale) {
    return Container(
      height: 48 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        onChanged: (value) => professionalController.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search professionals...',
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 24 * scale),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
        ),
      ),
    );
  }

  Widget _buildDropdownFromList(List<String> options, String value, Function(String?) onChanged, double scale) {
    final safeOptions = options.isNotEmpty ? options : ['All'];
    final safeValue = safeOptions.contains(value) ? value : safeOptions.first;

    return Container(
      height: 48 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24 * scale),
          style: TextStyle(color: Colors.black87, fontSize: 14 * scale),
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

  Widget _buildProfessionalsGrid(bool isMobile, bool isTablet, double scale, double width) {
    int crossAxisCount;
    if (width < 1000) {
      crossAxisCount = 1; // mobile
    } else if (width < 1350) {
      crossAxisCount = 2; // tablet
    } else if (width < 1500) {
      crossAxisCount = 3; // medium desktop
    } else {
      crossAxisCount = 4; // large desktop
    }

    double childAspectRatio = 1.44;
    
    if (width < 350) {
      childAspectRatio = 1.5;
    } else if (width < 480) {
      childAspectRatio = 1.8;
    } else if (width < 870) {
      childAspectRatio = 2.5;
    } else if (width < 1100) {
      childAspectRatio = 3.3;
    } else if (width < 1100) {
      childAspectRatio = 2;
    } else if (width < 1300) {
      childAspectRatio = 1.8;
    } else {
      childAspectRatio = 1.64;
    }

    return Obx(() {
      if (professionalController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (professionalController.hasError.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48 * scale, color: Colors.grey[400]),
              SizedBox(height: 16 * scale),
              Text(
                'Failed to load professionals',
                style: TextStyle(fontSize: 16 * scale, color: Colors.grey[600]),
              ),
              SizedBox(height: 16 * scale),
              ElevatedButton(
                onPressed: () => professionalController.fetchAllClients(),
                child: Text('Retry', style: TextStyle(fontSize: 14 * scale)),
              ),
            ],
          ),
        );
      }

      if (professionalController.displayedClients.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48 * scale, color: Colors.grey),
              SizedBox(height: 16 * scale),
              Text(
                'No professionals found',
                style: TextStyle(fontSize: 16 * scale, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Bulk actions bar
          if (professionalController.isSelectionMode.value)
            _buildBulkActionsBar(scale),
          
          // Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16 * scale,
                mainAxisSpacing: 16 * scale,
                // childAspectRatio: isMobile ? .02 : 1.4, // Adjusted for user info section
                childAspectRatio: childAspectRatio
              ),
              itemCount: professionalController.displayedClients.length,
              itemBuilder: (context, index) {
                final client = professionalController.displayedClients[index];
                return _buildClientCard(client, scale);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBulkActionsBar(double scale) {
    return Container(
      padding: EdgeInsets.all(26 * scale),
      margin: EdgeInsets.only(bottom: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Obx(() => Text(
            '${professionalController.selectedCount} selected',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14 * scale),
          )),
          const Spacer(),
          TextButton(
            onPressed: () => professionalController.selectAll(),
            child: Text('Select All', style: TextStyle(color: Colors.black87, fontSize: 14 * scale)),
          ),
          SizedBox(width: 12 * scale),
          ElevatedButton(
            onPressed: professionalController.selectedCount > 0
                ? () => _showBulkApprovalDialog()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              elevation: 0,
            ),
            child: Text('Bulk Approve', style: TextStyle(fontSize: 14 * scale)),
          ),
          SizedBox(width: 8 * scale),
          TextButton(
            onPressed: () => professionalController.clearSelection(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14 * scale)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client, double scale) {
    return GestureDetector(
      onLongPress: () => professionalController.toggleSelectionMode(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * scale),
          border: professionalController.isSelected(client.clientId)
              ? Border.all(color: Colors.blue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14 * scale), // Reduced padding from 16 to 14
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with selection checkbox and status
              Row(
                children: [
                  if (professionalController.isSelectionMode.value)
                    Obx(() => Checkbox(
                      value: professionalController.isSelected(client.clientId),
                      onChanged: (bool? value) {
                        professionalController.toggleSelection(client.clientId);
                      },
                    )),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: client.isAdminApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Text(
                      client.approvalStatus,
                      style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                        color: client.isAdminApproved ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 6 * scale), // Reduced spacing
              
              // Profile section with user name from API
              _buildProfileSection(client, scale),
              
              SizedBox(height: 8 * scale), // Reduced spacing
              
              // User Details Section
              _buildUserDetailsSection(client, scale),
              
              SizedBox(height: 8 * scale), // Reduced spacing
              
              // Experience and Education count
              Row(
                children: [
                  Icon(Icons.work_outline, size: 13 * scale, color: Colors.grey[600]),
                  SizedBox(width: 3 * scale),
                  Text(
                    '${client.experiences.length} exp',
                    style: TextStyle(fontSize: 18 * scale, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.school_outlined, size: 13 * scale, color: Colors.grey[600]),
                  SizedBox(width: 3 * scale),
                  Text(
                    '${client.education.length} edu',
                    style: TextStyle(fontSize: 18 * scale, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              SizedBox(height: 12 * scale), // Reduced spacing
              
              // Action button with increased height
              SizedBox(
                width: double.infinity,
                height: 40 * scale, // Increased height from default
                child: ElevatedButton(
                  onPressed: () => _navigateToDetailScreen(client),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: client.isAdminApproved ? Colors.blue : Colors.red,
                    side: BorderSide(color: client.isAdminApproved ? Colors.blue : Colors.red),
                    elevation: 0,
                  ),
                  child: Text(
                    client.isAdminApproved ? 'View Details' : 'Review & Approve',
                    style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailsSection(Client client, double scale) {
    // Check if we already have user data cached
    if (_userCache.containsKey(client.userId)) {
      final user = _userCache[client.userId];
      if (user != null) {
        return _buildUserInfo(user, scale);
      } else {
        return _buildUserInfoPlaceholder(scale);
      }
    }

    // Fetch user data if not cached
    _fetchUserData(client.userId);
    return _buildUserInfoPlaceholder(scale);
  }

  Widget _buildProfileSection(Client client, double scale) {
    // Check if we have user data cached
    final user = _userCache[client.userId];
    
    return Row(
      children: [
        CircleAvatar(
          radius: 22 * scale,
          backgroundImage: (() {
            final img = client.image ?? '';
            if (img.isEmpty) return null;
            final resolved = _resolveMediaUrl(img);
            try {
              return NetworkImage(resolved);
            } catch (_) {
              return null;
            }
          })(),
          backgroundColor: Colors.blue[100],
          child: (client.image == null || client.image!.isEmpty)
              ? Text(
                  user?.name.isNotEmpty == true 
                      ? user!.name[0].toUpperCase() 
                      : 'P', // Default to 'P' for Professional
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scale),
                )
              : null,
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Professional ${client.clientId}',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                client.location.isNotEmpty ? client.location : 'N/A',
                style: TextStyle(
                  fontSize: 16 * scale,
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

  Widget _buildUserInfo(User user, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2 * scale),
          Row(
            children: [
              Icon(Icons.numbers, size: 14 * scale, color: Colors.grey[600]),
              SizedBox(width: 4 * scale),
              Expanded(
                child: Text(
                  'ID: ${user.id}',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.email, size: 14 * scale, color: Colors.grey[600]),
              SizedBox(width: 4 * scale),
              Expanded(
                child: Text(
                  user.email.isNotEmpty ? user.email : 'N/A',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Row(
            children: [
              Icon(Icons.phone, size: 14 * scale, color: Colors.grey[600]),
              SizedBox(width: 4 * scale),
              Expanded(
                child: Text(
                  user.phone.isNotEmpty ? user.phone : 'N/A',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoPlaceholder(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 12 * scale, color: Colors.grey[400]),
              SizedBox(width: 4 * scale),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Row(
            children: [
              Icon(Icons.phone, size: 12 * scale, color: Colors.grey[400]),
              SizedBox(width: 4 * scale),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Row(
            children: [
              Icon(Icons.badge, size: 12 * scale, color: Colors.grey[400]),
              SizedBox(width: 4 * scale),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserData(int userId) async {
    if (_userCache.containsKey(userId)) return; // Already fetching or cached
    
    try {
      // Mark as being fetched
      _userCache[userId] = null;
      
      // Create a new UserController instance for this fetch
      final tempUserController = UserController();
      await tempUserController.fetchUserById(userId);
      
      if (tempUserController.user.value != null) {
        setState(() {
          _userCache[userId] = tempUserController.user.value;
          // Also add to professional controller for search
          professionalController.addUserToCache(userId, tempUserController.user.value!);
          // Refresh search results if there's an active search
          if (professionalController.searchQuery.value.isNotEmpty) {
            professionalController.updateSearchQuery(professionalController.searchQuery.value);
          }
        });
      } else {
        // If no user data, create a placeholder user with N/A values
        final placeholderUser = User(
          id: userId,
          name: 'N/A',
          email: 'N/A',
          phone: 'N/A',
          role: 'N/A',
          deviceId: 'N/A',
        );
        setState(() {
          _userCache[userId] = placeholderUser;
          // Also add to professional controller for search
          professionalController.addUserToCache(userId, placeholderUser);
          // Refresh search results if there's an active search
          if (professionalController.searchQuery.value.isNotEmpty) {
            professionalController.updateSearchQuery(professionalController.searchQuery.value);
          }
        });
      }
    } catch (e) {
      // If fetch fails, create a placeholder user with N/A values
      final placeholderUser = User(
        id: userId,
        name: 'N/A',
        email: 'N/A',
        phone: 'N/A',
        role: 'N/A',
        deviceId: 'N/A',
      );
      setState(() {
        _userCache[userId] = placeholderUser;
        // Also add to professional controller for search
        professionalController.addUserToCache(userId, placeholderUser);
        // Refresh search results if there's an active search
        if (professionalController.searchQuery.value.isNotEmpty) {
          professionalController.updateSearchQuery(professionalController.searchQuery.value);
        }
      });
      print('Failed to fetch user data for user $userId: $e');
    }
  }

  void _navigateToDetailScreen(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalDetailScreen(client: client),
      ),
    );
  }



  void _showBulkApprovalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Bulk Approve'),
          content: Obx(() => Text('Are you sure you want to approve ${professionalController.selectedCount} professionals?')),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                elevation: 0,
              ),
              child: const Text('Approve All'),
              onPressed: () {
                Navigator.of(context).pop();
                professionalController.bulkApproveSelected();
              },
            ),
          ],
        );
      },
    );
  }



}
