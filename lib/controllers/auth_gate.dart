import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/data/services/auth_service.dart';
import 'package:stackle_admin/view/auth/login_screen.dart';
import 'package:stackle_admin/view/main_dashboard.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController _authController;
  final AuthService _authService = AuthService();
  final GetStorage _storage = GetStorage();

  bool _isInitialized = false;
  bool _isNavigating = false; // Prevent multiple navigation calls

  @override
  void initState() {
    super.initState();
    // Use the globally registered AuthController if available, otherwise register it.
    if (Get.isRegistered<AuthController>()) {
      _authController = Get.find<AuthController>();
    } else {
      _authController = Get.put(AuthController());
    }
    // Defer navigation until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      print('AuthGate: Initializing authentication...');
      
      // Reset navigation flag
      _isNavigating = false;

      // Wait a bit for storage to be ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if tokens exist in storage
      final accessToken = _storage.read('access_token') ?? '';
      final refreshToken = _storage.read('refresh_token') ?? '';
      final tokenTimestamp = _storage.read('token_timestamp') ?? 0;

      print('AuthGate: Storage values:');
      print(
          '  - access_token: ${accessToken.isNotEmpty ? "Found (${accessToken.length} chars)" : "Empty"}');
      print(
          '  - refresh_token: ${refreshToken.isNotEmpty ? "Found (${refreshToken.length} chars)" : "Empty"}');
      print('  - token_timestamp: $tokenTimestamp');
      print(
          'AuthGate: Found tokens - Access: ${accessToken.isNotEmpty ? "Yes" : "No"}, Refresh: ${refreshToken.isNotEmpty ? "Yes" : "No"}');

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        // No tokens found, go to login
        print('AuthGate: No tokens found, navigating to login');
        _navigateToLogin();
        return;
      }

      // Check if token is expired (7 days = 604800000 milliseconds for testing)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final tokenAge = currentTime - tokenTimestamp;
      const twentyFourHours = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

      print(
          'AuthGate: Token age: ${(tokenAge / (60 * 60 * 1000)).toStringAsFixed(2)} hours');

      if (tokenAge >= twentyFourHours) {
        // Token is expired, try to refresh
        print('AuthGate: Token expired, attempting refresh...');
        await _attemptTokenRefresh(refreshToken);
      } else {
        // Token is still valid, set it in controller and navigate to dashboard
        print(
            'AuthGate: Token valid, setting in controller and navigating to dashboard');
        _authController.accessToken.value = accessToken;
        _authController.refreshToken.value = refreshToken;
        // Ensure current user data is fetched immediately so UI shows basic data
        await _authController.fetchCurrentUser();
        _navigateToDashboard();
      }
    } catch (e) {
      print('AuthGate: Auth initialization error: $e');
      _navigateToLogin();
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _attemptTokenRefresh(String refreshToken) async {
    try {
      print('AuthGate: Attempting to refresh token...');
      final newTokens = await _authService.refreshToken(refreshToken);

      if (newTokens != null && newTokens.isNotEmpty) {
        // Update tokens in storage and controller
        final newAccessToken = newTokens['access'] ?? '';
        final newRefreshToken = newTokens['refresh'] ??
            refreshToken; // Keep old refresh token if not provided

        if (newAccessToken.isNotEmpty) {
          _storage.write('access_token', newAccessToken);
          _storage.write('refresh_token', newRefreshToken);
          _storage.write(
              'token_timestamp', DateTime.now().millisecondsSinceEpoch);

          _authController.accessToken.value = newAccessToken;
          _authController.refreshToken.value = newRefreshToken;

          print('AuthGate: Token refreshed successfully');
          _navigateToDashboard();
        } else {
          print('AuthGate: Token refresh failed - empty access token');
          _navigateToLogin();
        }
      } else {
        print('AuthGate: Token refresh failed - no tokens returned');
        _navigateToLogin();
      }
    } catch (e) {
      print('AuthGate: Token refresh failed: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted && !_isNavigating) {
      _isNavigating = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !Get.isDialogOpen!) {
          try {
            Get.offAllNamed('/login');
          } catch (e) {
            print('AuthGate: Navigation error: $e');
            // Fallback to direct navigation
            Get.offAll(() => const LoginScreen());
          }
        }
      });
    }
  }

  void _navigateToDashboard() {
    if (mounted && !_isNavigating) {
      _isNavigating = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !Get.isDialogOpen!) {
          try {
            // Preserve the current dashboard route on reload
            final currentRoute = Get.currentRoute;
            String targetRoute = '/dashboard';
            if (currentRoute.isNotEmpty && currentRoute.startsWith('/dashboard')) {
              targetRoute = currentRoute;
            }
            Get.offAllNamed(targetRoute);
          } catch (e) {
            print('AuthGate: Navigation error: $e');
            // Fallback to direct navigation
            Get.offAll(() => const MainDashboard());
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F1E8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.health_and_safety,
                size: 80,
                color: Color(0xFFFFD700),
              ),
              SizedBox(height: 24),
              Text(
                'STACKLE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // This should not be reached as navigation happens in _initializeAuth
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
