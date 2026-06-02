import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF00BFA5);
const _kLineGreen = Color(0xFFAAE063);

class ZapStoryPage extends StatefulWidget {
  const ZapStoryPage({super.key});

  @override
  State<ZapStoryPage> createState() => _ZapStoryPageState();
}

class _ZapStoryPageState extends State<ZapStoryPage> {
  final List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  Map<String, dynamic>? _me;
  StreamSubscription? _filesSub;

  @override
  void initState() {
    super.initState();
    _loadStories();
    // Escuta downloads concluídos e força rebuild
    _filesSub = TDLibClient.filesUpdates.listen((update) {
      if (update['@type'] == 'UpdateFile') {
        final isDownloadingCompleted =
            update['file']?['local']?['isDownloadingCompleted'] as bool? ?? false;
        if (isDownloadingCompleted && mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _filesSub?.cancel();
    super.dispose();
  }

  Future<void> _downloadStoryMedia(Map<String, dynamic> story) async {
    try {
      final content = story['content'] as Map<String, dynamic>?;
      if (content == null) return;
      final type = content['@type'] as String?;
      if (type == 'storyContentPhoto') {
        final sizes = content['photo']?['sizes'] as List?;
        if (sizes != null && sizes.isNotEmpty) {
          final fileId = sizes.last['photo']?['id'] as int?;
          if (fileId != null) {
            await TDLibClient.downloadFile(fileId: fileId);
          }
        }
      } else if (type == 'storyContentVideo') {
        final fileId = content['video']?['video']?['id'] as int?;
        if (fileId != null) {
          await TDLibClient.downloadFile(fileId: fileId);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStories() async {
    try {
      _me = await TDLibClient.getMe();
      final stories = <Map<String, dynamic>>[];

      try {
        final myId = _me?['id'];
        if (myId != null) {
          final myStories = await TDLibClient.sendRaw({
            '@type': 'getChatActiveStories',
            'chatId': myId,
          });
          if (myStories != null) {
            final list = myStories['stories'] as List? ?? [];
            for (final story in list) {
              final s = story as Map<String, dynamic>;
              stories.add({'story': s, 'user': _me});
              _downloadStoryMedia(s); // não await — download em background
            }
          }
        }
      } catch (e) {
        logger.e('Erro stories próprios: $e');
      }

      final contacts = await TDLibClient.getContacts();
      for (final contact in contacts ?? []) {
        try {
          final userId = contact['id'] as int?;
          if (userId == null) continue;
          final s = await TDLibClient.sendRaw({
            '@type': 'getChatActiveStories',
            'chatId': userId,
          });
          if (s != null) {
            final list = s['stories'] as List? ?? [];
            for (final story in list) {
              final st = story as Map<String, dynamic>;
              stories.add({'story': st, 'user': contact});
              _downloadStoryMedia(st); // não await — download em background
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _stories.clear();
          _stories.addAll(stories);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postStory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Postar Story',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0)),
        content: const Text(
          'Contas gratuitas podem postar até 3 stories por dia.\nOs stories ficam ativos por 24 horas.',
          style: TextStyle(fontSize: 14, color: Color(0xFF888888), letterSpacing: 0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar',
                style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    try {
      await TDLibClient.sendRaw({
        '@type': 'sendStory',
        'chatId': _me?['id'],
        'content': {
          '@type': 'inputStoryContentPhoto',
          'photo': {'@type': 'inputFileLocal', 'path': picked.path},
          'addedStickerFileIds': [],
        },
        'privacySettings': {'@type': 'storyPrivacySettingsContacts'},
        'activePeriod': 86400,
        'isPostedToPremiumSubscribers': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Story postado! Aguarde aparecer...'),
              backgroundColor: _kGreen),
        );
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() { _isLoading = true; _stories.clear(); });
          _loadStories();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _postStory,
        backgroundColor: _kLineGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Zap',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400,
                          color: Color(0xFF111111), letterSpacing: 0),
                    ),
                    TextSpan(
                      text: 'Story',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                          color: Color(0xFF111111), letterSpacing: 0),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF111111), size: 26),
                onPressed: _postStory,
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : _stories.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: _kGreen,
                        onRefresh: () async {
                          setState(() { _isLoading = true; _stories.clear(); });
                          await _loadStories();
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _stories.length,
                          separatorBuilder: (_, __) =>
                              Container(height: 8, color: const Color(0xFFF5F5F5)),
                          itemBuilder: (_, i) => _StoryCard(data: _stories[i]),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Nenhum story por aqui',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: Color(0xFF888888), letterSpacing: 0)),
          const SizedBox(height: 8),
          const Text(
            'Seus contatos não postaram stories ainda.\nToque no + para postar o seu!',
            style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA),
                letterSpacing: 0, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── StoryCard como StatefulWidget para reagir ao download ──────────────────
class _StoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _StoryCard({required this.data});

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  StreamSubscription? _fileSub;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _fileSub = TDLibClient.filesUpdates.listen((update) {
      if (update['@type'] == 'UpdateFile') {
        final completed =
            update['file']?['local']?['isDownloadingCompleted'] as bool? ?? false;
        if (completed && mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _fileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.data['user'] as Map<String, dynamic>?;
    final story = widget.data['story'] as Map<String, dynamic>?;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final date = story?['date'] as int? ?? 0;
    final content = story?['content'] as Map<String, dynamic>?;

    final colors = [
      const Color(0xFF5C6BC0), const Color(0xFF26A69A),
      const Color(0xFFEF5350), const Color(0xFFAB47BC),
      const Color(0xFF42A5F5), const Color(0xFFFF7043),
    ];
    final color = name.isNotEmpty
        ? colors[name.codeUnitAt(0) % colors.length]
        : colors[0];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: Color(0xFF111111),
                      letterSpacing: 0)),
                  Text(_formatDate(date), style: const TextStyle(fontSize: 13,
                      color: Color(0xFF8D8D93), letterSpacing: 0)),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: Color(0xFFAAAAAA), size: 22),
          ]),

          const SizedBox(height: 12),

          // Mídia
          _buildMedia(content),

          const SizedBox(height: 12),

          // Caption
          if (_getCaption(content).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_getCaption(content),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111111),
                      letterSpacing: 0, height: 1.4)),
            ),

          // Reações
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _liked = !_liked),
              child: Icon(
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: const Color(0xFFE53935),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showCommentSheet(context, story, user),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF888888), size: 24),
            ),
          ]),
        ],
      ),
    );
  }

