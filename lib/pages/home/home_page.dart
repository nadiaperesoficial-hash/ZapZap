import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nullgram/pages/home/widgets/chat_list_view.dart';
import 'package:nullgram/tdlib/constants.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';
import '../chat/chat_page.dart';
import 'menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<Map<int, Map<String, dynamic>>> chats = ValueNotifier({});
  final ValueNotifier<List<Map<String, dynamic>>> folders = ValueNotifier([]);
  int selectedFolderIndex = 0;
  TabController? _tabController;
  final Map<int, bool> memberStatus = {};
  final Map<int, dynamic> users = {};
  final Map<int, dynamic> supergroups = {};
  final Map<String, bool> _fileExistsCache = {};
  final Map<String, Uint8List?> _miniThumbnailCache = {};

  // ── Busca ────────────────────────────────────────────────────────────────
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Resultados separados: locais e globais
  List<Map<String, dynamic>> _localResults = [];
  List<Map<String, dynamic>> _globalResults = [];
  bool _isSearchLoading = false;
  Timer? _debounce;

  // ── Filtro local (chats já carregados) ───────────────────────────────────
  List<Map<String, dynamic>> get _filteredLocalChats {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return chats.value.values
        .where((c) => (c['title'] ?? '').toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadChats();

    TDLibClient.chatUpdates.listen((update) async {
      final type = update['@type'];
      switch (type) {
        case updateNewChatConst:
          final chatData = update['chat'];
          final chatId = chatData['id'];
          final user = users[chatId];
          if (user != null) chatData["user"] = user;
          final supergroup = supergroups[chatId];
          if (supergroup != null) chatData["supergroup"] = supergroup;
          var status = memberStatus[chatData['type']?["supergroupId"]] ?? true;
          if (!status) return;
          final photo = chatData['photo'];
          if (photo != null &&
              photo['small']?['local']?['path'] == "" &&
              photo['small']?['remote']?['id'] != null) {
            TDLibClient.downloadFile(fileId: photo['small']['id'])
                .catchError((_) {});
          }
          final updatedChats =
              Map<int, Map<String, dynamic>>.from(chats.value);
          updatedChats[chatId] = chatData;
          _updateFolderUnreadCounts();
          chats.value = updatedChats;
          setState(() {});

        case updateChatFoldersConst:
          final chatFolders = update['chatFolders'] ?? [];
          final allChatsFolder = {
            'id': -1,
            'name': {'text': 'All chats'},
            'unreadCount': 0,
          };
          final newFolders = <Map<String, dynamic>>[
            allChatsFolder,
            ...chatFolders.map((folder) => {
                  'id': folder['id'],
                  'name': {'text': folder['name']['text']['text']},
                  'unreadCount': 0,
                })
          ];
          if (_tabController == null ||
              _tabController!.length != newFolders.length) {
            _tabController?.dispose();
            _tabController =
                TabController(length: newFolders.length, vsync: this)
                  ..addListener(() {
                    selectedFolderIndex = _tabController!.index;
                  });
          }
          folders.value = newFolders;
          _updateFolderUnreadCounts();
          setState(() {});

        case updateChatPositionConst:
          final chatId = update['chatId'];
          final position = update['position'];
          final existingChat = chats.value[chatId];
          if (existingChat != null) {
            final positions = existingChat['positions'] ?? [];
            final posIndex = positions.indexWhere((p) =>
                p['list']?['chatFolderId'] ==
                position['list']?['chatFolderId']);
            if (posIndex != -1) positions[posIndex] = position;
            else positions.add(position);
            final updatedChats = chats.value;
            updatedChats[chatId] = {...existingChat, 'positions': positions};
            chats.value = updatedChats;
          }

        case updateChatLastMessageConst:
          final chatId = update['chatId'];
          final lastMessage = update['lastMessage'];
          final newPositions = update['positions'];
          final existingChat = chats.value[chatId];
          if (existingChat != null) {
            final mergedPositions = List<Map<String, dynamic>>.from(
                newPositions?.map((e) => e) ?? []);
            final existingPositions = existingChat['positions'];
            if (existingPositions != null) {
              for (final existingPos in existingPositions) {
                if (!mergedPositions.any((p) =>
                    p['list']?['chatFolderId'] ==
                    existingPos['list']?['chatFolderId'])) {
                  mergedPositions.add(existingPos);
                }
              }
            }
            final updatedChats = chats.value;
            updatedChats[chatId] = {
              ...existingChat,
              'lastMessage': lastMessage,
              'positions': mergedPositions
            };
            chats.value = updatedChats;
          }

        case updateChatAddedToListConst:
          final chatId = update['chatId'];
          final folderId = update['chatList']?['chatFolderId'];
          final existingChat = chats.value[chatId];
          if (existingChat != null && folderId != null) {
            final folderIds = existingChat['folderIds'] ?? [];
            if (!folderIds.contains(folderId)) {
              folderIds.add(folderId);
              final updatedChats = chats.value;
              updatedChats[chatId] = {
                ...existingChat,
                'folderIds': folderIds
              };
              chats.value = updatedChats;
            }
          }

        case updateSupergroupConst:
          var isMember = true;
          var type = update["supergroup"]["status"]["@type"];
          if (type == "ChatMemberStatusLeft" ||
              type == "ChatMemberStatusBanned") isMember = false;
          final id = "-100${update["supergroup"]["id"]}";
          supergroups[int.parse(id)] = update["supergroup"];
          memberStatus[update["supergroup"]["id"]] = isMember;

        case updateUserConst:
          users[update["user"]["id"]] = update["user"];

        case updateUserStatusConst:
          final userId = update['userId'];
          var user = users[userId];
          if (user != null) {
            user['status'] = update['status'];
            final updatedChats = chats.value;
            for (final chatId in updatedChats.keys) {
              final chat = updatedChats[chatId];
              if (chat?['user']?['id'] == userId) {
                updatedChats[chatId] = {
                  ...?chat,
                  'user': {...chat?['user'], 'status': update['status']}
                };
              }
            }
            chats.value = updatedChats;
          }
      }
    });

    TDLibClient.filesUpdates.listen((update) async {
      final type = update['@type'];
      if (type == updateFileConst) {
        final path = update['file']?['local']?['path'];
        final fileId = update['file']?['id'];
        if (path != null && fileId != null) {
          final exists = await File(path).exists();
          if (_fileExistsCache[path] != exists) {
            _fileExistsCache[path] = exists;
            chats.value = chats.value;
          }
        }
      }
    });
  }

  Future<void> _loadChats() async {
    try {
      while (true) {
        var type = await TDLibClient.loadChats();
        if (type != "Ok") break;
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      logger.e('Failed to load chats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateFolderUnreadCounts() {
    final updatedFolders = folders.value;
    for (int i = 0; i < updatedFolders.length; i++) {
      final folder = updatedFolders[i];
      final folderId = folder['id'];
      int unreadChatsCount = 0;
      for (final chat in chats.value.values) {
        final chatUnreadCount = chat['unreadCount'] ?? 0;
        if (chatUnreadCount > 0) {
          if (folderId == -1) {
            unreadChatsCount++;
          } else {
            final chatFolderIds = chat['folderIds'] ?? [];
            if (chatFolderIds.contains(folderId)) unreadChatsCount++;
          }
        }
      }
      updatedFolders[i] = {...folder, 'unreadCount': unreadChatsCount};
    }
    folders.value = updatedFolders;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    _searchFocus.requestFocus();
  }

  void _stopSearch() {
    _debounce?.cancel();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _localResults = [];
      _globalResults = [];
      _isSearchLoading = false;
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _localResults = _filteredLocalChats;
      _globalResults = [];
    });

    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _isSearchLoading = false);
      return;
    }

    setState(() => _isSearchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final results =
            await TDLibClient.searchChatsByTitle(query: value.trim());
        if (!mounted) return;
        // Remove duplicatas com resultados locais
        final localIds = _localResults.map((c) => c['id']).toSet();
        final deduped = (results ?? [])
            .where((c) => !localIds.contains(c['id']))
            .toList();
        setState(() {
          _globalResults = deduped;
          _isSearchLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSearchLoading = false);
      }
    });
  }

  void _openChatFromData(Map<String, dynamic> chatData) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(chat: chatData)),
    );
  }

  void _openChat(int chatID) {
    final chatData = chats.value[chatID];
    if (chatData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(chat: chatData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const HomeMenu(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            if (!_isSearching)
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: folders,
                builder: (context, foldersList, _) {
                  if (foldersList.isEmpty || _tabController == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildFolderTabs(foldersList);
                },
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF111111)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const Expanded(
            child: Text(
              'ZapZap',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF111111), size: 26),
            onPressed: _startSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onTap: () { if (!_isSearching) _startSearch(); },
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle:
                const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
            prefixIcon: const Icon(Icons.search,
                color: Color(0xFFAAAAAA), size: 20),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Color(0xFFAAAAAA), size: 18),
                    onPressed: _stopSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFolderTabs(List<Map<String, dynamic>> foldersList) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFF00BFA5),
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF00BFA5),
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.normal),
        dividerColor: Colors.transparent,
        tabs: foldersList.map((folder) {
          final unreadCount = folder['unreadCount'] ?? 0;
          return Tab(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(folder['name']['text']),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    // ── Modo busca ───────────────────────────────────────────────────────
    if (_isSearching) {
      final hasLocal = _localResults.isNotEmpty;
      final hasGlobal = _globalResults.isNotEmpty;
      final isEmpty =
          !hasLocal && !hasGlobal && !_isSearchLoading && _searchQuery.isNotEmpty;

      if (_searchQuery.isEmpty) {
        return Center(
          child: Text('Digite para buscar',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
        );
      }

      if (_isSearchLoading && !hasLocal) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
      }

      if (isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Nenhum resultado',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 15)),
            ],
          ),
        );
      }

      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // Seção: chats recentes/locais
          if (hasLocal) ...[
            _sectionHeader('Recente'),
            ...  _localResults.map((chat) => _SearchChatTile(
                  chat: chat,
                  onTap: () => _openChat(chat['id']),
                )),
          ],
          // Seção: busca global
          if (hasGlobal) ...[
            _sectionHeader('Busca global'),
            ..._globalResults.map((chat) => _SearchChatTile(
                  chat: chat,
                  onTap: () => _openChatFromData(chat),
                  showMemberCount: true,
                )),
          ],
          if (_isSearchLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00BFA5), strokeWidth: 2)),
            ),
        ],
      );
    }

    // ── Modo normal ──────────────────────────────────────────────────────
    if (folders.value.isEmpty || _tabController == null) {
      return ChatListView(
        chatsNotifier: chats,
        folderId: null,
        fileExistsCache: _fileExistsCache,
        miniThumbnailCache: _miniThumbnailCache,
        onChatTap: _openChat,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: folders.value.map((folder) {
        return ChatListView(
          chatsNotifier: chats,
          folderId: folder['id'] == -1 ? null : folder['id'],
          fileExistsCache: _fileExistsCache,
          miniThumbnailCache: _miniThumbnailCache,
          onChatTap: _openChat,
        );
      }).toList(),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFAAAAAA),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Tile de resultado de busca ───────────────────────────────────────────────
class _SearchChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  final bool showMemberCount;

  const _SearchChatTile({
    required this.chat,
    required this.onTap,
    this.showMemberCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = chat['title'] ?? '';
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final unread = chat['unreadCount'] ?? 0;
    final memberCount = chat['supergroup']?['memberCount'] ??
        chat['memberCount'] ?? 0;

    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF42A5F5),
      const Color(0xFFFF7043),
    ];
    final color = title.isNotEmpty
        ? colors[title.codeUnitAt(0) % colors.length]
        : colors[0];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: unread > 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: const Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showMemberCount && memberCount > 0)
                    Text(
                      '$memberCount membros',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFAAAAAA)),
                    ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
