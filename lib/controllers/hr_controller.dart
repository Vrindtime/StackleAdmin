import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/models/organization.dart';
import '../data/services/hr_service.dart';
import '../data/models/job.dart' as job_model;

class HRController extends GetxController {
  final HRService _hrService = HRService();

  var isLoading = false.obs;
  var organizations = <Organization>[].obs;
  var filteredOrganizations = <Organization>[].obs;
  // Selected organization for details view
  var currentOrganization = Rxn<Organization>();
  var selectedFilter = 'All'.obs;
  var selectedLocation = 'All'.obs;
  var selectedDays = 'All'.obs;
  var searchQuery = ''.obs;
  // Jobs related state
  var organizationJobs = <job_model.Job>[].obs;
  var isLoadingJobs = false.obs;
  var jobsError = RxnString();
  int? _lastJobsOrgId; // Track which organization's jobs are loaded

  // Filter options
  final List<String> filterOptions = ['All', 'Approved', 'Pending'];

  @override
  void onInit() {
    super.onInit();
    fetchOrganizations();
    
    // Set up reactive listeners
    ever(selectedFilter, (_) => applyFilters());
    ever(selectedLocation, (_) => applyFilters());
    ever(selectedDays, (_) => applyFilters());
    ever(searchQuery, (_) => applyFilters());
  }

