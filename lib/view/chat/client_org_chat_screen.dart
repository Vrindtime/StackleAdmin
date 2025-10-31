import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/client_chat_controller.dart';
import 'package:stackle_admin/controllers/professional_controller.dart';
import 'package:stackle_admin/data/models/client.dart';
import 'package:stackle_admin/core/api_base.dart';

/// A minimal screen showing client <-> organization conversations.
/// UI updated to match the app's existing style and show client info (if available).
class ClientOrgChatScreen extends StatefulWidget {
  final int clientId;
  final String clientName;
  const ClientOrgChatScreen({Key? key, required this.clientId, required this.clientName}) : super(key: key);

  @override
  State<ClientOrgChatScreen> createState() => _ClientOrgChatScreenState();
}

class _ClientOrgChatScreenState extends State<ClientOrgChatScreen> {
  late ClientChatController controller;
  ProfessionalController? professionalController;
  Client? clientModel;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ClientChatController>() ? Get.find<ClientChatController>() : Get.put(ClientChatController());
    // try to find ProfessionalController to reuse loaded client data if available
    if (Get.isRegistered<ProfessionalController>()) {
      professionalController = Get.find<ProfessionalController>();
      final current = professionalController!.currentClient.value;
      if (current != null && current.clientId == widget.clientId) {
        clientModel = current;
      }
    }
    controller.fetchConversationsForClient(widget.clientId);
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return 'C';
    return name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase();
  }

  String _resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final baseRoot = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      // If it's already an absolute URL, return as-is
      return trimmed;
    }
    if (trimmed.startsWith('/media/')) return '${baseRoot.replaceAll(RegExp(r'/+\$'), '')}$trimmed';
    final idx = trimmed.indexOf('/media/');
    if (idx != -1) {
      final rel = trimmed.substring(idx + '/media/'.length);
      return '${baseRoot.replaceAll(RegExp(r'/+\$'), '')}/media/$rel';
    }
    final rel = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${baseRoot.replaceAll(RegExp(r'/+\$'), '')}/media/$rel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Column(
        children: [
          // Header similar to ProfessionalDetailScreen for consistent UI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue[50],
                backgroundImage: (() {
                  final img = clientModel?.image;
                  if (img != null && img.toString().trim().isNotEmpty) {
                    final resolved = _resolveMediaUrl(img.toString());
                    if (resolved.isNotEmpty) return NetworkImage(resolved);
                  }
                  return null;
                })() as ImageProvider<Object>?,
                child: (() {
                  final hasImage = clientModel?.image != null && clientModel!.image!.trim().isNotEmpty;
                  if (hasImage) return null;
                  return Text(_initials(widget.clientName), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                })(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      widget.clientName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A202C)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('Client ID: ${clientModel?.clientId ?? widget.clientId}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ]),
              ),
            ]),
          ),

          // Body
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final err = controller.errorMessage.value;
              if (err != null && err.isNotEmpty) {
                return Center(child: Text('Failed to load conversations: $err'));
              }

              final convs = controller.conversations;
              if (convs.isEmpty) {
                return const Center(child: Text('No conversations yet for this client.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: convs.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, idx) {
                  final c = convs[idx];
                  final convId = c['conversationId'] ?? c['id'] ?? c['conversation_id'];
                  final org = c['organization'] ?? c['org'] ?? <String,dynamic>{};
                  final orgName = org is Map ? (org['name'] ?? org['title'] ?? 'Organization') : (org?.toString() ?? 'Organization');
                  final lastMessage = c['last_message'] ?? c['lastMessage'] ?? c['preview'] ?? '';

                  // attempt to show org logo if present
                  final String orgLogo = (org is Map && (org['logo'] ?? org['image']) != null) ? (org['logo'] ?? org['image']).toString() : '';
                  final ImageProvider<Object>? orgImage = (orgLogo.isNotEmpty) ? (NetworkImage(_resolveMediaUrl(orgLogo))) : null;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    leading: CircleAvatar(backgroundImage: orgImage, child: orgImage == null ? Text((orgName.toString().isNotEmpty ? orgName.toString()[0] : 'O')) : null),
                    title: Text(orgName.toString()),
                    subtitle: Text(lastMessage.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
                      if (id != null) {
                        await controller.fetchMessagesForConversation(id);
                        if (!mounted) return;
                        showModalBottomSheet(context: context, builder: (_) => _buildMessagesSheet(controller));
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSheet(ClientChatController controller) {
    return Obx(() {
      if (controller.isLoadingMessages.value) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
      final err = controller.messagesError.value;
      if (err != null && err.isNotEmpty) return SizedBox(height: 200, child: Center(child: Text('Failed to load messages: $err')));
      final msgs = controller.messages;
      if (msgs.isEmpty) return SizedBox(height: 200, child: Center(child: Text('No messages')));

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: msgs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final m = msgs[i];
            final text = (m['message'] ?? m['text'] ?? m['content'] ?? '').toString();
            final ts = (m['sent_at'] ?? m['created_at'] ?? '').toString();
            return ListTile(
              title: Text(text),
              subtitle: Text(ts, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            );
          },
        ),
      );
    });
  }
}
