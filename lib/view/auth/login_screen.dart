import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final AuthController authController = AuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 768;

            if (isMobile) {
              return _buildMobileLayout();
            } else {
              return _buildDesktopLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24), // prevent cutoff
      child: Column(
        children: [
          // Mobile Image Section
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: _buildSurgeryImage(),
            ),
          ),

          const SizedBox(height: 32),

          // Mobile Login Form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLoginForm(true),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Medical Image
        Expanded(
          flex: 1,
          child: Container(
            height: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: _buildSurgeryImage(),
            ),
          ),
        ),

        // Right side - Login Form
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginForm(false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurgeryImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A5568).withOpacity(0.3),
            const Color(0xFF2D3748).withOpacity(0.7),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_hospital, size: 80, color: Colors.white70),
      ),
    );
  }

  Widget _buildLoginForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Logo Section
          Center(
            child: Column(
              children: const [
                Icon(Icons.health_and_safety,
                    size: 80, color: Color(0xFFFFD700)),
                SizedBox(height: 16),
                Text(
                  'STACKLE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isMobile ? 32 : 48),

          // Login Title
          const Text(
            'Login',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 24),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', 'test@admin.com'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: _inputDecoration('Password', 'At least 8 characters: Test@123'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Sign In Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  authController.login(
                      _emailController.text, _passwordController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Forgot Password Link
          Center(
            child: TextButton(
              onPressed: () {
                Get.toNamed('/forgot-password');
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }
}