  Future<void> fetchOrganizations() async {
    try {
      isLoading.value = true;
      final fetchedOrganizations = await _hrService.getOrganizations();
      organizations.value = fetchedOrganizations;
      applyFilters();
      // Refresh current organization reference if already set
      if (currentOrganization.value != null) {
        final id = currentOrganization.value!.id;
        final refreshed = organizations.firstWhereOrNull((o) => o.id == id);
        if (refreshed != null) currentOrganization.value = refreshed;
      }
    } catch (e) {
      print('Error fetching organizations: $e');
      Get.snackbar(
        'Error',
        'Failed to load organizations: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var filtered = organizations.toList();

    // Apply status filter
    if (selectedFilter.value != 'All') {
      if (selectedFilter.value == 'Approved') {
        filtered = filtered.where((org) => org.isAdminApproved).toList();
      } else if (selectedFilter.value == 'Pending') {
        filtered = filtered.where((org) => !org.isAdminApproved).toList();
      }
    }

    // Apply location filter
    if (selectedLocation.value != 'All') {
      filtered = filtered.where((org) => 
        org.area.trim().toLowerCase() == selectedLocation.value.trim().toLowerCase()
      ).toList();
    }

    // Apply days filter
    if (selectedDays.value != 'All') {
      final now = DateTime.now();
      DateTime cutoffDate;
      
      switch (selectedDays.value) {
        case 'Last 7 days':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 days':
          cutoffDate = now.subtract(const Duration(days: 30));
          break;
        case 'Last 90 days':
          cutoffDate = now.subtract(const Duration(days: 90));
          break;
        default:
          cutoffDate = DateTime(1970); // Very old date as fallback
      }
      
      filtered = filtered.where((org) => org.createdAt.isAfter(cutoffDate)).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase().trim();
      filtered = filtered.where((org) {
        return org.name.toLowerCase().contains(query) ||
            org.area.toLowerCase().trim().contains(query) ||
            org.city.toLowerCase().contains(query) ||
            org.state.toLowerCase().contains(query);
      }).toList();
    }

    filteredOrganizations.value = filtered;
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  void updateLocationFilter(String location) {
    selectedLocation.value = location;
    applyFilters();
  }

  void updateDaysFilter(String days) {
    selectedDays.value = days;
    applyFilters();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  Future<void> approveOrganization(int organizationId) async {
    try {
      isLoading.value = true;
      final success = await _hrService.approveOrganization(organizationId);
      
      if (success) {
        // Update local data
        final index = organizations.indexWhere((org) => org.id == organizationId);
        if (index != -1) {
          final updatedOrg = Organization(
            id: organizations[index].id,
            userId: organizations[index].userId,
            name: organizations[index].name,
            area: organizations[index].area,
            city: organizations[index].city,
            state: organizations[index].state,
            country: organizations[index].country,
            pincode: organizations[index].pincode,
            phone: organizations[index].phone,
            email: organizations[index].email,
            latitude: organizations[index].latitude,
            longitude: organizations[index].longitude,
            description: organizations[index].description,
            logo: organizations[index].logo,
            registrationNumber: organizations[index].registrationNumber,
            document: organizations[index].document,
            images: organizations[index].images,
            activeJobCount: organizations[index].activeJobCount,
            requestsCount: organizations[index].requestsCount,
            searchAppearanceCount: organizations[index].searchAppearanceCount,
            isAdminApproved: true, // Update approval status
            isBlocked: organizations[index].isBlocked,
            createdAt: organizations[index].createdAt,
            updatedAt: DateTime.now(),
          );
          organizations[index] = updatedOrg;
        }
        
        applyFilters();
        if (currentOrganization.value?.id == organizationId) {
          currentOrganization.value = organizations[index];
        }
        Get.snackbar(
          'Success',
          'Organization approved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to approve organization');
      }
    } catch (e) {
      print('Error approving organization: $e');
      Get.snackbar(
        'Error',
        'Failed to approve organization: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectOrganization(int organizationId) async {
    try {
      isLoading.value = true;
      final success = await _hrService.rejectOrganization(organizationId);
      
      if (success) {
        // Update local data
        final index = organizations.indexWhere((org) => org.id == organizationId);
        if (index != -1) {
          final updatedOrg = Organization(
            id: organizations[index].id,
            userId: organizations[index].userId,
            name: organizations[index].name,
            area: organizations[index].area,
            city: organizations[index].city,
            state: organizations[index].state,
            country: organizations[index].country,
            pincode: organizations[index].pincode,
            phone: organizations[index].phone,
            email: organizations[index].email,
            latitude: organizations[index].latitude,
            longitude: organizations[index].longitude,
            description: organizations[index].description,
            logo: organizations[index].logo,
            registrationNumber: organizations[index].registrationNumber,
            document: organizations[index].document,
            images: organizations[index].images,
            activeJobCount: organizations[index].activeJobCount,
            requestsCount: organizations[index].requestsCount,
            searchAppearanceCount: organizations[index].searchAppearanceCount,
            isAdminApproved: false, // Update approval status
            isBlocked: organizations[index].isBlocked,
            createdAt: organizations[index].createdAt,
            updatedAt: DateTime.now(),
          );
          organizations[index] = updatedOrg;
        }
        
        applyFilters();
        if (currentOrganization.value?.id == organizationId) {
          currentOrganization.value = organizations[index];
        }
        Get.snackbar(
          'Success',
          'Organization rejected successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to reject organization');
      }
    } catch (e) {
      print('Error rejecting organization: $e');
      Get.snackbar(
        'Error',
        'Failed to reject organization: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<job_model.Job>> getOrganizationJobs(int organizationId) async {
    try {
      final list = await _hrService.getOrganizationJobs(organizationId);
      return list.map((e) => e).toList();
    } catch (e) {
      print('Error fetching organization jobs: $e');
      Get.snackbar(
        'Error',
        'Failed to load organization jobs: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return [];
    }
  }

  Future<void> fetchOrganizationJobs(int organizationId, {bool force = true}) async {
    try {
      if (isLoadingJobs.value) return; // prevent overlapping calls
      // Always refresh if force or org changed
      if (force || _lastJobsOrgId != organizationId) {
        organizationJobs.clear(); // remove stale immediately
        jobsError.value = null;
      } else if (!force && jobsAreForCurrentOrg && organizationJobs.isNotEmpty) {
        return; // no-op reuse
      }
      isLoadingJobs.value = true;
      final jobs = await _hrService.getOrganizationJobs(organizationId);
      organizationJobs.assignAll(jobs);
      _lastJobsOrgId = organizationId;
    } catch (e) {
      jobsError.value = e.toString();
      print('fetchOrganizationJobs error: $e');
    } finally {
      isLoadingJobs.value = false;
    }
  }

  // Update organization basic details
  Future<void> updateOrganization(int organizationId, {String? name, String? description, String? area, String? city, String? state, String? country, String? pincode, String? phone, String? email, String? latitude, String? longitude}) async {
    try {
      isLoading.value = true;
      final success = await _hrService.updateOrganization(
        organizationId: organizationId,
        name: name,
        description: description,
        area: area,
        city: city,
        state: state,
        country: country,
        pincode: pincode,
  phone: phone,
  email: email,
  latitude: latitude,
  longitude: longitude,
      );
      if (success) {
        final index = organizations.indexWhere((o) => o.id == organizationId);
        if (index != -1) {
          final existing = organizations[index];
          final updated = Organization(
            id: existing.id,
            userId: existing.userId,
            name: name ?? existing.name,
            area: area ?? existing.area,
            city: city ?? existing.city,
            state: state ?? existing.state,
            country: country ?? existing.country,
            pincode: pincode ?? existing.pincode,
            phone: phone ?? existing.phone,
            email: email ?? existing.email,
            latitude: latitude ?? existing.latitude,
            longitude: longitude ?? existing.longitude,
            description: description ?? existing.description,
            logo: existing.logo,
            registrationNumber: existing.registrationNumber,
            document: existing.document,
            images: existing.images,
            activeJobCount: existing.activeJobCount,
            requestsCount: existing.requestsCount,
            searchAppearanceCount: existing.searchAppearanceCount,
            isAdminApproved: existing.isAdminApproved,
            isBlocked: existing.isBlocked,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          );
          organizations[index] = updated;
          if (currentOrganization.value?.id == organizationId) currentOrganization.value = updated;
          applyFilters();
        }
        Get.snackbar('Updated', 'Organization updated successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        throw Exception('Backend update failed');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update organization: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> blockOrganization(int organizationId) async {
    try {
      isLoading.value = true;
      final success = await _hrService.blockOrganization(organizationId);
      if (success) {
        final index = organizations.indexWhere((o) => o.id == organizationId);
        if (index != -1) {
          final o = organizations[index];
          final updated = Organization(
            id: o.id,
            userId: o.userId,
            name: o.name,
            area: o.area,
            city: o.city,
            state: o.state,
            country: o.country,
            pincode: o.pincode,
            phone: o.phone,
            email: o.email,
            latitude: o.latitude,
            longitude: o.longitude,
            description: o.description,
            logo: o.logo,
            registrationNumber: o.registrationNumber,
            document: o.document,
            images: o.images,
            activeJobCount: o.activeJobCount,
            requestsCount: o.requestsCount,
            searchAppearanceCount: o.searchAppearanceCount,
            isAdminApproved: o.isAdminApproved,
            isBlocked: true,
            createdAt: o.createdAt,
            updatedAt: DateTime.now(),
          );
          organizations[index] = updated;
          if (currentOrganization.value?.id == organizationId) currentOrganization.value = updated;
          applyFilters();
        }
        Get.snackbar('Blocked', 'Organization blocked', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[400], colorText: Colors.white);
      } else {
        throw Exception('Failed to block');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to block organization: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unblockOrganization(int organizationId) async {
    try {
      isLoading.value = true;
      final success = await _hrService.unblockOrganization(organizationId);
      if (success) {
        final index = organizations.indexWhere((o) => o.id == organizationId);
        if (index != -1) {
          final o = organizations[index];
          final updated = Organization(
            id: o.id,
            userId: o.userId,
            name: o.name,
            area: o.area,
            city: o.city,
            state: o.state,
            country: o.country,
            pincode: o.pincode,
            phone: o.phone,
            email: o.email,
            latitude: o.latitude,
            longitude: o.longitude,
            description: o.description,
            logo: o.logo,
            registrationNumber: o.registrationNumber,
            document: o.document,
            images: o.images,
            activeJobCount: o.activeJobCount,
            requestsCount: o.requestsCount,
            searchAppearanceCount: o.searchAppearanceCount,
            isAdminApproved: o.isAdminApproved,
            isBlocked: false,
            createdAt: o.createdAt,
            updatedAt: DateTime.now(),
          );
          organizations[index] = updated;
          if (currentOrganization.value?.id == organizationId) currentOrganization.value = updated;
          applyFilters();
        }
        Get.snackbar('Unblocked', 'Organization unblocked', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        throw Exception('Failed to unblock');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to unblock organization: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Utility methods
  int get totalOrganizations => organizations.length;
  int get approvedOrganizations => organizations.where((org) => org.isAdminApproved).length;
  int get pendingOrganizations => organizations.where((org) => !org.isAdminApproved).length;
  
  // Debug method to check area data
  void debugAreas() {
    print('All areas in organizations:');
    for (final org in organizations) {
      print('  Org ${org.id}: "${org.area}" (length: ${org.area.length})');
    }
  }
  
  String get filterStatus {
    switch (selectedFilter.value) {
      case 'Approved':
        return 'Showing ${approvedOrganizations} approved organizations';
      case 'Pending':
        return 'Showing ${pendingOrganizations} pending organizations';
      default:
        return 'Showing ${totalOrganizations} total organizations';
    }
  }

  // Set the current organization when navigating to details screen
  void setCurrentOrganization(Organization org) {
    final prev = currentOrganization.value?.id;
    currentOrganization.value = org;
    if (prev == null || prev != org.id) {
      // Clear jobs when switching organizations to prevent stale display
      organizationJobs.clear();
      jobsError.value = null;
      _lastJobsOrgId = null;
    }
  }

  bool get jobsAreForCurrentOrg =>
      _lastJobsOrgId != null && currentOrganization.value?.id == _lastJobsOrgId;

  // Refresh just current organization by re-fetching list (API lacks single endpoint)
  Future<void> refreshCurrentOrganization() async {
    if (currentOrganization.value == null) return;
    await fetchOrganizations();
  }
}