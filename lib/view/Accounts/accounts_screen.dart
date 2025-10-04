import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/user_controller.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late UserController userController;
  late AuthController authController;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Edit mode state
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Use Get.find or Get.put with permanent flag to avoid conflicts
    userController = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : Get.put(UserController(), permanent: true);
    authController = Get.find<AuthController>();

    // Fetch current user data on load if not already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.currentUser.value == null) {
        authController.fetchCurrentUser();
      } else {
        // Sync local currentUser with global one
        userController.currentUser.value = authController.currentUser.value;
      }
    });

    // Listen to global currentUser changes to update form controllers
    // Only update if controllers are not disposed
    ever(authController.currentUser, (user) {
      if (user != null && mounted) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
        // Also sync with local controller
        userController.currentUser.value = user;
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers safely
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    final user = authController.currentUser.value;
    if (user == null) return;

    try {
      // Validate input
      if (_nameController.text.trim().isEmpty) {
        Get.snackbar(
          "Error",
          "Name cannot be empty",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (_emailController.text.trim().isEmpty) {
        Get.snackbar(
          "Error",
          "Email cannot be empty",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Update user via controller
      final success = await userController.updateUser(
        userId: user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: user.role, // Keep the same role
      );

      if (success) {
        setState(() {
          _isEditMode = false;
        });

        // Force refresh the UI by triggering an update
        if (mounted) {
          setState(() {}); // This will trigger a rebuild with updated data
        }

        Get.snackbar(
          "Success",
          "Profile updated successfully",
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update profile: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Row(
        children: [
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                if (authController.currentUser.value == null &&
                    userController.isLoadingCurrentUser.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (userController.hasError.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load profile',
                          style:
                              TextStyle(fontSize: 18, color: Colors.red[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userController.errorMessage.value,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => authController.fetchCurrentUser(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildMainContent(context),
                  ],
                );
              }),
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
          'Account',
          style: TextStyle(
            fontSize: isDesktop ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildProfileSection()),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _buildPersonalInformationSection()),
            ],
          )
        : Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 32),
              _buildPersonalInformationSection(),
            ],
          );
  }

  Widget _buildProfileSection() {
    return Obx(() {
      final user = authController.currentUser.value;

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
              children: [
                // Profile Picture
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // User Info
                // _buildContactInfo(Icons.email, user?.email ?? 'Loading...'),
                // const SizedBox(height: 16),
                // _buildContactInfo(Icons.phone, user?.phone ?? 'Loading...'),

                // const SizedBox(height: 24),

                // Action Buttons
                _buildActionButton(
                  Icons.lock_outline,
                  'Change Password',
                  Colors.black87,
                  () => _showChangePasswordDialog(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  Icons.logout,
                  'Logout',
                  Colors.red,
                  () => _showLogoutDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Edit/Save Profile Buttons
          if (_isEditMode)
            // When in edit mode, show Save and Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditMode = false;
                        // Clear any unsaved changes by repopulating from current user
                        final user = authController.currentUser.value;
                        if (user != null) {
                          _nameController.text = user.name;
                          _emailController.text = user.email;
                          _phoneController.text = user.phone;
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => ElevatedButton(
                        onPressed: userController.isLoading.value
                            ? null
                            : _saveProfileChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: userController.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )),
                ),
              ],
            )
          else
            // When not in edit mode, show Edit Profile button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    final user = authController.currentUser.value;
                    if (user != null) {
                      _nameController.text = user.name;
                      _emailController.text = user.email;
                      _phoneController.text = user.phone;
                    }
                    _isEditMode = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black87,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              //   if (_isEditMode)
              //     Row(
              //       children: [
              //         TextButton(
              //           onPressed: () {
              //             setState(() {
              //               _isEditMode = false;
              //               // Reset form controllers to original values
              //               final user = userController.currentUser.value;
              //               if (user != null) {
              //                 _nameController.text = user.name;
              //                 _emailController.text = user.email;
              //                 _phoneController.text = user.phone;
              //               }
              //             });
              //           },
              //           child: const Text('Cancel'),
              //         ),
              //         const SizedBox(width: 8),
              //         ElevatedButton(
              //           onPressed: _saveProfile,
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: Colors.green,
              //             foregroundColor: Colors.white,
              //           ),
              //           child: const Text('Save'),
              //         ),
              //       ],
              //     ),
            ],
          ),
          const SizedBox(height: 32),
          _buildPersonalInfoGrid(),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "All fields are required",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return;
    }

    final success = await userController.updateCurrentUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success) {
      setState(() {
        _isEditMode = false;
      });

      // Refresh the global current user data to ensure UI is updated everywhere
      await authController.fetchCurrentUser();
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
            'Password change functionality will use the forgot password flow.\n\nAn OTP will be sent to your email address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to forgot password screen
              Get.toNamed('/forgot-password');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authController.logout();
              // Navigate to login after logout using named route
              Get.offAllNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoGrid() {
    return Obx(() {
      final user = authController.currentUser.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 400;

          if (isWide) {
            return Column(
              children: [
                _buildPersonalInfoField(
                  'Full Name',
                  user?.name ?? 'Loading...',
                  controller: _nameController,
                  isEditable: _isEditMode,
                ),
                const SizedBox(height: 24),
                _buildPersonalInfoField(
                  'Email Address',
                  user?.email ?? 'Loading...',
                  controller: _emailController,
                  isEditable: _isEditMode,
                ),
                const SizedBox(height: 24),
                _buildPersonalInfoField(
                  'Phone Number',
                  user?.phone ?? 'Loading...',
                  controller: _phoneController,
                  isEditable: _isEditMode,
                ),
                const SizedBox(height: 24),
                _buildPersonalInfoField(
                  'Role',
                  user?.role ?? 'Loading...',
                  isEditable: false, // Role is not editable
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildPersonalInfoField(
                  'Full Name',
                  user?.name ?? 'Loading...',
                  controller: _nameController,
                  isEditable: _isEditMode,
                ),
                const SizedBox(height: 24),
                _buildPersonalInfoField(
                  'Email Address',
                  user?.email ?? 'Loading...',
                  controller: _emailController,
                  isEditable: _isEditMode,
                ),
                const SizedBox(height: 24),
                _buildPersonalInfoField(
                  'Phone Number',
                  user?.phone ?? 'Loading...',
                  controller: _phoneController,
                  isEditable: _isEditMode,
                ),
                const SizedBox(height: 24),
                _buildPersonalInfoField(
                  'Role',
                  user?.role ?? 'Loading...',
                  isEditable: false, // Role is not editable
                ),
              ],
            );
          }
        },
      );
    });
  }

  Widget _buildPersonalInfoField(
    String label,
    String value, {
    TextEditingController? controller,
    bool isEditable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditable && controller != null)
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE9ECEF),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
