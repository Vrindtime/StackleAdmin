import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:stackle_admin/core/pdf_viewer.dart';
import 'package:stackle_admin/data/models/client.dart';
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/controllers/professional_controller.dart';
import 'package:stackle_admin/controllers/user_controller.dart';
import 'package:stackle_admin/core/api_base.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  final Client client;
  const ProfessionalDetailScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ProfessionalDetailScreen> createState() => _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  late UserController userController;
  late ProfessionalController professionalController;

  @override
  void initState() {
    super.initState();
    userController = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : Get.put(UserController(), permanent: true);
    professionalController = Get.find<ProfessionalController>();

    professionalController.currentClient.value = widget.client;
    userController.fetchUserById(widget.client.userId);
    professionalController.fetchClientById(widget.client.clientId);
  }

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
        if (Uri.parse(baseRoot).host == uri.host) return trimmed; // already ours
      } catch (_) {}
      return trimmed; // external
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        return Row(children: [Expanded(child: _buildMainContent(isMobile, isTablet))]);
      }),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(isMobile),
        const SizedBox(height: 24),
        Expanded(
          child: Obx(() {
            if (professionalController.isLoadingClient.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading client details...'),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildUserInfoSection(),
                const SizedBox(height: 32),
                _buildClientInfoSection(),
                const SizedBox(height: 32),
                _buildLocationSection(),
                const SizedBox(height: 32),
                _buildStatusSection(),
                const SizedBox(height: 32),
                _buildExperienceSection(),
                const SizedBox(height: 32),
                _buildEducationSection(),
                const SizedBox(height: 32),
                _buildCertificatesSection(),
                const SizedBox(height: 32),
                _buildLanguagesSection(),
                const SizedBox(height: 32),
                _buildApprovalSection(),
              ]),
            );
          }),
        )
      ]),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(children: [
      if (isMobile)
        IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context)),
      const SizedBox(width: 16),
      Expanded(
        child: Obx(() {
          final client = professionalController.currentClient.value ?? widget.client;
            final imageUrl = client.image ?? '';
            final resolved = imageUrl.isNotEmpty ? _resolveMediaUrl(imageUrl) : '';
            final initials = (userController.user.value?.name ?? '').isNotEmpty
                ? userController.user.value!.name
                    .split(' ')
                    .map((s) => s.isNotEmpty ? s[0] : '')
                    .join()
                    .toUpperCase()
                : 'P';
          return Row(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blue[50],
              backgroundImage: resolved.isNotEmpty ? NetworkImage(resolved) : null,
              child: resolved.isEmpty
                  ? Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Professional ID: ${client.clientId}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Joined: ${client.createdAt.year}-${client.createdAt.month.toString().padLeft(2, '0')}-${client.createdAt.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ])
          ]);
        }),
      ),
      const SizedBox(width: 8),
      Obx(() {
        final user = userController.user.value;
        final isLoadingStatus = userController.isLoadingBlockStatus.value;
        final blockStatus = userController.userBlockStatus.value;
        final isBlocked = blockStatus?.isBlocked ?? false;
        final client = professionalController.currentClient.value ?? widget.client;
        final isApproved = client.isAdminApproved;

        return PopupMenuButton<String>(
          color: Colors.white,
          tooltip: 'More actions',
          onOpened: () {
            if (user != null && blockStatus == null && !isLoadingStatus) {
              userController.fetchUserBlockStatus(user.id);
            }
          },
          onSelected: (val) {
            switch (val) {
              case 'approve_professional':
                _handleApproval();
                break;
              case 'reject_professional':
                _handleRejection();
                break;
              case 'block_user':
                _handleBlockUser();
                break;
              case 'unblock_user':
                _handleUnblockUser();
                break;
            }
          },
          itemBuilder: (_) {
            final items = <PopupMenuEntry<String>>[];

            if (isApproved) {
              items.add(const PopupMenuItem<String>(
                value: 'reject_professional',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.block, color: Colors.red),
                  title: Text('Reject Professional'),
                ),
              ));
            } else {
              items.add(const PopupMenuItem<String>(
                value: 'approve_professional',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Approve Professional'),
                ),
              ));
              items.add(const PopupMenuItem<String>(
                value: 'reject_professional',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.block, color: Colors.red),
                  title: Text('Reject Professional'),
                ),
              ));
            }

            items.add(const PopupMenuDivider());

            if (user == null) {
              items.add(const PopupMenuItem<String>(
                value: 'no_user',
                enabled: false,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('User data unavailable'),
                ),
              ));
              return items;
            }

            if (isLoadingStatus) {
              items.add(PopupMenuItem<String>(
                value: 'loading',
                enabled: false,
                child: SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Checking status...'),
                    ],
                  ),
                ),
              ));
              return items;
            }

            if (isBlocked) {
              items.add(PopupMenuItem<String>(
                value: 'unblock_user',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_open, color: Colors.green),
                  title: const Text('Unblock User'),
                ),
              ));
            } else {
              items.add(PopupMenuItem<String>(
                value: 'block_user',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text('Block User'),
                ),
              ));
            }

            return items;
          },
          icon: const Icon(Icons.more_vert, color: Colors.black54),
        );
      })
    ]);
  }

  // Sections -----------------------------------------------------------------
  Widget _buildUserInfoSection() {
    return _cardWrapper(
      titleIcon: Icons.person,
      titleColor: Colors.blue[600]!,
      title: 'User Information',
      child: Obx(() {
        if (userController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userController.hasError.value) {
          return _errorBox(
            'Failed to load user details',
            userController.errorMessage.value,
            onRetry: () => userController.fetchUserById(widget.client.userId),
          );
        }
        final User? user = userController.user.value;
        if (user == null) {
          return const Text('No user data available', style: TextStyle(color: Colors.grey));
        }
        return Column(children: [
          _infoRow('Name', user.name, Icons.person_outline),
            _infoRow('Email', user.email, Icons.email_outlined),
          _infoRow('Phone', user.phone, Icons.phone_outlined),
          _infoRow('Role', user.role, Icons.admin_panel_settings_outlined),
          _infoRow('User ID', user.id.toString(), Icons.badge_outlined),
        ]);
      }),
    );
  }

  Widget _buildClientInfoSection() {
    return _cardWrapper(
      titleIcon: Icons.work_outline,
      titleColor: Colors.green[600]!,
      title: 'Professional Information',
      child: Obx(() {
        final client = professionalController.currentClient.value ?? widget.client;
        return Column(children: [
          _infoRow('Client ID', client.clientId.toString(), Icons.tag),
          _infoRow('Preferred Job', client.preferredJob ?? 'Not specified', Icons.work),
          _infoRow('Gender', client.gender ?? 'Not specified', Icons.person),
          _infoRow('Date of Birth', client.dob != null ? client.dob!.toLocal().toString().split(' ')[0] : 'Not specified', Icons.cake),
          if (client.description != null && client.description!.isNotEmpty)
            _infoRow('Description', client.description!, Icons.description, multiline: true),
        ]);
      }),
    );
  }

  Widget _buildLocationSection() {
    return _cardWrapper(
      titleIcon: Icons.location_on,
      titleColor: Colors.orange[600]!,
      title: 'Location Details',
      child: Obx(() {
        final client = professionalController.currentClient.value ?? widget.client;
        return Column(children: [
          _infoRow('Place', client.place ?? 'Not specified', Icons.home),
          _infoRow('District', client.district ?? 'Not specified', Icons.location_city),
          _infoRow('State', client.state ?? 'Not specified', Icons.map),
          _infoRow('Pincode', client.pincode ?? 'Not specified', Icons.local_post_office),
          if (client.latitude != null && client.longitude != null)
            _infoRow('Coordinates', '${client.latitude}, ${client.longitude}', Icons.gps_fixed),
        ]);
      }),
    );
  }

  Widget _buildStatusSection() {
    return _cardWrapper(
      titleIcon: Icons.verified_user,
      titleColor: Colors.purple[600]!,
      title: 'Status Information',
      child: Column(children: [
        _statusRow('Admin Approved', widget.client.isAdminApproved, Icons.admin_panel_settings),
        _statusRow('KYC Verified', widget.client.isKycVerified, Icons.verified),
        _infoRow('Created Date', widget.client.formattedCreatedDate, Icons.calendar_today),
        _infoRow('Updated Date', widget.client.updatedAt.toLocal().toString(), Icons.update),
      ]),
    );
  }

  Widget _buildExperienceSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 16),
      if (widget.client.experiences.isEmpty)
        const Text('No experience information provided.', style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic))
      else
        Wrap(spacing: 16, runSpacing: 16, children: widget.client.experiences.map((exp) => _experienceCard(
              exp.title ?? 'Position Not Specified',
              exp.company ?? 'Company Not Specified',
              exp.duration ?? 'Duration Not Specified',
              widget.client.location,
              exp.description ?? 'No description provided',
              exp.experienceCertificate ?? '',
            )).toList()),
    ]);
  }

  Widget _experienceCard(String title, String company, String duration, String location,
      [String description = '', String certificateUrl = '']) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(company, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('Duration: $duration', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Expanded(child: Text(location.isNotEmpty ? location : 'Location not specified', style: const TextStyle(fontSize: 12, color: Colors.grey)))
        ]),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Description:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          if (certificateUrl.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _viewDocument('Experience Document', _resolveMediaUrl(certificateUrl)),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('View', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              ),
            ),
        ]
      ]),
    );
  }

  Widget _buildEducationSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Education', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 16),
      if (widget.client.education.isEmpty)
        const Text('No education information provided.', style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic))
      else
        Wrap(spacing: 16, runSpacing: 16, children: widget.client.education.map((edu) => _educationCard(
              edu.degree ?? 'Degree Not Specified',
              edu.institution ?? 'Institution Not Specified',
              (edu.startDate != null && edu.endDate != null) ? '${edu.startDate} - ${edu.endDate}' : 'Duration Not Specified',
              edu.fieldOfStudy,
              edu.grade,
              edu.certificate ?? '',
            )).toList()),
    ]);
  }

  Widget _educationCard(String degree, String university, String duration,
      [String? fieldOfStudy, String? grade, String certificateUrl = '']) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(degree, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(university, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        if (fieldOfStudy != null && fieldOfStudy.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Field: $fieldOfStudy', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(duration, style: const TextStyle(fontSize: 10, color: Colors.grey))),
          if (certificateUrl.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _viewDocument('Education Document', _resolveMediaUrl(certificateUrl)),
              icon: const Icon(Icons.visibility, size: 14),
              label: const Text('View', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
            ),
          if (grade != null && grade.isNotEmpty)
            Text('Grade: $grade', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Expanded(child: Text(widget.client.location.isNotEmpty ? widget.client.location : 'Location not specified', style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ]),
      ]),
    );
  }

  Widget _buildCertificatesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Certificates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 16),
      if (widget.client.certificates.isEmpty)
        const Text('No certificates information provided.', style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic))
      else
        ListView.builder(
          shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.client.certificates.length,
          itemBuilder: (_, i) {
            final cert = widget.client.certificates[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))
              ]),
              child: Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.verified_user, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cert.name ?? 'Certificate Name Not Specified', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (cert.issuer != null && cert.issuer!.isNotEmpty)
                    Text('Issued by: ${cert.issuer}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (cert.issueDate != null && cert.issueDate!.isNotEmpty)
                    Text('Issue Date: ${cert.issueDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                if (cert.certificateUrl != null && cert.certificateUrl!.isNotEmpty)
                  IconButton(
                    onPressed: () => _viewDocument(cert.name ?? 'Certificate', cert.certificateUrl!),
                    icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                  )
              ]),
            );
          },
        )
    ]);
  }

  Widget _buildLanguagesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Languages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 16),
      if (widget.client.languages.isEmpty)
        const Text('No language information provided.', style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic))
      else
        Wrap(spacing: 12, runSpacing: 12, children: widget.client.languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue[200]!)),
              child: Text(lang.language ?? 'Unknown Language', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            )).toList())
    ]);
  }

  Widget _buildApprovalSection() {
    return Obx(() {
      final client = professionalController.currentClient.value ?? widget.client;
      if (client.isAdminApproved) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[200]!)),
          child: Row(children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Professional Approved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('This professional has been approved and can receive job offers.', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
            )
          ]),
        );
      }
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Admin Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Review all the information above and decide whether to approve or reject this professional.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleRejection,
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleApproval,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green, side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
                child: const Text('Approve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )
          ])
        ]),
      );
    });
  }

  // Actions ------------------------------------------------------------------
  void _handleApproval() {
    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Approve Professional'),
              content: Text('Approve this professional?\n\nClient ID: ${widget.client.clientId}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green, side: const BorderSide(color: Colors.green), elevation: 0),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _approveClient();
                    },
                    child: const Text('Approve'))
              ],
            ));
  }

  void _handleRejection() {
    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Reject Professional'),
              content: Text('Reject this professional?\n\nClient ID: ${widget.client.clientId}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), elevation: 0),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _rejectClient();
                    },
                    child: const Text('Reject'))
              ],
            ));
  }

  Future<void> _approveClient() async {
    final success = await Get.find<ProfessionalController>().approveClient(widget.client.clientId);
    if (!mounted || !success) return;
    Get.snackbar('Success', 'Professional approved successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green[100], colorText: Colors.green[800]);
  }

  Future<void> _rejectClient() async {
    final success = await Get.find<ProfessionalController>().rejectClient(widget.client.clientId);
    if (!mounted || !success) return;
    Get.snackbar('Success', 'Professional rejected', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[800]);
  }

  void _handleBlockUser() {
    final user = userController.user.value;
    if (user == null) {
      Get.snackbar('Error', 'User not loaded yet', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[800]);
      return;
    }
    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Block User'),
              content: Text('Block user "${user.name}" (ID: ${user.id})?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), elevation: 0),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await userController.blockUser(user.id);
                    },
                    child: const Text('Block'))
              ],
            ));
  }

  void _handleUnblockUser() {
    final user = userController.user.value;
    if (user == null) {
      Get.snackbar('Error', 'User not loaded yet', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[800]);
      return;
    }
    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Unblock User'),
              content: Text('Unblock user "${user.name}" (ID: ${user.id})?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green, side: const BorderSide(color: Colors.green), elevation: 0),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await userController.unblockUser(user.id);
                    },
                    child: const Text('Unblock'))
              ],
            ));
  }

  // UI helpers ----------------------------------------------------------------
  Widget _cardWrapper({required IconData titleIcon, required Color titleColor, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(titleIcon, color: titleColor, size: 24), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 20),
        child
      ]),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, {bool multiline = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[700]), maxLines: multiline ? null : 1, overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis),
        )
      ]),
    );
  }

  Widget _statusRow(String label, bool status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: status ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: status ? Colors.green[200]! : Colors.red[200]!)),
      child: Row(children: [
        Icon(icon, size: 18, color: status ? Colors.green[600] : Colors.red[600]),
        const SizedBox(width: 12),
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        const SizedBox(width: 12),
        Expanded(
          child: Row(children: [
            Icon(status ? Icons.check_circle : Icons.cancel, size: 16, color: status ? Colors.green[600] : Colors.red[600]),
            const SizedBox(width: 8),
            Text(status ? 'Yes' : 'No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: status ? Colors.green[600] : Colors.red[600]))
          ]),
        )
      ]),
    );
  }

  Widget _errorBox(String title, String message, {VoidCallback? onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
      child: Row(children: [
        Icon(Icons.error, color: Colors.red[600]),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(message, style: const TextStyle(fontSize: 12))
        ])),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry'))
      ]),
    );
  }

  void _viewDocument(String title, String url) {
    final resolved = _resolveMediaUrl(url);
    if (Uri.tryParse(resolved)?.path.toLowerCase().endsWith('.pdf') ?? false) {
      viewPdfInline(title, resolved, context);
      return;
    }
    showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Row(children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close))
                  ]),
                  Row(children: [
                    Expanded(
                        child: Text(resolved, style: const TextStyle(fontSize: 12, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                    IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: resolved));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
                        },
                        icon: const Icon(Icons.copy, size: 18))
                  ]),
                  const SizedBox(height: 16),
                  Expanded(
                      child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(resolved, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Text('Failed to load image'))),
                    ),
                  ))
                ]),
              ),
            ));
  }
}