  void _showCommentSheet(BuildContext context,
      Map<String, dynamic>? story, Map<String, dynamic>? user) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Responder para ${user?['firstName'] ?? ''}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  letterSpacing: 0)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma resposta...',
                    hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final msg = ctrl.text.trim();
                if (msg.isEmpty) return;
                Navigator.pop(context);
                // Envia mensagem direta ao usuário
                final userId = user?['id'] as int?;
                if (userId != null) {
                  await TDLibClient.sendMessage(chatId: userId, text: msg);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resposta enviada!'),
                        backgroundColor: Color(0xFF00BFA5)));
                }
              },
              child: Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(
                    color: Color(0xFF00BFA5), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMedia(Map<String, dynamic>? content) {
    if (content == null) return _mediaPlaceholder();
    final type = content['@type'] as String?;

    if (type == 'storyContentPhoto') {
      final sizes = (content['photo']?['sizes'] as List?) ?? [];
      String? path;
      for (int i = sizes.length - 1; i >= 0; i--) {
        final p = sizes[i]['photo']?['local']?['path'] as String?;
        if (p != null && p.isNotEmpty) { path = p; break; }
      }
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file,
                width: double.infinity, height: 280, fit: BoxFit.cover),
          );
        }
      }
      return Container(
        height: 280,
        decoration: BoxDecoration(color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12)),
        child: const Center(
            child: CircularProgressIndicator(color: _kLineGreen)),
      );
    }

    if (type == 'storyContentVideo') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(alignment: Alignment.center, children: [
          _mediaPlaceholder(),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 32),
          ),
        ]),
      );
    }

    return _mediaPlaceholder();
  }

  Widget _mediaPlaceholder() {
    return Container(
      height: 280,
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12)),
      child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFCCCCCC))),
    );
  }

  String _getCaption(Map<String, dynamic>? content) {
    if (content == null) return '';
    return content['caption']?['text'] as String? ?? '';
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
