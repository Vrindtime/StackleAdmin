import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/hr_controller.dart';
import 'package:stackle_admin/controllers/user_controller.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/core/pdf_viewer.dart';
import 'package:stackle_admin/data/models/organization.dart';
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/core/routing.dart';

// New dynamic HR details screen (see professional_details_screen for inspiration)
class HrDetailsScreen extends StatefulWidget {
  final Organization? organization;
  const HrDetailsScreen({super.key, this.organization});

  @override
  State<HrDetailsScreen> createState() => _HrDetailsScreenState();
}

class _HrDetailsScreenState extends State<HrDetailsScreen> {
  late final AuthController authController;
  late HRController hrController;
  late UserController userController;
  bool _editMode = false;
  bool _saving = false;
  // Controllers for inline editing
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  // Owner user controllers
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    ever(authController.currentUser, (user) {
      if (user == null) {
        Get.offAllNamed(AppRoutes.login);
      }
    });
    hrController = Get.isRegistered<HRController>()
        ? Get.find<HRController>()
        : Get.put(HRController(), permanent: true);
    userController = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : Get.put(UserController(), permanent: true);

    // If an Organization object was passed to the widget, use it immediately.
    // Otherwise try to resolve orgId from Get.arguments or Get.parameters and
    // fetch/resolve the organization asynchronously.
    if (widget.organization != null) {
      hrController.setCurrentOrganization(widget.organization!);
      userController.fetchUserById(widget.organization!.userId);
      _seedInlineControllers(widget.organization!);
    } else {
      // Resolve orgId from arguments or url parameters
      final arg = Get.arguments;
      int? orgId;
      if (arg is int) {
        orgId = arg;
      } else if (arg is Map && arg['orgId'] is int) {
        orgId = arg['orgId'] as int;
      }
      if (orgId == null) {
        final p = Get.parameters['orgId'];
        if (p != null) orgId = int.tryParse(p);
      }

      if (orgId != null) {
        _loadOrgFromId(orgId);
      }
    }
  }

  void _seedInlineControllers(Organization org) {
    _nameCtrl.text = org.name;
    _descCtrl.text = org.description;
    _areaCtrl.text = org.area;
    _cityCtrl.text = org.city;
    _stateCtrl.text = org.state;
    _countryCtrl.text = org.country;
    _pincodeCtrl.text = org.pincode;
    _phoneCtrl.text = org.phone ?? '';
    _emailCtrl.text = org.email ?? '';
    _latCtrl.text = org.latitude;
    _lngCtrl.text = org.longitude;
    final owner = userController.user.value;
    if (owner != null) {
      _ownerNameCtrl.text = owner.name;
      _ownerEmailCtrl.text = owner.email;
      _ownerPhoneCtrl.text = owner.phone;
    }
  }

  void _toggleEdit() {
    final org = hrController.currentOrganization.value ?? widget.organization;
    if (!_editMode) {
      if (org != null) _seedInlineControllers(org);
    }
    setState(() {
      _editMode = !_editMode;
    });
  }

  void _cancelEdit() {
    final org = hrController.currentOrganization.value ?? widget.organization;
    if (org != null) _seedInlineControllers(org); // revert changes
    setState(() {
      _editMode = false;
      _saving = false;
    });
  }

  Future<void> _saveInline() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    final org = hrController.currentOrganization.value ?? widget.organization;
  if (org == null) return;
    await hrController.updateOrganization(
      org.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      latitude: _latCtrl.text.trim().isEmpty ? null : _latCtrl.text.trim(),
      longitude: _lngCtrl.text.trim().isEmpty ? null : _lngCtrl.text.trim(),
    );
    final owner = userController.user.value;
    if (owner != null) {
      final newName = _ownerNameCtrl.text.trim();
      final newEmail = _ownerEmailCtrl.text.trim();
      final newPhone = _ownerPhoneCtrl.text.trim();
      final changed = newName != owner.name ||
          newEmail != owner.email ||
          newPhone != owner.phone;
      if (changed) {
        await userController.updateUser(
          userId: owner.id,
          name: newName.isEmpty ? owner.name : newName,
          email: newEmail.isEmpty ? owner.email : newEmail,
          phone: newPhone.isEmpty ? owner.phone : newPhone,
          role: owner.role,
        );
      }
    }
    setState(() {
      _saving = false;
      _editMode = false;
    });
  }

  // Consolidated media URL resolver (mirrors professional_details_screen logic)
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
        return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
      }
      try {
        if (Uri.parse(baseRoot).host == uri.host) return trimmed;
      } catch (_) {}
      return trimmed; // external URL
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

  void _viewDocument(String title, String url) {
    final resolved = _resolveMediaUrl(url);
    if (Uri.tryParse(resolved)?.path.toLowerCase().endsWith('.pdf') ?? false) {
      viewPdfInline(title, resolved, context);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close))
              ]),
              Row(children: [
                Expanded(
                    child: Text(resolved,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blueGrey),
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: resolved));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')));
                    })
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolved,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Text('Failed to load image')),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadOrgFromId(int orgId) async {
    // Try local cache first
    Organization? org = hrController.organizations.where((o) => o.id == orgId).isNotEmpty
        ? hrController.organizations.where((o) => o.id == orgId).first
        : null;

    if (org == null) {
      // Fetch organizations and try again
      await hrController.fetchOrganizations();
      org = hrController.organizations.where((o) => o.id == orgId).isNotEmpty
          ? hrController.organizations.where((o) => o.id == orgId).first
          : null;
    }

    if (org != null) {
      hrController.setCurrentOrganization(org);
      userController.fetchUserById(org.userId);
      _seedInlineControllers(org);
      setState(() {});
    } else {
      Get.snackbar('Error', 'Organization not found (ID: $orgId)', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return Row(children: [Expanded(child: _buildMainContent(isMobile))]);
      }),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(isMobile),
        const SizedBox(height: 24),
        Expanded(child: Obx(() {
          final org = hrController.currentOrganization.value ?? widget.organization;
          if (org == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _buildUserInfoSection(),
                const SizedBox(height: 32),
                _buildOrgInfoSection(org),
                const SizedBox(height: 32),
                _buildLocationSection(org),
                const SizedBox(height: 32),
                _buildStatsSection(org),
                const SizedBox(height: 32),
                _buildDocumentsSection(org),
                const SizedBox(height: 32),
                _buildImagesSection(org),
                const SizedBox(height: 32),
                // Block/Edit section moved to overflow menu; placeholder removed
              ]));
        }))
      ]),
    );
  }

  Widget _buildHeader(bool isMobile) => Row(
        children: [
          if (isMobile)
            IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black54),
              onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() {
        final org = hrController.currentOrganization.value ?? widget.organization;
        if (org == null) return const SizedBox.shrink();
        final initials = org.name.isNotEmpty
          ? org.name
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase()
          : 'O';
        final logoUrl = (org.logo ?? '').isNotEmpty
          ? _resolveMediaUrl(org.logo!)
          : '';
        return Row(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue[50],
                  backgroundImage:
                      logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                  child: logoUrl.isEmpty
                      ? Text(initials,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(org.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Org ID: ${org.id}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ])
              ]);
            }),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange[200]!,
              side: BorderSide(color: Colors.orange[200]!),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              final org = hrController.currentOrganization.value ?? widget.organization;
              if (org == null) return;
              Get.toNamed(
                AppRoutes.hrChatScreen,
                arguments: org.id,
              );
            },
            icon: Icon(Icons.chat, size: 18, color: Colors.orange[200]!),
            label: Text('Chat',
                style: TextStyle(fontWeight: FontWeight.w600,color: Colors.orange[200]!)),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final loading = hrController.isLoadingJobs.value;
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: loading ? null : _openJobsList,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.work_outline, size: 18),
              label: const Text('Jobs',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            );
          }),
          if (_editMode) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _saving ? null : _cancelEdit,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saving ? null : _saveInline,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save All'),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 8),
          Obx(() {
            final org =
                hrController.currentOrganization.value ?? widget.organization;
            if (org == null) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              color: Colors.white,
              tooltip: 'More actions',
              onSelected: (val) {
                switch (val) {
                  case 'revoke':
                    _handleRevokeApproval();
                    break;
                  case 'approve':
                    _handleApprove();
                    break;
                  case 'edit':
                    _toggleEdit();
                    break;
                  case 'block':
                    if (org.isBlocked) {
                      hrController.unblockOrganization(org.id);
                    } else {
                      hrController.blockOrganization(org.id);
                    }
                    break;
                  case 'block_user':
                    _handleBlockOwnerUser();
                    break;
                  case 'unblock_user':
                    _handleUnblockOwnerUser();
                    break;
                  case 'reject':
                    _handleReject(); // keep path if needed, though not shown when approved now
                    break;
                }
              },
              itemBuilder: (_) {
                final items = <PopupMenuEntry<String>>[];
                if (org.isAdminApproved) {
                  items.add(const PopupMenuItem<String>(
                    value: 'revoke',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.undo, color: Colors.orange),
                      title: Text('Revoke Approval'),
                    ),
                  ));
                } else {
                  items.add(const PopupMenuItem<String>(
                    value: 'approve',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Approve'),
                    ),
                  ));
                  items.add(const PopupMenuItem<String>(
                    value: 'reject',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text('Reject (Pending)'),
                    ),
                  ));
                }
                // Common options
                items.add(const PopupMenuDivider());
                items.add(const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Edit Organization'),
                  ),
                ));
                items.add(PopupMenuItem<String>(
                  value: 'block',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(org.isBlocked ? Icons.lock_open : Icons.block,
                        color: org.isBlocked ? Colors.green : Colors.red),
                    title: Text(org.isBlocked
                        ? 'Unblock Organization'
                        : 'Block Organization'),
                  ),
                ));
                // Owner user block/unblock action (admin)
                final owner = userController.user
                    .value; // Block state not on User model; both actions available
                if (owner != null) {
                  items.add(const PopupMenuItem<String>(
                    value: 'block_user',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_off, color: Colors.red),
                      title: Text('Block Owner User'),
                    ),
                  ));
                  items.add(const PopupMenuItem<String>(
                    value: 'unblock_user',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_open, color: Colors.green),
                      title: Text('Unblock Owner User'),
                    ),
                  ));
                }
                return items;
              },
              icon: const Icon(Icons.more_vert, color: Colors.black54),
            );
          }),
        ],
      );

  Widget _buildUserInfoSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.person, color: Colors.blue[600]),
            const SizedBox(width: 12),
            const Text('Owner User Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          Obx(() {
            if (userController.isLoading.value)
              return const Center(child: CircularProgressIndicator());
            if (userController.hasError.value) {
              return _errorBox(
                  'Failed to load user', userController.errorMessage.value,
                  onRetry: () {
                final uid = hrController.currentOrganization.value?.userId ?? widget.organization?.userId;
                if (uid != null) userController.fetchUserById(uid);
              });
            }
            final User? user = userController.user.value;
            if (user == null)
              return const Text('No user data',
                  style: TextStyle(color: Colors.grey));
            return Column(children: [
              _editableInfoRow(
                  'Name', _ownerNameCtrl, user.name, Icons.person_outline,
                  required: true, maxLen: 120),
              _editableInfoRow(
                  'Email', _ownerEmailCtrl, user.email, Icons.email_outlined,
                  email: true),
              _editableInfoRow(
                  'Phone', _ownerPhoneCtrl, user.phone, Icons.phone_outlined,
                  phone: true),
              _infoRow('Role', user.role, Icons.admin_panel_settings_outlined),
              _infoRow('User ID', user.id.toString(), Icons.badge_outlined),
            ]);
          })
        ]),
      );

  Widget _buildOrgInfoSection(Organization org) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.business, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('Organization Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _inlineField('Name', _nameCtrl, validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().length > 120) return 'Too long';
            return null;
          }),
          const SizedBox(height: 12),
          _displayRow('Registration No', org.registrationNumber,
              Icons.confirmation_number),
          const SizedBox(height: 12),
          _inlineField('Description', _descCtrl, maxLines: 3, validator: (v) {
            if (!_editMode) return null;
            final val = v?.trim() ?? '';
            if (val.length > 2000) return 'Description too long';
            return null;
          }),
          const SizedBox(height: 12),
          _sectionLabel('Contact'),
          const SizedBox(height: 8),
          _inlineField('Phone', _phoneCtrl, validator: (v) {
            if (!_editMode) return null;
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            if (!RegExp(r'^[- +0-9]{6,15}$').hasMatch(val))
              return 'Invalid phone';
            return null;
          }),
          const SizedBox(height: 12),
          _inlineField('Email', _emailCtrl, validator: (v) {
            if (!_editMode) return null;
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val))
              return 'Invalid email';
            return null;
          }),
          const SizedBox(height: 20),
          _sectionLabel('Location'),
          const SizedBox(height: 8),
          _inlineField('Area', _areaCtrl),
          const SizedBox(height: 12),
          _inlineField('City', _cityCtrl),
          const SizedBox(height: 12),
          _inlineField('State', _stateCtrl),
          const SizedBox(height: 12),
          _inlineField('Country', _countryCtrl),
          const SizedBox(height: 12),
          _inlineField('Pincode', _pincodeCtrl, validator: (v) {
            if (!_editMode) return null;
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            if (val.length < 3) return 'Too short';
            if (val.length > 12) return 'Too long';
            return null;
          }),
          const SizedBox(height: 12),
          _readOnlyField('Coordinates', '${org.latitude}, ${org.longitude}'),
        ]),
      ),
    );
  }

  Widget _inlineField(String label, TextEditingController controller,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.label_important, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      if (_editMode)
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D0D0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue)),
          ),
        )
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!)),
          child: Text(controller.text.isNotEmpty ? controller.text : '—',
              style: TextStyle(
                  color:
                      controller.text.isEmpty ? Colors.grey : Colors.black87)),
        )
    ]);
  }

  Widget _sectionLabel(String title) => Row(children: [
        Icon(Icons.segment, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ]);

  Widget _readOnlyField(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.label_important, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
        ]),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!)),
          child: Text(value.isNotEmpty ? value : '—',
              style: TextStyle(
                  color: value.isEmpty ? Colors.grey : Colors.black87)),
        )
      ]);

  Widget _displayRow(String label, String value, IconData icon) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.grey[600]),
      const SizedBox(width: 8),
      SizedBox(
          width: 140,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value.isNotEmpty ? value : '—',
              style: TextStyle(
                  color: value.isEmpty ? Colors.grey : Colors.black87))),
    ]);
  }

  Widget _buildLocationSection(Organization org) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.location_on, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          _editableInfoRow('Area', _areaCtrl, org.area, Icons.home),
          _editableInfoRow('City', _cityCtrl, org.city, Icons.location_city),
          _editableInfoRow('State', _stateCtrl, org.state, Icons.map),
          _editableInfoRow('Country', _countryCtrl, org.country, Icons.flag),
          _editableInfoRow(
              'Pincode', _pincodeCtrl, org.pincode, Icons.local_post_office,
              pincode: true),
          _editableInfoRow(
              'Latitude', _latCtrl, org.latitude, Icons.gps_not_fixed,
              latitude: true),
          _editableInfoRow(
              'Longitude', _lngCtrl, org.longitude, Icons.gps_fixed,
              longitude: true),
        ]),
      );
  Widget _editableInfoRow(String label, TextEditingController controller,
      String currentValue, IconData icon,
      {bool required = false,
      bool email = false,
      bool phone = false,
      bool pincode = false,
      bool latitude = false,
      bool longitude = false,
      int maxLen = 255}) {
    String? validator(String? v) {
      if (!_editMode) return null;
      final val = v?.trim() ?? '';
      if (required && val.isEmpty) return 'Required';
      if (val.isNotEmpty && val.length > maxLen) return 'Too long';
      if (email &&
          val.isNotEmpty &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val))
        return 'Invalid email';
      if (phone && val.isNotEmpty && !RegExp(r'^[- +0-9]{6,15}$').hasMatch(val))
        return 'Invalid phone';
      if (pincode && val.isNotEmpty && (val.length < 3 || val.length > 12))
        return 'Invalid pincode';
      if (latitude && val.isNotEmpty) {
        final d = double.tryParse(val);
        if (d == null || d < -90 || d > 90) return 'Invalid latitude';
      }
      if (longitude && val.isNotEmpty) {
        final d = double.tryParse(val);
        if (d == null || d < -180 || d > 180) return 'Invalid longitude';
      }
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Expanded(
            child: !_editMode
                ? Text(currentValue.isNotEmpty ? currentValue : '—',
                    style: TextStyle(
                        color: currentValue.isEmpty
                            ? Colors.grey
                            : Colors.black87))
                : TextFormField(
                    controller: controller,
                    validator: validator,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D0D0))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue)),
                    ),
                  ))
      ]),
    );
  }

  Widget _buildStatsSection(Organization org) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.insights, color: Colors.purple[600]),
            const SizedBox(width: 12),
            const Text('Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _statChip('Active Jobs', org.activeJobCount, Icons.work),
            _statChip('Requests', org.requestsCount, Icons.inbox),
            _statChip('Search Views', org.searchAppearanceCount, Icons.search),
            _approvalStatusChip(org.isAdminApproved),
            if (org.isBlocked) _blockedStatusChip(),
          ])
        ]),
      );

  Widget _buildDocumentsSection(Organization org) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.picture_as_pdf, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Documents',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          if (org.document.isEmpty)
            const Text('No documents uploaded',
                style: TextStyle(color: Colors.grey))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: org.document.length,
              itemBuilder: (_, i) {
                final doc = org.document[i];
                final resolved = _resolveMediaUrl(doc);
                final isPdf = resolved.toLowerCase().endsWith('.pdf');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!)),
                  child: Row(children: [
                    Icon(isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                        color: isPdf ? Colors.red : Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(resolved.split('/').last,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                    TextButton.icon(
                        onPressed: () =>
                            _viewDocument('Document ${i + 1}', doc),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'))
                  ]),
                );
              },
            )
        ]),
      );

  Widget _buildImagesSection(Organization org) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.image, color: Colors.teal[600]),
            const SizedBox(width: 12),
            const Text('Images',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          if (org.images.isEmpty)
            const Text('No images uploaded',
                style: TextStyle(color: Colors.grey))
          else
            Wrap(
                spacing: 12,
                runSpacing: 12,
                children: org.images.map((img) {
                  final resolved = _resolveMediaUrl(img);
                  return GestureDetector(
                      onTap: () => _viewDocument('Image', img),
                      child: Container(
                          width: 120,
                          height: 90,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              image: DecorationImage(
                                  image: NetworkImage(resolved),
                                  fit: BoxFit.cover))));
                }).toList())
        ]),
      );

  // Approval section removed for simplified UI (actions remain in overflow menu if needed)

  // Removed placeholder block method (real implementation wired into menu)

  void _handleApprove() {
    final org = hrController.currentOrganization.value ?? widget.organization;
    if (org == null) {
      Get.snackbar('Error', 'Organization not loaded', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Approve Organization'),
                content: Text('Approve organization ID: ${org.id}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          elevation: 0),
                      onPressed: () {
                        Navigator.pop(context);
                        hrController.approveOrganization(org.id);
                      },
                      child: const Text('Approve')),
                ]));
  }

  void _handleReject() {
    final org = hrController.currentOrganization.value ?? widget.organization;
    if (org == null) {
      Get.snackbar('Error', 'Organization not loaded', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Reject Organization'),
                content: Text('Reject organization ID: ${org.id}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          elevation: 0),
                      onPressed: () {
                        Navigator.pop(context);
                        hrController.rejectOrganization(org.id);
                      },
                      child: const Text('Reject')),
                ]));
  }

  void _handleRevokeApproval() {
    final org = hrController.currentOrganization.value ?? widget.organization;
    if (org == null) {
      Get.snackbar('Error', 'Organization not loaded', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Revoke Approval'),
              content: Text(
                  'Revoke approval for organization "${org.name}" (ID: ${org.id})? This will move it back to Pending status.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      elevation: 0),
                  onPressed: () {
                    Navigator.pop(context);
                    // Revoke modeled as reject + (optional) immediate UI update; backend currently only has reject.
                    hrController.rejectOrganization(org.id);
                  },
                  child: const Text('Revoke'),
                )
              ],
            ));
  }

  void _handleBlockOwnerUser() {
    final owner = userController.user.value;
    if (owner == null) {
      Get.snackbar('Error', 'Owner user not loaded yet',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800]);
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Block Owner User'),
              content: Text(
                  'Are you sure you want to block user "${owner.name}" (ID: ${owner.id})? This action may restrict account access.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      elevation: 0),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await userController.blockUser(owner.id);
                    if (success) {
                      // Optionally refresh organization or user if backend reflects blocked status.
                    }
                  },
                  child: const Text('Block User'),
                )
              ],
            ));
  }

  void _handleUnblockOwnerUser() {
    final owner = userController.user.value;
    if (owner == null) {
      Get.snackbar('Error', 'Owner user not loaded yet',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800]);
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Unblock Owner User'),
              content: Text('Unblock user "${owner.name}" (ID: ${owner.id})?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      elevation: 0),
                  onPressed: () async {
                    Navigator.pop(context);
                    await userController.unblockUser(owner.id);
                  },
                  child: const Text('Unblock User'),
                )
              ],
            ));
  }

  // Helpers
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      );

  Widget _infoRow(String label, String value, IconData icon,
          {bool multiline = false}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment:
              multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: multiline ? null : 1,
                overflow:
                    multiline ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      );

  Widget _statChip(String label, int value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text('$label: $value',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
        ]),
      );

  Widget _approvalStatusChip(bool approved) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: approved ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: approved ? Colors.green[200]! : Colors.orange[200]!),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(approved ? Icons.verified : Icons.hourglass_bottom,
              size: 18,
              color: approved ? Colors.green[600] : Colors.orange[600]),
          const SizedBox(width: 8),
          Text(approved ? 'Approved' : 'Pending',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: approved ? Colors.green[700] : Colors.orange[700]))
        ]),
      );

  Widget _blockedStatusChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock, size: 18, color: Colors.red[600]),
          const SizedBox(width: 8),
          Text('Blocked',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700])),
        ]),
      );

  Widget _errorBox(String title, String message, {VoidCallback? onRetry}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(children: [
          Icon(Icons.error, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(message, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry'))
        ]),
      );
  void _openJobsList() async {
    final org = hrController.currentOrganization.value ?? widget.organization;
    if (org == null) {
      Get.snackbar('Error', 'Organization not loaded', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    // Always force refresh to avoid stale jobs
    await hrController.fetchOrganizationJobs(org.id, force: true);
    // Show dialog with jobs
    // ignore: use_build_context_synchronously
    showDialog(
        context: context,
        builder: (ctx) {
          return Obx(() {
            final loading = hrController.isLoadingJobs.value;
            final error = hrController.jobsError.value;
            final jobs = hrController.organizationJobs;
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 600, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Jobs',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Obx(() => IconButton(
                              tooltip: 'Refresh',
                              icon: hrController.isLoadingJobs.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.refresh),
                              onPressed: hrController.isLoadingJobs.value
                                  ? null
                                  : () async {
                                      await hrController.fetchOrganizationJobs(
                                          org.id,
                                          force: true);
                                    },
                            )),
                        const Spacer(),
                        IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close))
                      ]),
                      const Divider(),
                      if (loading)
                        const Expanded(
                            child: Center(child: CircularProgressIndicator())),
                      if (!loading && error != null)
                        Expanded(
                            child: Center(
                                child:
                                    _errorBox('Jobs Error', error, onRetry: () {
                          Navigator.of(ctx).pop();
                          _openJobsList();
                        }))),
                      if (!loading && error == null && jobs.isEmpty)
                        const Expanded(
                            child: Center(child: Text('No jobs found'))),
                      if (!loading && error == null && jobs.isNotEmpty)
                        Expanded(
                          child: ListView.separated(
                            itemCount: jobs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final job = jobs[index];
                              final loc = job.city.isNotEmpty
                                  ? '${job.city}, ${job.state}'
                                  : job.state;
                              final salary =
                                  job.salary.isNotEmpty ? job.salary : '—';
                              final idText =
                                  job.id != null ? 'ID: ${job.id}' : '';
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.blue[50],
                                  child: const Icon(Icons.work_outline,
                                      size: 18, color: Colors.blue),
                                ),
                                title: Text(job.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text([
                                  if (idText.isNotEmpty) idText,
                                  loc,
                                  'Salary: $salary'
                                ].join(' • ')),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  Get.toNamed(AppRoutes.hrJobDetails,
                                      arguments: {
                                        'job': job,
                                        'organizationName': org.name
                                      });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}
