import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nullgram/pages/chat/utils/albums_grouper.dart';
import 'package:nullgram/pages/chat/utils/message_formatter.dart';
import 'package:nullgram/pages/chat/widgets/album_bubble.dart';
import 'package:nullgram/pages/chat/widgets/chat_avatar.dart';
import 'package:nullgram/pages/chat/widgets/message_bubble.dart';
import 'package:nullgram/tdlib/constants.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> chat;
  const ChatPage({super.key, required this.chat});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isRecording = ValueNotifier<bool>(false);
  final ValueNotifier<String> _messageText = ValueNotifier('');
  final ValueNotifier<List<Map<String, dynamic>>> _messages = ValueNotifier([]);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _hasMore = ValueNotifier(true);
  final _record = AudioRecorder();
  final ValueNotifier<Duration> _recordDuration = ValueNotifier(Duration.zero);
  Timer? _recordTimer;
  static const int _batchSize = 50;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      _messageText.value = _messageController.text;
    });

    TDLibClient.messsagesUpdates.listen((update) async {
      final type = update['@type'];
      switch (type) {
        case updateNewMessageConst:
          final message = update['message'];
          if (message['chatId'] == widget.chat['id']) {
            if (!mounted) return;
            _messages.value = AlbumsGrouper.groupMediaAlbums([message, ..._messages.value]);
            setState(() {});
          }
        case updateDeleteMessagesConst:
          final chatId = update['chatId'];
          final messageIds = update['messageIds'];
          if (chatId == widget.chat['id']) {
            if (!mounted) return;
            _messages.value = _messages.value.where((m) => !messageIds.contains(m['id'])).toList();
            setState(() {});
          }
          break;
      }
    });

    _loadLocalMessages();
  }

  Future<void> _loadLocalMessages() async {
    try {
      while (true) {
        if (!mounted) return;
        _isLoading.value = true;
        final fromId = _messages.value.isEmpty ? 0 : _messages.value.last['id'];
        final localMessages = await TDLibClient.getChatHistory(
          chatId: widget.chat['id']!, fromMessageId: fromId, offset: 0, limit: _batchSize * 2, onlyLocal: true,
        );
        if (!mounted) return;
        if (localMessages != null && localMessages.messages.isNotEmpty) {
          _messages.value = AlbumsGrouper.groupMediaAlbums([..._messages.value, ...localMessages.messages]);
          setState(() {});
        } else break;
      }
    } catch (e) {
      logger.e('Error loading initial messages: $e');
    }
    if (!mounted) return;
    _isLoading.value = false;
  }

  Future<void> _loadBatch() async {
    if (_isLoading.value || !_hasMore.value) return;
    _isLoading.value = true;
    final fromId = _messages.value.isEmpty ? 0 : _messages.value.last['id'];
    final messages = await TDLibClient.getChatHistory(
      chatId: widget.chat['id']!, fromMessageId: fromId, offset: 0, limit: _batchSize * 2, onlyLocal: false,
    );
    if (messages == null || messages.messages.isEmpty) {
      _hasMore.value = false;
      _isLoading.value = false;
      return;
    }
    final pos = _scrollController.position;
    final firstVisibleIndex = (_messages.value.isNotEmpty && pos.maxScrollExtent > 0)
        ? (pos.pixels / (pos.maxScrollExtent / _messages.value.length)).round().clamp(0, _messages.value.length - 1)
        : 0;
    _messages.value = AlbumsGrouper.groupMediaAlbums([..._messages.value, ...messages.messages]);
    await Future.delayed(Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemHeight = _scrollController.position.maxScrollExtent / _messages.value.length;
        final targetPosition = firstVisibleIndex * itemHeight;
        _scrollController.jumpTo(targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
      _isLoading.value = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _isRecording.dispose();
    _messageText.dispose();
    _messages.dispose();
    _isLoading.dispose();
    _hasMore.dispose();
    _recordDuration.dispose();
    _recordTimer?.cancel();
    _record.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.ogg';
        await _record.start(
          const RecordConfig(encoder: AudioEncoder.opus, bitRate: 96000),
          path: path,
        );
        _isRecording.value = true;
        _recordDuration.value = Duration.zero;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _recordDuration.value = _recordDuration.value + const Duration(seconds: 1);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      logger.e('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _record.stop();
      _isRecording.value = false;
      _recordDuration.value = Duration.zero;
      if (path != null) {
        await TDLibClient.sendVoiceNote(chatId: widget.chat['id'], path: path);
      }
    } catch (e) {
      logger.e('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending audio: $e')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _record.stop();
    _isRecording.value = false;
    _recordDuration.value = Duration.zero;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildMessageInput() {
    final canSendBasicMessages = widget.chat['permissions']?['canSendBasicMessages'] ?? true;
    if (!canSendBasicMessages) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: _isRecording,
      builder: (context, isRecording, child) {
        if (isRecording) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
            ),
            child: Row(children: [
              const SizedBox(width: 8),
              const Icon(Icons.mic, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              ValueListenableBuilder<Duration>(
                valueListenable: _recordDuration,
                builder: (context, duration, _) => Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _cancelRecording,
                  child: Row(children: [
                    const Icon(Icons.chevron_left, color: Colors.grey),
                    Text('Deslize para cancelar', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ]),
                ),
              ),
              GestureDetector(
                onLongPressEnd: (_) => _stopRecording(),
                onLongPressCancel: () => _cancelRecording(),
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.mic, color: Colors.white)),
                ),
              ),
            ]),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
          ),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.emoji_emotions_outlined), onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.attach_file, size: 22)),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<String>(
              valueListenable: _messageText,
              builder: (context, text, child) {
                if (text.isNotEmpty) {
                  return GestureDetector(
                    onTap: () async {
                      final msg = _messageController.text.trim();
                      if (msg.isEmpty) return;
                      _messageController.clear();
                      await TDLibClient.sendMessage(chatId: widget.chat['id'], text: msg);
                    },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.send, color: Colors.white)),
                    ),
                  );
                }
                return GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  onLongPressCancel: () => _cancelRecording(),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.mic_none, color: Colors.white)),
                  ),
                );
              },
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300.0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: InkWell(
            onTap: () {},
            child: Row(children: [
              ChatAvatar(chat: widget.chat, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.chat['title'] ?? 'Chat',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (widget.chat['user'] != null)
                    Text(MessageFormatter.getUserStatus(widget.chat['user']!),
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  if (widget.chat['supergroup'] != null)
                    Text("${NumberFormat('#,###', 'en_US').format(widget.chat['supergroup']['memberCount'] ?? 0)} subscribers",
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ]),
              ),
            ]),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _messages,
              builder: (context, messages, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (context, isLoading, child) {
                    if (messages.isEmpty && !isLoading) {
                      return const Center(child: Text('No messages yet'));
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isLoading && index == messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('Loading older messages', style: TextStyle(color: Colors.grey))),
                          );
                        }
                        if (messages.isEmpty) return const SizedBox.shrink();
                        final message = messages[index];
                        if (index >= messages.length - 50 && !isLoading && _hasMore.value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => _loadBatch());
                        }
                        if (message['isAlbum'] == true) {
                          return AlbumBubble(albumMessages: message['messages'], chat: widget.chat);
                        }
                        return MessageBubble(message: message, chat: widget.chat);
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ]),
      ),
    );
  }
}
