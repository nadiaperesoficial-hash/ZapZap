import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../chat/widgets/chat_avatar.dart';

class ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  final int? currentFolderId;
  final Map<String, bool> fileExistsCache;
  final Map<String, Uint8List?> miniThumbnailCache;
  final Function(int) onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentFolderId,
    required this.fileExistsCache,
    required this.miniThumbnailCache,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
    final chatId = chat['id'] as int;
    final title = chat['title'] as String? ?? 'Unknown';
    final unreadCount = chat['unreadCount'] as int? ?? 0;

    final positions = chat['positions'] as List<dynamic>?;
    final currentPosition = positions
        ?.cast<Map<String, dynamic>?>()
        .firstWhere(
          (p) => p?['list']?['chatFolderId'] == currentFolderId,
          orElse: () => null,
        );
    final isPinned = currentPosition?['isPinned'] as bool? ?? false;

    final timeStr = lastMessage != null
        ? _formatTime(lastMessage['date'] as int)
        : '';

    return InkWell(
      key: ValueKey('chat_$chatId'),
      onTap: () => onTap(chatId),
      splashColor: const Color(0xFFE8F5E9),
      highlightColor: const Color(0xFFF0FAF0),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar ──────────────────────────────────────────
            Stack(
              children: [
                RepaintBoundary(
                  child: ChatAvatar(
                    chat: chat,
                    radius: 28,
                    fileExistsCache: fileExistsCache,
                    miniThumbnailCache: miniThumbnailCache,
                  ),
                ),
                if (isPinned)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BFA5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.push_pin,
                          size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 13),

            // ── Conteúdo ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nome + horário
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF111111),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? const Color(0xFF00BFA5)
                              : const Color(0xFFAAAAAA),
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Prévia + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _getMessagePreview(lastMessage),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: unreadCount > 0
                                ? const Color(0xFF555555)
                                : const Color(0xFF999999),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 999
                                ? '999+'
                                : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessagePreview(Map<String, dynamic>? lastMessage) {
    if (lastMessage == null) return '';
    final content = lastMessage['content'] as Map<String, dynamic>?;
    if (content == null) return '';
    switch (content['@type'] as String?) {
      case 'MessageText':
        return content['text']?['text'] as String? ?? '';
      case 'MessagePhoto':
        return '📷 Photo';
      case 'MessageVideo':
        return '🎥 Video';
      case 'MessageVoiceNote':
        return '🎤 Voice message';
      case 'MessageDocument':
        return '📎 Document';
      case 'MessageSticker':
        return '🎨 Sticker';
      case 'MessageAnimation':
        return '🎬 GIF';
      default:
        return 'Message';
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays < 7) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[date.weekday % 7];
    } else if (date.year == now.year) {
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month]}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year % 100}';
    }
  }
}
