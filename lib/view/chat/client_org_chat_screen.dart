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
  int? _selectedConversationId;
  Map<String, dynamic>? _selectedConversation;

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
      backgroundColor: const Color(0xFFFAF7F0),
      body: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context), vertical: 24),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black54), onPressed: () => Navigator.pop(context)),
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
                          Text(widget.clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A202C)), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text('Client ID: ${clientModel?.clientId ?? widget.clientId}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ]),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 18),

                  // Chat area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]),
                      child: Row(
                        children: [
                          // Left: conversations list
                          Container(
                            width: _getChatListWidth(context),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE5E7EB)))),
                            child: Obx(() {
                              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                              final err = controller.errorMessage.value;
                              if (err != null && err.isNotEmpty) return Center(child: Text('Failed to load conversations: $err'));
                              final convs = controller.conversations;
                              if (convs.isEmpty) return const Center(child: Text('No conversations yet for this client.'));
                              return ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: convs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, idx) {
                                  final c = convs[idx];
                                  final convId = c['conversationId'] ?? c['id'] ?? c['conversation_id'];
                                  final org = c['organization'] ?? c['org'] ?? <String,dynamic>{};
                                  final orgName = org is Map ? (org['name'] ?? org['title'] ?? 'Organization') : (org?.toString() ?? 'Organization');
                                  final lastMessage = c['last_message'] ?? c['lastMessage'] ?? c['preview'] ?? '';
                                  final String orgLogo = (org is Map && (org['logo'] ?? org['image']) != null) ? (org['logo'] ?? org['image']).toString() : '';
                                  final ImageProvider<Object>? orgImage = (orgLogo.isNotEmpty) ? (NetworkImage(_resolveMediaUrl(orgLogo))) : null;

                                  final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');

                                  final bool isSelected = id != null && id == _selectedConversationId;

                                  final bool isBlockedConv = _isConversationBlocked(c as Map<String, dynamic>?);
                                  final String? blockedBy = _blockedByName(c as Map<String, dynamic>?);

                                  return InkWell(
                                    onTap: () async {
                                      if (id == null) return;
                                      await controller.fetchMessagesForConversation(id);
                                      if (!mounted) return;
                                      setState(() {
                                        _selectedConversationId = id;
                                        _selectedConversation = Map<String, dynamic>.from(c);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                      child: Row(children: [
                                        CircleAvatar(backgroundImage: orgImage, child: orgImage == null ? Text((orgName.toString().isNotEmpty ? orgName.toString()[0] : 'O')) : null),
                                        const SizedBox(width: 10),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(orgName.toString(), style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(lastMessage.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            Text('ID: ${id ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                            const SizedBox(width: 8),
                                            if (isBlockedConv) ...[
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFECACA), borderRadius: BorderRadius.circular(6)), child: Row(children: [
                                                const Icon(Icons.block, size: 12, color: Color(0xFF991B1B)),
                                                const SizedBox(width: 4),
                                                Text('Blocked', style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                                              ])),
                                              if (blockedBy != null) ...[
                                                const SizedBox(width: 6),
                                                Text('by $blockedBy', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))
                                              ]
                                            ]
                                          ])
                                        ])),
                                      ]),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),

                          // Right: messages
                          Expanded(
                            child: Obx(() {
                              final isLoading = controller.isLoadingMessages.value;
                              final err = controller.messagesError.value;
                              final msgs = controller.messages;
                              return Column(
                                children: [
                                  // Messages header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                                    child: Row(children: [
                                      Expanded(child: Builder(builder: (_) {
                                        if (_selectedConversation == null) return const Text('Select a conversation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
                                        final conv = _selectedConversation!;
                                        final cid = conv['conversationId'] ?? conv['id'] ?? conv['conversation_id'];
                                        final int? cidInt = cid is int ? cid : int.tryParse(cid?.toString() ?? '');
                                        final name = conv['organization']?['name'] ?? conv['org']?['name'] ?? conv['name'] ?? 'Conversation';
                                        final blocked = _isConversationBlocked(conv);
                                        final by = _blockedByName(conv);
                                        final title = blocked ? '$name (ID: ${cidInt ?? ''}) · Blocked${by != null ? ' by $by' : ''}' : '$name (ID: ${cidInt ?? ''})';
                                        return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
                                      })),
                                    ]),
                                  ),

                                  // Messages list
                                  Expanded(
                                    child: isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : (err != null && err.isNotEmpty)
                                            ? Center(child: Text('Failed to load messages: $err'))
                                            : (msgs.isEmpty)
                                                ? const Center(child: Text('No messages'))
                                                : ListView.separated(
                                                    padding: const EdgeInsets.all(12),
                                                    itemCount: msgs.length,
                                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                                    itemBuilder: (context, i) {
                                                      final m = msgs[i];
                                                      return _buildMessageBubble(m);
                                                    },
                                                  ),
                                  ),

                                  const SizedBox(height: 8),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
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

  

  double _getChatListWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 300;
    if (screenWidth > 768) return 250;
    return 200;
  }

  double _getHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 40;
    if (screenWidth > 768) return 32;
    return 24;
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final DateTime parsed = DateTime.parse(isoString).toLocal();
      final now = DateTime.now().toLocal();

      final int hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final String minute = parsed.minute.toString().padLeft(2, '0');
      final String suffix = parsed.hour >= 12 ? 'PM' : 'AM';
      final String timeStr = '$hour:$minute $suffix';

      if (parsed.year == now.year && parsed.month == now.month && parsed.day == now.day) {
        return timeStr;
      }

      final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final String month = monthNames[parsed.month - 1];
      final String dateStr = '${parsed.day} $month';
      if (parsed.year == now.year) {
        return '$dateStr, $timeStr';
      }
      return '${parsed.day} $month ${parsed.year}, $timeStr';
    } catch (_) {
      return '';
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final String text = (message['message'] ?? message['text'] ?? message['content'] ?? '').toString();
    final String ts = (message['sent_at'] ?? message['created_at'] ?? message['timestamp'] ?? '').toString();
    final String time = _formatTimestamp(ts);

    final String senderType = (message['sender_type'] ?? message['senderType'] ?? '').toString().toLowerCase();
    final bool isClient = senderType == 'client' || senderType == 'candidate' || senderType == 'user' || (message['direction'] ?? '').toString().toLowerCase() == 'incoming';

    // Show client messages on the LEFT, organization messages on the RIGHT
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isClient ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // If message is from client and client messages are shown on the left,
          // render client avatar before the bubble so it appears on the same side.
          if (isClient) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE5E7EB),
              child: const Text('C', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ),
            const SizedBox(width: 12),
          ],

          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: isClient ? const Color(0xFFF3F4F6) : const Color(0xFFFDE68A), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: const TextStyle(color: Color(0xFF111827))),
              if (time.isNotEmpty) ...[const SizedBox(height: 6), Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))],
            ]),
          ),

          // If message is from organization, show org avatar on the right side
          if (!isClient) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE5E7EB),
              child: const Text('O', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ),
          ],
        ],
      ),
    );
  }

  // Conversation helpers: determine blocked state and who blocked it.
  bool _isConversationBlocked(Map<String, dynamic>? convo) {
    if (convo == null) return false;
    final dynamic v = convo['is_blocked'] ?? convo['blocked'] ?? convo['isBlocked'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  String? _blockedByName(Map<String, dynamic>? convo) {
    if (convo == null) return null;
    final dynamic b = convo['blocked_by'] ?? convo['blockedBy'] ?? convo['blocked_by_user'];
    if (b == null) return null;
    if (b is Map && b['name'] != null) return b['name'].toString();
    return b.toString();
  }
}
