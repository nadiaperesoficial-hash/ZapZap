import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'message_audio.dart';
import 'message_photo.dart';
import 'message_text.dart';
import 'message_video.dart';
import 'message_voice_note.dart';
import 'interaction_info.dart';

const _kBubbleOut = Color(0xFFAAE063);
const _kBubbleIn  = Colors.white;

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Map<String, dynamic> chat;

  const MessageBubble({super.key, required this.message, required this.chat});

  bool _isVideoNote(Map<String, dynamic> message) {
    final content = message['content'];
    if (content?['@type'] != 'MessageText') return false;
    final text = content?['text']?['text'] as String? ?? '';
    return text.startsWith('🎥 [video_note:') && text.endsWith(']');
  }

  String _extractVideoNoteId(Map<String, dynamic> message) {
    final text = message['content']?['text']?['text'] as String? ?? '';
    return text.replaceFirst('🎥 [video_note:', '').replaceFirst(']', '');
  }

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

    // Vídeo circular customizado
    if (_isVideoNote(message)) {
      final noteId = _extractVideoNoteId(message);
      return _VideoNoteBubble(
        noteId: noteId,
        isOutgoing: isOutgoing,
        message: message,
      );
    }

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
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
      bottomRight: Radius.circular(isOutgoing ? 4 : 18),
    );
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
                            child: _buildMediaContent(content, message['id']),
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
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
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

// ── Player circular de vídeo note ────────────────────────────────────────────
class _VideoNoteBubble extends StatefulWidget {
  final String noteId;
  final bool isOutgoing;
  final Map<String, dynamic> message;

  const _VideoNoteBubble({
    required this.noteId,
    required this.isOutgoing,
    required this.message,
  });

  @override
  State<_VideoNoteBubble> createState() => _VideoNoteBubbleState();
}

class _VideoNoteBubbleState extends State<_VideoNoteBubble> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _watched = false;
  bool _expired = false;
  String? _mediaUrl;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final record = await Supabase.instance.client
          .from('video_notes')
          .select()
          .eq('id', widget.noteId)
          .maybeSingle();

      if (record == null) {
        setState(() => _expired = true);
        return;
      }

      final expiresAt = DateTime.parse(record['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        setState(() => _expired = true);
        return;
      }

      setState(() {
        _mediaUrl = record['media_url'] as String?;
        _watched = record['watched'] as bool? ?? false;
      });
    } catch (_) {}
  }

  Future<void> _play() async {
    if (_mediaUrl == null || _loading) return;
    setState(() => _loading = true);

    _controller = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl!));
    await _controller!.initialize();
    await _controller!.play();

    // Marca como assistido
    await Supabase.instance.client
        .from('video_notes')
        .update({'watched': true}).eq('id', widget.noteId);

    _controller!.addListener(() {
      if (_controller!.value.position >= _controller!.value.duration) {
        // Some após assistir
        Supabase.instance.client
            .from('video_notes')
            .delete()
            .eq('id', widget.noteId);
        if (mounted) setState(() => _expired = true);
      }
    });

    setState(() {
      _loading = false;
      _watched = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final margin = EdgeInsets.only(
      left: widget.isOutgoing ? 64 : 14,
      right: widget.isOutgoing ? 14 : 64,
      top: 3,
      bottom: 3,
    );

    return Align(
      alignment: widget.isOutgoing
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: margin,
        child: Column(
          crossAxisAlignment: widget.isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _expired ? null : _play,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: widget.isOutgoing
                        ? const Color(0xFFAAE063)
                        : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _expired
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off,
                                  color: Colors.white54, size: 32),
                              SizedBox(height: 6),
                              Text('Expirado',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    letterSpacing: 0,
                                  )),
                            ],
                          ),
                        )
                      : _controller != null &&
                              _controller!.value.isInitialized
                          ? VideoPlayer(_controller!)
                          : _loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFFAAE063)))
                              : Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_circle_fill,
                                        color: widget.isOutgoing
                                            ? const Color(0xFFAAE063)
                                            : const Color(0xFF00BFA5),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '🎥 Vídeo circular\nSome após assistir',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          letterSpacing: 0,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InteractionInfo(
                  message: widget.message, isOutgoing: widget.isOutgoing),
            ),
          ],
        ),
      ),
    );
  }
}
