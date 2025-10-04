import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/data/models/client.dart';
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/data/services/professional_service.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

enum ProfessionalFilter { all, approved, rejected }

class ProfessionalController extends GetxController {
  final ProfessionalService _service = ProfessionalService();

  // Observables for different data sets
  var allClients = <Client>[].obs;
  var approvedClients = <Client>[].obs;
  var pendingClients = <Client>[].obs;
  var rejectedClients = <Client>[].obs;
  var displayedClients = <Client>[].obs; // Currently shown clients based on filter

  // User data cache for search functionality
  final Map<int, User?> userCache = {};

  // Individual client for detail view
  var currentClient = Rxn<Client>();
  var isLoadingClient = false.obs;

  // UI state
  var isLoading = false.obs;
  var isLoadingAction = false.obs; // For approve/reject actions
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Filter and search
  var currentFilter = ProfessionalFilter.all.obs;
  var searchQuery = ''.obs;
  // Use 'All' so it matches options produced by the UI helpers and means "no filter"
  var selectedSector = 'All'.obs;
  var selectedLocation = 'All'.obs;
  var selectedDays = 'All'.obs;

  // Selection for bulk operations
  var selectedClientIds = <int>[].obs;
  var isSelectionMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllClients();
    // Recompute displayed clients whenever filter selections change so UI updates immediately
    ever(selectedSector, (_) => _updateDisplayedClients());
    ever(selectedLocation, (_) => _updateDisplayedClients());
    ever(selectedDays, (_) => _updateDisplayedClients());
    ever(searchQuery, (_) => _updateDisplayedClients());
  }

  /// Fetch all clients
  Future<void> fetchAllClients() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final clients = await _service.getAllClients(token: token);
      allClients.assignAll(clients);
      
      // Update filter-specific lists
      approvedClients.assignAll(clients.where((c) => c.isAdminApproved).toList());
      pendingClients.assignAll(clients.where((c) => !c.isAdminApproved).toList());
      // Rejected clients are those not approved by admin
      // In future, this could be based on a separate rejection status field
      rejectedClients.assignAll(clients.where((c) => !c.isAdminApproved).toList());
      
      _updateDisplayedClients();
      
      print('ProfessionalController: Fetched ${clients.length} clients');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('ProfessionalController: fetchAllClients error: $e');
      
      Get.snackbar(
        "Error",
        "Failed to load professionals: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch only approved clients
  Future<void> fetchApprovedClients() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final clients = await _service.getApprovedClients(token: token);
      approvedClients.assignAll(clients);
      
      if (currentFilter.value == ProfessionalFilter.approved) {
        _updateDisplayedClients();
      }
    } catch (e) {
      print('ProfessionalController: fetchApprovedClients error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch only pending clients
  Future<void> fetchPendingClients() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final clients = await _service.getPendingApprovalClients(token: token);
      pendingClients.assignAll(clients);
      
      if (currentFilter.value == ProfessionalFilter.rejected) {
        _updateDisplayedClients();
      }
    } catch (e) {
      print('ProfessionalController: fetchPendingClients error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve a single client
  Future<bool> approveClient(int clientId) async {
    try {
      isLoadingAction.value = true;

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final success = await _service.approveClient(clientId, token: token);
      
      if (success) {
        // Update local data
        _updateClientApprovalStatus(clientId, true);
        return true;
      }
      return false;
    } catch (e) {
      print('ProfessionalController: approveClient error: $e');
      Get.snackbar(
        "Error",
        "Failed to approve professional: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoadingAction.value = false;
    }
  }

  /// Reject a single client
  Future<bool> rejectClient(int clientId) async {
    try {
      isLoadingAction.value = true;

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final success = await _service.rejectClient(clientId, token: token);
      
      if (success) {
        // Update local data
        _updateClientApprovalStatus(clientId, false);
        return true;
      }
      return false;
    } catch (e) {
      print('ProfessionalController: rejectClient error: $e');
      Get.snackbar(
        "Error",
        "Failed to reject professional: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoadingAction.value = false;
    }
  }

  /// Bulk approve selected clients
  Future<void> bulkApproveSelected() async {
    if (selectedClientIds.isEmpty) return;

    try {
      isLoadingAction.value = true;

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final success = await _service.bulkApproveClients(selectedClientIds.toList(), token: token);
      
      if (success) {
        // Update local data for all selected clients
        for (int clientId in selectedClientIds) {
          _updateClientApprovalStatus(clientId, true);
        }
        
        clearSelection();
        
        Get.snackbar(
          "Success",
          "Successfully approved ${selectedClientIds.length} professionals",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('ProfessionalController: bulkApproveSelected error: $e');
      Get.snackbar(
        "Error",
        "Failed to bulk approve professionals: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingAction.value = false;
    }
  }

  /// Update client approval status in local data
  void _updateClientApprovalStatus(int clientId, bool isApproved) {
    // Update in all lists
    _updateClientInList(allClients, clientId, isApproved);
    _updateClientInList(approvedClients, clientId, isApproved);
    _updateClientInList(pendingClients, clientId, isApproved);
    
    // Remove from old list and add to new list
    if (isApproved) {
      final client = pendingClients.firstWhereOrNull((c) => c.clientId == clientId);
      if (client != null) {
        pendingClients.removeWhere((c) => c.clientId == clientId);
        approvedClients.add(client);
      }
    } else {
      final client = approvedClients.firstWhereOrNull((c) => c.clientId == clientId);
      if (client != null) {
        approvedClients.removeWhere((c) => c.clientId == clientId);
        pendingClients.add(client);
      }
    }
    
    _updateDisplayedClients();

    final current = currentClient.value;
    if (current != null && current.clientId == clientId) {
      currentClient.value = Client(
        clientId: current.clientId,
        userId: current.userId,
        isKycVerified: current.isKycVerified,
        isAdminApproved: isApproved,
        preferredJob: current.preferredJob,
        dob: current.dob,
        gender: current.gender,
        place: current.place,
        district: current.district,
        state: current.state,
        pincode: current.pincode,
        latitude: current.latitude,
        longitude: current.longitude,
        resume: current.resume,
        image: current.image,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
        experiences: current.experiences,
        certificates: current.certificates,
        education: current.education,
        languages: current.languages,
        description: current.description,
      );
    }
  }

  void _updateClientInList(RxList<Client> list, int clientId, bool isApproved) {
    final index = list.indexWhere((c) => c.clientId == clientId);
    if (index != -1) {
      // Create updated client object
      final client = list[index];
      final updatedClient = Client(
        clientId: client.clientId,
        userId: client.userId,
        isKycVerified: client.isKycVerified,
        isAdminApproved: isApproved,
        preferredJob: client.preferredJob,
        dob: client.dob,
        gender: client.gender,
        place: client.place,
        district: client.district,
        state: client.state,
        pincode: client.pincode,
        latitude: client.latitude,
        longitude: client.longitude,
        resume: client.resume,
        image: client.image,
        createdAt: client.createdAt,
        updatedAt: DateTime.now(),
        experiences: client.experiences,
        certificates: client.certificates,
        education: client.education,
        languages: client.languages,
        description: client.description,
      );
      list[index] = updatedClient;
    }
  }

  /// Apply filter
  void applyFilter(ProfessionalFilter filter) {
    currentFilter.value = filter;
    _updateDisplayedClients();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _updateDisplayedClients();
  }

  /// Update displayed clients based on current filter and search
  void _updateDisplayedClients() {
    List<Client> baseList;
    
    switch (currentFilter.value) {
      case ProfessionalFilter.approved:
        baseList = approvedClients.toList();
        break;
      case ProfessionalFilter.rejected:
        baseList = rejectedClients.toList();
        break;
      case ProfessionalFilter.all:
        baseList = allClients.toList();
        break;
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      baseList = baseList.where((client) {
        return client.clientId.toString().contains(query) ||
               client.userId.toString().contains(query) ||
               client.location.toLowerCase().contains(query) ||
               client.preferredJob?.toLowerCase().contains(query) == true ||
               client.description?.toLowerCase().contains(query) == true ||
               client.place?.toLowerCase().contains(query) == true ||
               client.district?.toLowerCase().contains(query) == true ||
               client.state?.toLowerCase().contains(query) == true ||
               _userNameMatches(client.userId, query); // Search by user name/email/phone
      }).toList();
    }

    // Apply selectedDays filter (Last X days) using createdAt. 'All' means no date filter.
    if (selectedDays.value.isNotEmpty && selectedDays.value.toLowerCase() != 'all') {
      final daysMatch = RegExp(r'Last\s+(\d+)', caseSensitive: false).firstMatch(selectedDays.value);
      if (daysMatch != null) {
        final days = int.tryParse(daysMatch.group(1) ?? '30') ?? 30;
        final cutoff = DateTime.now().subtract(Duration(days: days));
        baseList = baseList.where((c) => c.createdAt.isAfter(cutoff)).toList();
      }
    }

    // Apply selectedSector filter using preferredJob. Treat 'all' (case-insensitive) as no filter.
    final sectorVal = selectedSector.value.trim().toLowerCase();
    if (sectorVal.isNotEmpty && sectorVal != 'all') {
      baseList = baseList.where((c) => c.preferredJob?.toLowerCase().contains(sectorVal) == true).toList();
    }

    // Apply selectedLocation filter using place. Treat 'all' as no filter.
    final locationVal = selectedLocation.value.trim().toLowerCase();
    if (locationVal.isNotEmpty && locationVal != 'all') {
      baseList = baseList.where((c) => c.place?.toLowerCase().contains(locationVal) == true).toList();
    }

    displayedClients.assignAll(baseList);
  }

  /// Selection methods for bulk operations
  void toggleSelection(int clientId) {
    if (selectedClientIds.contains(clientId)) {
      selectedClientIds.remove(clientId);
    } else {
      selectedClientIds.add(clientId);
    }
    
    if (selectedClientIds.isEmpty) {
      isSelectionMode.value = false;
    }
  }

  void selectAll() {
    selectedClientIds.assignAll(displayedClients.map((c) => c.clientId).toList());
    isSelectionMode.value = true;
  }

  void clearSelection() {
    selectedClientIds.clear();
    isSelectionMode.value = false;
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedClientIds.clear();
    }
  }

  /// Getters
  int get totalClients => allClients.length;
  int get totalApproved => approvedClients.length;
  int get totalPending => pendingClients.length;
  int get selectedCount => selectedClientIds.length;
  
  bool isSelected(int clientId) => selectedClientIds.contains(clientId);
  
  String get currentFilterText {
    switch (currentFilter.value) {
      case ProfessionalFilter.approved:
        return 'Approved Professionals';

      case ProfessionalFilter.rejected:
        return 'Rejected Professionals';
      case ProfessionalFilter.all:
        return 'All Professionals';
    }
  }

  /// Add user data to cache for search functionality
  void addUserToCache(int userId, User user) {
    userCache[userId] = user;
  }

  /// Get user from cache
  User? getUserFromCache(int userId) {
    return userCache[userId];
  }

  /// Fetch individual client by ID for detail view
  Future<void> fetchClientById(int clientId) async {
    try {
      isLoadingClient.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final client = await _service.getClientById(clientId, token: token);
      currentClient.value = client;
      
      // Also update the client in the main lists if it exists
      _updateClientInAllLists(client);
      
      print('ProfessionalController: Fetched client ${client.clientId}');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('ProfessionalController: fetchClientById error: $e');
      
      Get.snackbar(
        "Error",
        "Failed to load client details: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoadingClient.value = false;
    }
  }

  /// Update client profile with optimized refresh
  Future<bool> updateClientProfile({
    required int clientId,
    required String preferredJob,
    required String description,
    required String place,
    required String district,
    required String state,
    required String pincode,
  }) async {
    try {
      isLoadingAction.value = true;

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final success = await _service.updateClientProfile(
        clientId: clientId,
        token: token,
        preferredJob: preferredJob,
        description: description,
        place: place,
        district: district,
        state: state,
        pincode: pincode,
      );

      if (success) {
        // Instead of refreshing entire list, just refresh this specific client
        await fetchClientById(clientId);
        
        Get.snackbar(
          "Success",
          "Profile updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('ProfessionalController: updateClientProfile error: $e');
      Get.snackbar(
        "Error",
        "Failed to update profile: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoadingAction.value = false;
    }
  }

  /// Update a specific client in all lists (for when we have fresh data)
  void _updateClientInAllLists(Client updatedClient) {
    final clientId = updatedClient.clientId;
    
    // Update in all clients list
    final allIndex = allClients.indexWhere((c) => c.clientId == clientId);
    if (allIndex != -1) {
      allClients[allIndex] = updatedClient;
    }
    
    // Update in approved/pending lists based on current status
    if (updatedClient.isAdminApproved) {
      // Remove from pending, add/update in approved
      pendingClients.removeWhere((c) => c.clientId == clientId);
      final approvedIndex = approvedClients.indexWhere((c) => c.clientId == clientId);
      if (approvedIndex != -1) {
        approvedClients[approvedIndex] = updatedClient;
      } else {
        approvedClients.add(updatedClient);
      }
    } else {
      // Remove from approved, add/update in pending
      approvedClients.removeWhere((c) => c.clientId == clientId);
      final pendingIndex = pendingClients.indexWhere((c) => c.clientId == clientId);
      if (pendingIndex != -1) {
        pendingClients[pendingIndex] = updatedClient;
      } else {
        pendingClients.add(updatedClient);
      }
    }
    
    // Update rejected list (same as pending for now)
    rejectedClients.removeWhere((c) => c.clientId == clientId);
    if (!updatedClient.isAdminApproved) {
      rejectedClients.add(updatedClient);
    }
    
    // Refresh displayed clients
    _updateDisplayedClients();
  }

  /// Check if user name matches search query
  bool _userNameMatches(int userId, String query) {
    final user = userCache[userId];
    if (user == null) return false;
    
    return user.name.toLowerCase().contains(query) ||
           user.email.toLowerCase().contains(query) ||
           user.phone.toLowerCase().contains(query);
  }
}