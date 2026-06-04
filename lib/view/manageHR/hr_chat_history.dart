import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/instance_manager.dart';
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/controllers/hr_controller.dart';
import 'package:stackle_admin/core/routing.dart';
import 'package:stackle_admin/data/models/organization.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/chat_controller.dart';
import 'package:stackle_admin/controllers/org_chat_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

class HRChatDetailScreen extends StatefulWidget {
  const HRChatDetailScreen({Key? key}) : super(key: key);

  @override
  State<HRChatDetailScreen> createState() => _HRChatDetailScreenState();
}

class _HRChatDetailScreenState extends State<HRChatDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedChat = '';
  late HRController hrController;
  Organization? organization; // resolved org details
  Map<String, dynamic>? chatOrgMap; // raw organization JSON from chat API (preferred)
  // whether we've collected basic org info (name/phone/id) and can show the UI
  bool _orgInfoReady = false;
  bool _isLoadingChats = false;
  String? _chatsErrorMessage;
  int? _selectedConversationId;
  Map<String, dynamic>? _selectedConversation;

  // new: chat controller
  late ChatController chatController;
  late OrgChatController orgChatController;

  final List<Map<String, dynamic>> chatUsers = [];
  final List<Map<String, dynamic>> chatUsersOrg = [];
  String selectedChatOrg = '';
  // active org conversation id (for org-to-org tab)
  int? _activeOrgConvoId;
  Map<String, dynamic>? _selectedConversationOrg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    // Resolve HR controller and organization argument (orgId expected)
    hrController = Get.isRegistered<HRController>()
        ? Get.find<HRController>()
        : Get.put(HRController(), permanent: true);

    // register chat controller (singleton tied to Get lifecycle)
    chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController(), permanent: true);

    orgChatController = Get.isRegistered<OrgChatController>()
        ? Get.find<OrgChatController>()
        : Get.put(OrgChatController(), permanent: true);

    // When user switches to the Organization Chat tab, ensure the org controller
    // has the local org id and preload conversations/messages for the first convo.
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 1) {
        final id = organization?.id;
        if (id != null) {
          orgChatController.setLocalOrgId(id);
          // fetch conversations; if there are any, preload messages for the first one
          orgChatController.fetchConversations(id).then((_) {
            if (orgChatController.conversations.isNotEmpty) {
              final first = orgChatController.conversations.first;
              final dynamic convId = first['id'];
              final int? cid = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
              if (cid != null) {
                _activeOrgConvoId = cid;
                _selectedConversationOrg = first;
                orgChatController.fetchMessages(cid);
                setState(() {});
              }
            }
          });
        }
      }else if (_tabController.index == 0) {
        // Ensure chat controller has local org id set
        final id = organization?.id;
        if (id != null) {
          chatController.fetchConversations(id);
        }
      }else{
        Get.find<OrgChatController>().fetchConversations(organization!.id);
      }
    });

    // listen to chat controller changes and update local state for UI
    ever<Map<String, dynamic>?>(chatController.organization, (val) {
      if (!mounted) return;
      setState(() {
        chatOrgMap = val; // keep raw JSON; UI will prefer chatOrgMap fields
        // mark org info ready when chat API returns organization object
        if (val != null) {
          _orgInfoReady = true;
        }
        // keep Organization model only if HRController has the full model available
        // leave `organization` unchanged here; _resolveOrganizationAndChats will set it if available
      });
    });

    ever<List<Map<String, dynamic>>>(chatController.conversations, (val) {
      // rebuild chatUsers list when conversations update
      if (!mounted) return;
      final List<Map<String, dynamic>> newChatUsers = [];
      for (final item in chatController.conversations) {
        final conversation = Map<String, dynamic>.from(item);
        final client = conversation['client'];
        final name = client != null && client['name'] != null
            ? client['name'].toString()
            : 'Unknown';
        newChatUsers.add({
          'name': name,
          'isSelected': false,
          'conversationId': conversation['id'],
          'conversation': conversation,
        });
      }

      int? selectedId = _selectedConversationId;
      Map<String, dynamic>? selectedConversation = _selectedConversation;
      String selectedName = selectedChat;
      bool containsSelected = false;

      if (selectedId != null) {
        for (final user in newChatUsers) {
          final dynamic convId = user['conversationId'];
          final int? id = convId is int ? convId : int.tryParse(convId.toString());
          if (id != null && id == selectedId) {
            user['isSelected'] = true;
            selectedName = user['name']?.toString() ?? selectedName;
            final conversation = user['conversation'];
            if (conversation is Map<String, dynamic>) {
              selectedConversation = conversation;
            }
            containsSelected = true;
            break;
          }
        }
      }

      if (newChatUsers.isNotEmpty && !containsSelected) {
        final first = newChatUsers.first;
        first['isSelected'] = true;
        final dynamic convId = first['conversationId'];
        selectedId = convId is int ? convId : int.tryParse(convId.toString());
        selectedName = first['name']?.toString() ?? '';
        final conversation = first['conversation'];
        if (conversation is Map<String, dynamic>) {
          selectedConversation = conversation;
        }
      } else if (newChatUsers.isEmpty) {
        selectedId = null;
        selectedName = '';
        selectedConversation = null;
      }

      final bool shouldFetch = selectedId != null &&
          (_selectedConversationId != selectedId || chatController.messages.isEmpty);

      setState(() {
        chatUsers
          ..clear()
          ..addAll(newChatUsers);
        selectedChat = selectedName;
        _selectedConversationId = selectedId;
        _selectedConversation = selectedConversation;
      });

      if (shouldFetch) {
        _loadMessagesForConversation(selectedId, conversation: selectedConversation, useOrgController: false);
      }
    });

    // Listen to org chat controller conversations to populate org chat list
    ever<List<Map<String, dynamic>>>(orgChatController.conversations, (val) {
      if (!mounted) return;
      final List<Map<String, dynamic>> newChatUsers = [];
      for (final item in orgChatController.conversations) {
        final conversation = Map<String, dynamic>.from(item);
        final other = conversation['other_org'] ?? conversation['other_organization'] ?? conversation['other'] ?? conversation['recipient'];
        final name = other != null && other['name'] != null ? other['name'].toString() : 'Unknown';
        newChatUsers.add({
          'name': name,
          'isSelected': false,
          'conversationId': conversation['id'],
          'conversation': conversation,
        });
      }

      int? selectedId = _activeOrgConvoId;
      Map<String, dynamic>? selectedConversation = _selectedConversationOrg;
      String selectedName = selectedChatOrg;
      bool containsSelected = false;

      if (selectedId != null) {
        for (final user in newChatUsers) {
          final dynamic convId = user['conversationId'];
          final int? id = convId is int ? convId : int.tryParse(convId.toString());
          if (id != null && id == selectedId) {
            user['isSelected'] = true;
            selectedName = user['name']?.toString() ?? selectedName;
            final conversation = user['conversation'];
            if (conversation is Map<String, dynamic>) {
              selectedConversation = conversation;
            }
            containsSelected = true;
            break;
          }
        }
      }

      if (newChatUsers.isNotEmpty && !containsSelected) {
        final first = newChatUsers.first;
        first['isSelected'] = true;
        final dynamic convId = first['conversationId'];
        selectedId = convId is int ? convId : int.tryParse(convId.toString());
        selectedName = first['name']?.toString() ?? '';
        final conversation = first['conversation'];
        if (conversation is Map<String, dynamic>) {
          selectedConversation = conversation;
        }
      } else if (newChatUsers.isEmpty) {
        selectedId = null;
        selectedName = '';
        selectedConversation = null;
      }

      final bool shouldFetch = selectedId != null && (_activeOrgConvoId != selectedId || orgChatController.messages.isEmpty);

      setState(() {
        chatUsersOrg
          ..clear()
          ..addAll(newChatUsers);
        selectedChatOrg = selectedName;
        _activeOrgConvoId = selectedId;
        _selectedConversationOrg = selectedConversation;
      });

      if (shouldFetch) {
        _loadMessagesForConversation(selectedId, conversation: selectedConversation, useOrgController: true);
      }
    });

    // Try to read orgId from navigation arguments or named route parameters
    final arg = Get.arguments;
    int? orgId;
    if (arg is int) {
      orgId = arg;
    } else if (arg is Map && arg['orgId'] is int) {
      orgId = arg['orgId'] as int;
    }
    // also support Get.parameters (route param from path /chatlists/:orgId)
    if (orgId == null) {
      final p = Get.parameters['orgId'];
      if (p != null) {
        orgId = int.tryParse(p);
      }
    }

    if (orgId != null) {
      _resolveOrganizationAndChats(orgId);
    } else {
      // If no orgId passed, try to use currentOrganization if set
      final cur = hrController.currentOrganization.value;
      if (cur != null) {
        organization = cur;
        // still try to fetch convos for the current org
        chatController.fetchConversations(cur.id);
        // we already have basic info from HRController
        setState(() { _orgInfoReady = true; });
      } else {
        // try to load organizations once so we can collect basic org info if available
        hrController.fetchOrganizations().then((_) {
          final after = hrController.currentOrganization.value;
          if (after != null) {
            setState(() {
              organization = after;
              _orgInfoReady = true;
            });
            chatController.fetchConversations(after.id);
          } else {
            // nothing found — mark ready so UI can render a fallback instead of blocking forever
            setState(() { _orgInfoReady = true; });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _resolveOrganizationAndChats(int orgId) async {
    // Try to find organization locally first
    organization = hrController.organizations.where((o) => o.id == orgId).isNotEmpty
        ? hrController.organizations.where((o) => o.id == orgId).first
        : null;

    if (organization == null) {
      // fetch org list and try again
      await hrController.fetchOrganizations();
      organization = hrController.organizations.where((o) => o.id == orgId).isNotEmpty
          ? hrController.organizations.where((o) => o.id == orgId).first
          : null;
    }

    // Ask chat controller to fetch convos; it will set organization if returned by API.
    await chatController.fetchConversations(orgId);

    // If chat API returned an organization object, chatController.organization was set and we already listened to it.
    // Otherwise fallback to the org found locally above (if any)
    if (mounted) {
      if (chatController.organization.value == null && organization != null) {
        // keep local organization found from HRController
        setState(() {});
      } else {
        // chatController.organization was set and ever() has updated local organization variable
        setState(() {});
      }
    }
  }

  

  

  // Resolve logo URL from a raw string (used when chat API returns logo in JSON)
  String _resolveLogoFromString(String? logo) {
    if (logo == null || logo.trim().isEmpty) return '';
    final trimmed = logo.trim();
    final baseRoot = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    try {
      final uri = Uri.parse(trimmed);
      if (uri.scheme == 'http' || uri.scheme == 'https') return trimmed;
    } catch (_) {}
    final root = baseRoot.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('/media/')) return '$root$trimmed';
    final idx = trimmed.indexOf('/media/');
    if (idx != -1) {
      final rel = trimmed.substring(idx + '/media/'.length);
      return '$root/media/$rel';
    }
    final rel = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '$root/media/$rel';
  }

  @override
  Widget build(BuildContext context) {
    // Wait until we've collected basic org info (name/phone/id) before showing chat UI.
    // If not ready yet, show a simple centered loader so users can't interact until data is collected.
    if (!_orgInfoReady) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: Row(
        children: [
          // // Use the previously created Sidebar widget
          // const Sidebar(),

          // // Main content area
          Expanded(
            child: _buildMainContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: 24,
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildTabSection(context),
          const SizedBox(height: 24),
          Expanded(child: _buildChatSection(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => (hrController.currentOrganization.value != null) ? Get.back() : Get.offAllNamed(AppRoutes.hr),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF2D3748),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: (() {
                // prefer chat API org JSON, fallback to HRController Organization model
                final logoStr = chatOrgMap != null
                    ? (chatOrgMap!['logo'] ?? '').toString()
                    : (organization?.logo ?? '');
                final resolved = logoStr.isNotEmpty ? _resolveLogoFromString(logoStr) : '';
                if (resolved.isNotEmpty) {
                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.transparent,
                    backgroundImage: NetworkImage(resolved),
                  );
                }
                return Icon(
                  Icons.local_hospital,
                  color: const Color(0xFF3B82F6),
                  size: 28,
                );
              })(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatOrgMap != null
                      ? (chatOrgMap!['name'] ?? organization?.name ?? 'Organization').toString()
                      : (organization?.name ?? 'Organization'),
                  style: TextStyle(
                    fontSize: _getTitleFontSize(context),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 4),
                // prefer phone from chat API JSON, fallback to Organization model
                Builder(builder: (_) {
                  final String phoneStr = chatOrgMap != null
                      ? (chatOrgMap!['phone'] ?? organization?.phone ?? 'Ph: NaN').toString()
                      : (organization?.phone ?? 'Ph: NaN').toString();
                  String idStr = '';
                  if (chatOrgMap != null) {
                    final dynamic rawId = chatOrgMap!['id'];
                    idStr = rawId != null ? rawId.toString() : (organization != null ? organization!.id.toString() : '');
                  } else {
                    idStr = organization != null ? organization!.id.toString() : '';
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phoneStr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (idStr.isNotEmpty) const SizedBox(height: 4),
                      if (idStr.isNotEmpty)
                        Text(
                          'ID: $idStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(
          //     Icons.more_vert,
          //     color: Color(0xFF6B7280),
          //     size: 24,
          //   ),
          // ),
        ],
      ),
    );
  }


  

  Widget _buildTabSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1A202C),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: const Color(0xFFFBBF24),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(8),
        tabs: const [
          Tab(text: 'Client Chat'),
          Tab(text: 'Organization Chat'),
        ],
      ),
    );
  }

  Widget _buildChatSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat users list
          Container(
            width: _getChatListWidth(context),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Color(0xFFF3F4F6),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                // show client or org chats based on active tab
                Builder(builder: (_) {
                  final bool isOrgTab = _tabController.index == 1;
                  final bool isLoading = isOrgTab ? orgChatController.isLoading.value : chatController.isLoading.value;
                  final String? controllerError = isOrgTab ? orgChatController.errorMessage.value : chatController.errorMessage.value;
                  final List<Map<String, dynamic>> listToShow = isOrgTab ? chatUsersOrg : chatUsers;

                  if (isLoading || _isLoadingChats) {
                    return const Expanded(child: Center(child: CircularProgressIndicator()));
                  }

                  if ((controllerError != null && controllerError.isNotEmpty) || _chatsErrorMessage != null) {
                    return Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controllerError ?? _chatsErrorMessage ?? 'Error loading conversations',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: () {
                                final arg = Get.arguments;
                                int? orgId;
                                if (arg is int) orgId = arg;
                                else if (arg is Map && arg['orgId'] is int) orgId = arg['orgId'] as int;
                                if (orgId != null) {
                                  if (isOrgTab) orgChatController.fetchConversations(orgId);
                                  else chatController.fetchConversations(orgId);
                                } else if (organization != null) {
                                  if (isOrgTab) orgChatController.fetchConversations(organization!.id);
                                  else chatController.fetchConversations(organization!.id);
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: listToShow.length,
                      itemBuilder: (context, index) {
                        final user = listToShow[index];
                        return isOrgTab ? _buildOrgChatUserItem(user) : _buildChatUserItem(user);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Chat messages area
          Expanded(
            child: _buildChatMessages(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatUserItem(Map<String, dynamic> user) {
    final String name = user['name']?.toString() ?? '';
    final bool isSelected = user['isSelected'] == true;
    final dynamic convId = user['conversationId'];
    final int? conversationId = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
    final conversation = user['conversation'] is Map<String, dynamic>
        ? user['conversation'] as Map<String, dynamic>
        : null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE5E7EB),
          child: Icon(
            Icons.person,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
          ),
        ),
        onTap: () {
          if (conversationId != null) {
            _loadMessagesForConversation(conversationId, conversation: conversation, useOrgController: false);
          }
        },
      ),
    );
  }

  Widget _buildOrgChatUserItem(Map<String, dynamic> user) {
    final String name = user['name']?.toString() ?? '';
    final bool isSelected = user['isSelected'] == true;
    final dynamic convId = user['conversationId'];
    final int? conversationId = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
    final conversation = user['conversation'] is Map<String, dynamic>
        ? user['conversation'] as Map<String, dynamic>
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE5E7EB),
          child: Icon(
            Icons.apartment,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
          ),
        ),
        onTap: () {
          if (conversationId != null) {
            _loadMessagesForConversation(conversationId, conversation: conversation, useOrgController: true);
          }
        },
      ),
    );
  }

  Map<String, dynamic>? _conversationFromChatUsers(int conversationId) {
    for (final user in chatUsers) {
      final dynamic convId = user['conversationId'];
      final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
      if (id != null && id == conversationId) {
        final data = user['conversation'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    }
    return null;
  }

  Future<void> _loadMessagesForConversation(int conversationId, {Map<String, dynamic>? conversation, bool useOrgController = false}) async {
    if (!mounted) return;

    if (!useOrgController) {
      final Map<String, dynamic>? resolvedConversation = conversation ?? _conversationFromChatUsers(conversationId);

      setState(() {
        for (final user in chatUsers) {
          final dynamic convId = user['conversationId'];
          final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
          user['isSelected'] = id != null && id == conversationId;
        }
        _selectedConversationId = conversationId;
        _selectedConversation = resolvedConversation;
        if (resolvedConversation != null) {
          final client = resolvedConversation['client'];
          if (client is Map && client['name'] != null) {
            selectedChat = client['name'].toString();
          }
        }
        if (selectedChat.isEmpty) {
          for (final user in chatUsers) {
            final dynamic convId = user['conversationId'];
            final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
            if (id != null && id == conversationId) {
              selectedChat = user['name']?.toString() ?? selectedChat;
              break;
            }
          }
        }
      });

      await chatController.fetchMessages(conversationId);
      return;
    }

    // Org chat branch
    Map<String, dynamic>? resolvedConversation = conversation;
    if (resolvedConversation == null) {
      for (final user in chatUsersOrg) {
        final dynamic convId = user['conversationId'];
        final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
        if (id != null && id == conversationId) {
          final data = user['conversation'];
          if (data is Map<String, dynamic>) {
            resolvedConversation = data;
            break;
          }
        }
      }
    }

    setState(() {
      for (final user in chatUsersOrg) {
        final dynamic convId = user['conversationId'];
        final int? id = convId is int ? convId : int.tryParse(convId?.toString() ?? '');
        user['isSelected'] = id != null && id == conversationId;
      }
      _activeOrgConvoId = conversationId;
      _selectedConversationOrg = resolvedConversation;
      if (resolvedConversation != null) {
        final other = resolvedConversation['organization'] ?? resolvedConversation['other_organization'] ?? resolvedConversation['recipient'];
        if (other is Map && other['name'] != null) {
          selectedChatOrg = other['name'].toString();
        }
      }
    });

    await orgChatController.fetchMessages(conversationId);
  }

  Widget _buildChatMessages() {
    return Obx(() {
      final bool isOrgTab = _tabController.index == 1;
      final bool loadingMessages = isOrgTab ? orgChatController.isLoadingMessages.value : chatController.isLoadingMessages.value;
      final String? messagesError = isOrgTab ? orgChatController.messagesError.value : chatController.messagesError.value;
      final List<dynamic> messageList = (isOrgTab ? orgChatController.messages : chatController.messages).toList();
      final int? currentConvoId = isOrgTab ? _activeOrgConvoId : _selectedConversationId;
      final Map<String, dynamic>? selectedConvo = isOrgTab ? _selectedConversationOrg : _selectedConversation;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFF3F4F6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "ConvoID: ${currentConvoId ?? ''}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8,),
                if (selectedConvo != null && _isConversationBlocked(selectedConvo)) ...[
                  Tooltip(
                    message: 'Conversation is blocked',
                    child: Chip(
                      backgroundColor: const Color(0xFFFEE2E2),
                      avatar: const Icon(Icons.block, color: Color(0xFFB91C1C), size: 18),
                      label: Text(
                        'Blocked',
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'by ${_blockedByName(selectedConvo) ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ),
                ] else ...[
                  Tooltip(
                    message: 'Conversation active',
                    child: Chip(
                      backgroundColor: const Color(0xFFEFF6EF),
                      avatar: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                      label: const Text(
                        'Active',
                        style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 8),

                // Reload messages for the selected conversation
                IconButton(
                  onPressed: () {
                    final id = currentConvoId;
                    if (id != null) {
                      _loadMessagesForConversation(id, conversation: selectedConvo, useOrgController: isOrgTab);
                    }
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Builder(
              builder: (_) {
                if (currentConvoId == null) {
                  return const Center(child: Text('Select a conversation to view messages'));
                }
                if (loadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messagesError != null && messagesError.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            messagesError,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            final id = currentConvoId;
                            _loadMessagesForConversation(id, conversation: selectedConvo, useOrgController: isOrgTab);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (messageList.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    try {
                      final dynamic raw = messageList[index];
                      if (raw == null) return const SizedBox.shrink();
                      if (raw is! Map<String, dynamic>) return const SizedBox.shrink();
                      final Map<String, dynamic> message = raw;
                      return _buildMessageBubble(message);
                    } catch (e, st) {
                      // defensive: avoid crashing the whole list when one item is bad
                      debugPrint('Error building message item: $e\n$st');
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final String text = _extractMessageText(message);
    final String timestamp = _formatTimestamp(_extractTimestamp(message));
    final String messageType = (message['message_type'] ?? message['type'] ?? '').toString().toLowerCase();
    final bool isSystemMessage = messageType == 'system' || messageType == 'activity';

    if (isSystemMessage) return _buildSystemMessage(text, timestamp);

    final bool isClient = _isFromClient(message);

    final dynamic fileField = message['file_url'] ?? message['fileUrl'] ?? message['file'] ?? '';
    final String fileUrl = fileField is Map ? (fileField['url'] ?? '').toString() : fileField.toString();
    final bool hasFile = fileUrl.isNotEmpty;

    // derive file meta
    String fileName = '';
    if (hasFile) {
      try {
        final uri = Uri.parse(fileUrl);
    final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.path;
    fileName = seg;
      } catch (_) {
        // best-effort parse
        final parts = fileUrl.split('/');
    final last = parts.isNotEmpty ? parts.last : fileUrl;
    fileName = last;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isClient) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE5E7EB),
              child: const Text('O', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isClient ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasFile) ...[
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (fileUrl.isEmpty) return;
                            // On web open in a new tab; on other platforms fallback to copying URL
                            if (kIsWeb) {
                              try {
                                web.window.open(fileUrl, '_blank');
                              } catch (e) {
                                // fallback to clipboard
                                try {
                                  await Clipboard.setData(ClipboardData(text: fileUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opened in new tab (or copied to clipboard)')));
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open or copy file URL')));
                                }
                              }
                            } else {
                              try {
                                await Clipboard.setData(ClipboardData(text: fileUrl));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File URL copied to clipboard')));
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to copy file URL')));
                              }
                            }
                          },
                          icon: Icon(Icons.document_scanner_outlined),
                          label: Text(fileName),
                          style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ],
                    ),
                    if (text.isNotEmpty) const SizedBox(height: 12),
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: TextStyle(fontSize: 14, color: isClient ? Colors.white : const Color(0xFF374151), height: 1.5),
                      ),
                  ] else ...[
                    Text(
                      text,
                      style: TextStyle(fontSize: 14, color: isClient ? Colors.white : const Color(0xFF374151), height: 1.5),
                    ),
                  ],
                  if (timestamp.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            timestamp,
                            style: TextStyle(fontSize: 12, color: isClient ? Colors.white.withOpacity(0.8) : const Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isClient) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE5E7EB),
              child: const Text('C', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ),
          ],
        ],
      ),
    );
  }

  // Determine whether the message was sent by the client (from org perspective
  // clients appear on the right). Falls back to inspecting sender_type and
  // sender_entity_id vs the known organization id.
  bool _isFromClient(Map<String, dynamic> message) {
    final String senderType = (message['sender_type'] ?? message['senderType'] ?? '').toString().toLowerCase();
    // In org-to-org chats we can't rely on sender_type; instead compare
    // sender_entity_id to the known local org id (provided by OrgChatController).
    if (_tabController.index == 1) {
      final dynamic senderEntityId = message['sender_entity_id'] ?? message['senderEntityId'];
      final int? myOrgId = orgChatController.localOrgId.value ?? organization?.id ?? (chatOrgMap != null ? int.tryParse(chatOrgMap!['id']?.toString() ?? '') : null);
      if (senderEntityId != null && myOrgId != null) {
        final int? entityId = senderEntityId is int ? senderEntityId : int.tryParse(senderEntityId.toString());
        if (entityId != null) return entityId != myOrgId;
      }
      // fallback to direction
      final String direction = (message['direction'] ?? '').toString().toLowerCase();
      if (direction == 'incoming') return true;
      if (direction == 'outgoing') return false;
      return false;
    }

    if (senderType == 'client' || senderType == 'candidate' || senderType == 'user') return true;
    if (senderType == 'organization' || senderType == 'admin' || senderType == 'hr') return false;

    final dynamic senderEntityId = message['sender_entity_id'] ?? message['senderEntityId'];
    final int? orgId = chatOrgMap != null
        ? int.tryParse(chatOrgMap!['id']?.toString() ?? '')
        : organization?.id;
    if (senderEntityId != null && orgId != null) {
      final int? entityId = senderEntityId is int ? senderEntityId : int.tryParse(senderEntityId.toString());
      if (entityId != null) return entityId != orgId;
    }

    final String direction = (message['direction'] ?? '').toString().toLowerCase();
    if (direction == 'incoming') return true;
    if (direction == 'outgoing') return false;

    return false;
  }

  Widget _buildSystemMessage(String text, String timestamp) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (timestamp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                timestamp,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _extractMessageText(Map<String, dynamic> message) {
    final candidates = [
      message['message'],
      message['text'],
      message['content'],
      message['body'],
      message['data'],
    ];
    for (final candidate in candidates) {
      if (candidate != null) {
        final value = candidate.toString().trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  String? _extractTimestamp(Map<String, dynamic> message) {
    final keys = ['sent_at', 'created_at', 'updated_at', 'timestamp'];
    for (final key in keys) {
      final dynamic value = message[key];
      if (value != null) {
        final stringValue = value.toString();
        if (stringValue.isNotEmpty) {
          return stringValue;
        }
      }
    }
    return null;
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

      // If same calendar day, show time only.
      if (parsed.year == now.year && parsed.month == now.month && parsed.day == now.day) {
        return timeStr;
      }

      // For different day but same year show: '29 Oct, 6:38 PM'
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final String month = monthNames[parsed.month - 1];
      final String dateStr = '${parsed.day} $month';

      if (parsed.year == now.year) {
        return '$dateStr, $timeStr';
      }

      // Different year: include year
      return '${parsed.day} $month ${parsed.year}, $timeStr';
    } catch (_) {
      return '';
    }
  }

  // NOTE: message origin logic now handled by _isFromClient which is used
  // to align bubbles from the org perspective (clients appear on the right).

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

  double _getTitleFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 24;
    if (screenWidth > 768) return 22;
    return 20;
  }
}
