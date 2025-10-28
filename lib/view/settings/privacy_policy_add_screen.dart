import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/privacy_policy_controller.dart';
import 'package:stackle_admin/data/models/privacy_policy.dart';

class PrivacyPolicyAddScreen extends StatefulWidget {
  const PrivacyPolicyAddScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyAddScreen> createState() => _PrivacyPolicyAddScreenState();
}

class _PrivacyPolicyAddScreenState extends State<PrivacyPolicyAddScreen> {
  late final PrivacyPolicyController _controller;
  final TextEditingController _textController = TextEditingController();
  Worker? _policyWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(PrivacyPolicyController());
    _policyWorker = ever<PrivacyPolicy?>(_controller.policy, (policy) {
      if (!mounted) return;
      final text = policy?.text ?? '';
      if (_textController.text != text) {
        _textController.text = text;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadPrivacyPolicy();
    });
  }

  @override
  void dispose() {
    _policyWorker?.dispose();
    _textController.dispose();
    if (Get.isRegistered<PrivacyPolicyController>()) {
      Get.delete<PrivacyPolicyController>();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _textController.text;
    final hasPolicy = _controller.policy.value != null;
    if (hasPolicy) {
      await _controller.updatePrivacyPolicy(text);
    } else {
      await _controller.createPrivacyPolicy(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) {
      return _buildDesktopLayout(context);
    }
    if (width >= 768) {
      return _buildTabletLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopHeader(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildPolicyEditor(fillAvailable: true, isCompact: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabletHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildPolicyEditor(fillAvailable: true, isCompact: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh',
              onPressed: _controller.isLoading.value
                  ? null
                  : () => _controller.loadPrivacyPolicy(),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPolicyEditor(fillAvailable: false, isCompact: true),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: ()=> Navigator.of(context).pop(),
            ),
            SizedBox(width: 16),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.black54,
                size: 20,
              ),
            ),
            // const SizedBox(width: 16),
            // Row(
            //   children: [
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.end,
            //       children: const [
            //         Text(
            //           'Nived Manoj',
            //           style: TextStyle(
            //             fontSize: 16,
            //             fontWeight: FontWeight.w600,
            //             color: Colors.black87,
            //           ),
            //         ),
            //         Text(
            //           'Admin',
            //           style: TextStyle(
            //             fontSize: 14,
            //             color: Colors.black54,
            //           ),
            //         ),
            //       ],
            //     ),
            //     const SizedBox(width: 12),
            //     Container(
            //       width: 44,
            //       height: 44,
            //       decoration: const BoxDecoration(
            //         shape: BoxShape.circle,
            //         image: DecorationImage(
            //           image: NetworkImage(
            //             'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
            //           ),
            //           fit: BoxFit.cover,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletHeader() {
    return Row(
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.black54,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyEditor({required bool fillAvailable, required bool isCompact}) {
    return Obx(() {
      final policy = _controller.policy.value;
      final isLoading = _controller.isLoading.value;
      final isSaving = _controller.isSaving.value;
      final error = _controller.errorMessage.value;

      final titleStyle = TextStyle(
        fontSize: isCompact ? 20 : 24,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      );

      final subtitleStyle = TextStyle(
        fontSize: isCompact ? 13 : 14,
        color: Colors.black54,
      );

      final textField = TextField(
        controller: _textController,
        expands: fillAvailable,
        minLines: fillAvailable ? null : (isCompact ? 10 : 14),
        maxLines: fillAvailable ? null : 24,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(fontSize: isCompact ? 14 : 15, height: 1.4, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Write the privacy policy that should be shown inside the app...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 1.4),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: isCompact ? 18 : 24,
          ),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Privacy Policy', style: titleStyle),
                    const SizedBox(height: 6),
                    if (policy?.formattedUpdatedAt != null)
                      Text('Last updated ${policy!.formattedUpdatedAt}', style: subtitleStyle)
                    else
                      Text('No privacy policy published yet', style: subtitleStyle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: isLoading ? null : () => _controller.loadPrivacyPolicy(),
                    icon: const Icon(Icons.refresh),
                  ),
                  ElevatedButton(
                    onPressed: (isSaving || _controller.isLoading.value)
                        ? null
                        : () => _handleSave(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(policy == null ? 'Create Policy' : 'Update Policy'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (error.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: isLoading ? null : () => _controller.loadPrivacyPolicy(),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (!fillAvailable) ...[
            if (policy == null)
              Text(
                'Start by writing your privacy policy below then tap "Create Policy".',
                style: subtitleStyle,
              )
            else
              Text(
                'Update the policy content below and save your changes.',
                style: subtitleStyle,
              ),
            const SizedBox(height: 16),
          ]
          else ...[
            if (policy == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Start by writing your privacy policy below then tap "Create Policy".',
                  style: subtitleStyle,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Update the policy content below and save your changes.',
                  style: subtitleStyle,
                ),
              ),
          ],
          fillAvailable ? Expanded(child: textField) : textField,
        ],
      );
    });
  }
}
