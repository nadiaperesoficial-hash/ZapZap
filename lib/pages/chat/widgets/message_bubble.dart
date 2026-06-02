import 'package:flutter/material.dart';
import 'message_audio.dart';
import 'message_photo.dart';
import 'message_text.dart';
import 'message_video.dart';
import 'message_voice_note.dart';
import 'interaction_info.dart';

// Balões estilo LINE
const _kBubbleOut = Color(0xFFAAE063);  // verde LINE
const _kBubbleIn  = Colors.white;        // branco LINE

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Map<String, dynamic> chat;

  const MessageBubble({super.key, required this.message, required this.chat});

  Widget _buildMediaContent(Map<String, dynamic> content, int messageId) {
    final contentType = content['@type'];
    switch (contentType) {
      case 'MessagePhoto':
        return MessagePhoto(content: content, messageId: messageId);
      case 'MessageVideo':
        return MessageVideo(content: content);
      case 'MessageAudio':
        return MessageAudio(content: content);
      case 'MessageVoiceNote':
        return MessageVoiceNote(content: content, messageId: messageId);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message['isOutgoing'] ?? false;
    final content = message['content'];
    final contentType = content['@type'];
    final hasCaption = content['caption']?['text'] != null &&
        content['caption']['text'].toString().isNotEmpty;

    final hasMedia = contentType == 'MessagePhoto' ||
        contentType == 'MessageVideo' ||
        contentType == 'MessageAudio' ||
        contentType == 'MessageVoiceNote';

    final isSupergroupChat = chat['supergroup'] != null;
    String? senderName;
    if (isSupergroupChat && !isOutgoing) {
      senderName = chat['title'];
    }

    final bubbleColor = isOutgoing ? _kBubbleOut : _kBubbleIn;

    // Bordas arredondadas estilo LINE — canto inferior pontudo no lado do remetente
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
      bottomRight: Radius.circular(isOutgoing ? 4 : 18),
    );

    // Margens com espaço das bordas para evitar toques acidentais
    final margin = EdgeInsets.only(
      left: isOutgoing ? 64 : 14,
      right: isOutgoing ? 14 : 64,
      top: 3,
      bottom: 3,
    );

    if (hasMedia && !hasCaption) {
      return Align(
        alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: margin,
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          child: Column(
            crossAxisAlignment:
                isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (senderName != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(senderName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF00BFA5),
                              letterSpacing: 0,
                            )),
                      ),
                    contentType == 'MessageVoiceNote'
                        ? _buildMediaContent(content, message['id'])
                        : ClipRRect(
                            borderRadius: borderRadius,
                            child:
                                _buildMediaContent(content, message['id']),
                          ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 8, right: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InteractionInfo(
                      message: message, isOutgoing: isOutgoing),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin,
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMedia)
              Container(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (senderName != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(senderName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF00BFA5),
                              letterSpacing: 0,
                            )),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                      ),
                      child: _buildMediaContent(content, message['id']),
                    ),
                    Container(
                      constraints:
                          const BoxConstraints(minWidth: double.infinity),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MessageText(content: content['caption']),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InteractionInfo(
                                message: message, isOutgoing: isOutgoing),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (senderName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(senderName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00BFA5),
                                letterSpacing: 0,
                              )),
                        ),
                      if (contentType == 'MessageText')
                        MessageText(content: content['text']),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InteractionInfo(
                            message: message, isOutgoing: isOutgoing),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
