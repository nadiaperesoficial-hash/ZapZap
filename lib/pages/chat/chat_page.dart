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

const _kChatBg = Color(0xFFBDC9D7);
const _kAppBar = Color(0xFF3D4D6A);

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
  final ValueNotifier<Duration> _recordDuration = ValueNotifier(Duration.zero);
  final _record = AudioRecorder();
  Timer? _recordTimer;
  bool _cancelled = false;
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
            _messages.value = AlbumsGrouper.groupMediaAlbums(
                [message, ..._messages.value]);
            setState(() {});
          }
        case updateDeleteMessagesConst:
          final chatId = update['chatId'];
          final messageIds = update['messageIds'];
          if (chatId == widget.chat['id']) {
            if (!mounted) return;
            _messages.value = _messages.value
                .where((m) => !messageIds.contains(m['id']))
                .toList();
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
        final fromId =
            _messages.value.isEmpty ? 0 : _messages.value.last['id'];
        final localMessages = await TDLibClient.getChatHistory(
          chatId: widget.chat['id']!,
          fromMessageId: fromId,
          offset: 0,
          limit: _batchSize * 2,
          onlyLocal: true,
        );
        if (!mounted) return;
        if (localMessages != null && localMessages.messages.isNotEmpty) {
          _messages.value = AlbumsGrouper.groupMediaAlbums(
              [..._messages.value, ...localMessages.messages]);
          setState(() {});
        } else {
          break;
        }
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
      chatId: widget.chat['id']!,
      fromMessageId: fromId,
      offset: 0,
      limit: _batchSize * 2,
      onlyLocal: false,
    );
    if (messages == null || messages.messages.isEmpty) {
      _hasMore.value = false;
      _isLoading.value = false;
      return;
    }
    final pos = _scrollController.position;
    final firstVisibleIndex =
        (_messages.value.isNotEmpty && pos.maxScrollExtent > 0)
            ? (pos.pixels /
                    (pos.maxScrollExtent / _messages.value.length))
                .round()
                .clamp(0, _messages.value.length - 1)
            : 0;
    _messages.value = AlbumsGrouper.groupMediaAlbums(
        [..._messages.value, ...messages.messages]);
    await Future.delayed(Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemHeight =
            _scrollController.position.maxScrollExtent / _messages.value.length;
        final targetPosition = firstVisibleIndex * itemHeight;
        _scrollController.jumpTo(targetPosition.clamp(
            0.0, _scrollController.position.maxScrollExtent));
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
        _cancelled = false;
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.ogg';
        await _record.start(
          const RecordConfig(encoder: AudioEncoder.opus, bitRate: 96000),
          path: path,
        );
        _isRecording.value = true;
        _recordDuration.value = Duration.zero;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _recordDuration.value += const Duration(seconds: 1);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de microfone negada')),
          );
        }
      }
    } catch (e) {
      logger.e('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording.value) return;
    try {
      _recordTimer?.cancel();
      final path = await _record.stop();
      _isRecording.value = false;
      _recordDuration.value = Duration.zero;
      if (path != null && !_cancelled) {
        await TDLibClient.sendVoiceNote(
            chatId: widget.chat['id'], path: path);
      }
    } catch (e) {
      logger.e('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar áudio: $e')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _cancelled = true;
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

  // ── Barra de gravação ──────────────────────────────────────────────────
  Widget _buildRecordingBar() {
    return Listener(
      onPointerUp: (_) => _stopRecording(),
      child: Container(
        height: 60,
        color: _kAppBar,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (_, value, __) => Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<Duration>(
            valueListenable: _recordDuration,
            builder: (_, duration, __) => Text(
              _formatDuration(duration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _cancelRecording,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chevron_left, color: Colors.white60, size: 20),
                const Text('Deslize para cancelar',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      letterSpacing: 0,
                    )),
              ]),
            ),
          ),
          const Icon(Icons.mic, color: Colors.white, size: 26),
        ]),
      ),
    );
  }

  // ── Input estilo foto 2 — campo largo arredondado ──────────────────────
  Widget _buildNormalInput() {
    return Container(
      color: _kAppBar,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Emoji
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined,
                color: Colors.white70, size: 24),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Campo de texto largo
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E55),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      height: 1.3,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Mensagem',
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                // Anexo
                GestureDetector(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.attach_file,
                        color: Colors.white54, size: 22),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(width: 8),

          // Botão enviar / microfone
          ValueListenableBuilder<String>(
            valueListenable: _messageText,
            builder: (_, text, __) {
              if (text.isNotEmpty) {
                return GestureDetector(
                  onTap: () async {
                    final msg = _messageController.text.trim();
                    if (msg.isEmpty) return;
                    _messageController.clear();
                    await TDLibClient.sendMessage(
                        chatId: widget.chat['id'], text: msg);
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BFA5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                );
              }
              return Listener(
                onPointerDown: (_) => _startRecording(),
                onPointerUp: (_) => _stopRecording(),
                child: Container(
                  width: 42, height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_none,
                      color: Colors.white70, size: 26),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildMessageInput() {
    final canSend =
        widget.chat['permissions']?['canSendBasicMessages'] ?? true;
    if (!canSend) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: _isRecording,
      builder: (_, recording, __) =>
          recording ? _buildRecordingBar() : _buildNormalInput(),
    );
  }

  // ── Last seen ──────────────────────────────────────────────────────────
  Widget _buildSubtitle() {
    if (widget.chat['user'] != null) {
      final statusText =
          MessageFormatter.getUserStatus(widget.chat['user']!);
      final isOnline =
          widget.chat['user']?['status']?['@type'] == 'userStatusOnline';
      return Text(
        statusText,
        style: TextStyle(
          fontSize: 13,
          color: isOnline ? const Color(0xFF80CBC4) : Colors.white60,
          fontWeight: FontWeight.normal,
          letterSpacing: 0,
        ),
      );
    }
    if (widget.chat['supergroup'] != null) {
      final count = widget.chat['supergroup']['memberCount'] ?? 0;
      return Text(
        '${NumberFormat('#,###', 'en_US').format(count)} membros',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white60,
          letterSpacing: 0,
        ),
      );
    }
    return const SizedBox.shrink();
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
          backgroundColor: _kAppBar,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: InkWell(
            onTap: () {},
            child: Row(children: [
              ChatAvatar(chat: widget.chat, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat['title'] ?? 'Chat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildSubtitle(),
                  ],
                ),
              ),
            ]),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.call, color: Colors.white),
                onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {}),
          ],
        ),
        body: Container(
          color: _kChatBg,
          child: Column(children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _messages,
                builder: (_, messages, __) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isLoading,
                    builder: (_, isLoading, __) {
                      if (messages.isEmpty && !isLoading) {
                        return const Center(
                          child: Text('Nenhuma mensagem ainda',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                letterSpacing: 0,
                              )),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length + (isLoading ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (isLoading && index == messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text('Carregando mensagens...',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      letterSpacing: 0,
                                    )),
                              ),
                            );
                          }
                          if (messages.isEmpty) return const SizedBox.shrink();
                          final message = messages[index];
                          if (index >= messages.length - 50 &&
                              !isLoading && _hasMore.value) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => _loadBatch());
                          }
                          if (message['isAlbum'] == true) {
                            return AlbumBubble(
                                albumMessages: message['messages'],
                                chat: widget.chat);
                          }
                          return MessageBubble(
                              message: message, chat: widget.chat);
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
      ),
    );
  }
}
