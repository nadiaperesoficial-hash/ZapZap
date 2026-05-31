import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'chat_list_item.dart';

class ChatListView extends StatefulWidget {
  final ValueNotifier<Map<int, Map<String, dynamic>>> chatsNotifier;
  final int? folderId;
  final Map<String, bool> fileExistsCache;
  final Map<String, Uint8List?> miniThumbnailCache;
  final Function(int) onChatTap;

  const ChatListView({
    super.key,
    required this.chatsNotifier,
    required this.folderId,
    required this.fileExistsCache,
    required this.miniThumbnailCache,
    required this.onChatTap,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  @override
  void initState() {
    super.initState();
    widget.chatsNotifier.addListener(_onChatsUpdated);
  }

  @override
  void dispose() {
    widget.chatsNotifier.removeListener(_onChatsUpdated);
    super.dispose();
  }

  void _onChatsUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chats = _getFilteredAndSortedChats();

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Nenhuma conversa',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: PageStorageKey('chat_list_${widget.folderId}'),
      itemCount: chats.length,
      addAutomaticKeepAlives: true,
      cacheExtent: 1000,
      // Divisória suave só entre itens — estilo LINE
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        indent: 72,
        endIndent: 0,
        color: Color(0xFFF0F0F0),
      ),
      itemBuilder: (context, index) => ChatListItem(
        chat: chats[index],
        currentFolderId: widget.folderId,
        fileExistsCache: widget.fileExistsCache,
        miniThumbnailCache: widget.miniThumbnailCache,
        onTap: widget.onChatTap,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAndSortedChats() {
    var allChats = widget.chatsNotifier.value.values.toList();

    if (widget.folderId != null && widget.folderId != -1) {
      allChats = allChats
          .where((chat) =>
              (chat['folderIds'] as List?)?.contains(widget.folderId) ?? false)
          .toList();
    }

    allChats.sort((a, b) {
      final aPositions = a['positions'] as List<dynamic>?;
      final bPositions = b['positions'] as List<dynamic>?;

      final aPosition = aPositions
          ?.cast<Map<String, dynamic>?>()
          .firstWhere(
            (p) => p?['list']?['chatFolderId'] == widget.folderId,
            orElse: () => null,
          );

      final bPosition = bPositions
          ?.cast<Map<String, dynamic>?>()
          .firstWhere(
            (p) => p?['list']?['chatFolderId'] == widget.folderId,
            orElse: () => null,
          );

      final aIsPinned = aPosition?['isPinned'] as bool? ?? false;
      final bIsPinned = bPosition?['isPinned'] as bool? ?? false;

      if (aIsPinned != bIsPinned) return bIsPinned ? 1 : -1;

      if (aIsPinned && bIsPinned) {
        final aOrder =
            int.tryParse(aPosition?['order']?.toString() ?? '0') ?? 0;
        final bOrder =
            int.tryParse(bPosition?['order']?.toString() ?? '0') ?? 0;
        return bOrder.compareTo(aOrder);
      }

      final aDate = a['lastMessage']?['date'] as int? ?? 0;
      final bDate = b['lastMessage']?['date'] as int? ?? 0;
      return bDate.compareTo(aDate);
    });

    return allChats;
  }
}
