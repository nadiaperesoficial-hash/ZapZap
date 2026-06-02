import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF00BFA5);

class ZapStoryPage extends StatefulWidget {
  const ZapStoryPage({super.key});

  @override
  State<ZapStoryPage> createState() => _ZapStoryPageState();
}

class _ZapStoryPageState extends State<ZapStoryPage> {
  final List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    _loadStories();
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
      final contacts = await TDLibClient.getContacts();
      final stories = <Map<String, dynamic>>[];

      for (final contact in contacts ?? []) {
        try {
          final s = await TDLibClient.sendRaw({
            '@type': 'getChatActiveStories',
            'chatId': contact['id'],
          });
          if (s != null && (s['stories'] as List?)?.isNotEmpty == true) {
            for (final story in s['stories'] as List) {
              stories.add({'story': story, 'user': contact});
              await _downloadStoryMedia(story as Map<String, dynamic>);
            }
          }
        } catch (_) {}
      }

      try {
        final myId = _me?['id'];
        if (myId != null) {
          final myStories = await TDLibClient.sendRaw({
            '@type': 'getChatActiveStories',
            'chatId': myId,
          });
          if (myStories != null &&
              (myStories['stories'] as List?)?.isNotEmpty == true) {
            for (final story in myStories['stories'] as List) {
              stories.insert(0, {'story': story, 'user': _me});
              await _downloadStoryMedia(story as Map<String, dynamic>);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
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
          const SnackBar(content: Text('Story postado!'), backgroundColor: _kGreen),
        );
        setState(() {
          _isLoading = true;
          _stories.clear();
        });
        _loadStories();
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
        backgroundColor: const Color(0xFF3DAF5C),
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111111),
                        letterSpacing: 0,
                      ),
                    ),
                    TextSpan(
                      text: 'Story',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                        letterSpacing: 0,
                      ),
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
                          setState(() {
                            _isLoading = true;
                            _stories.clear();
                          });
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
                letterSpacing: 0,
              )),
          const SizedBox(height: 8),
          const Text(
            'Seus contatos não postaram stories ainda.\nToque no + para postar o seu!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
              letterSpacing: 0,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final user = data['user'] as Map<String, dynamic>?;
    final story = data['story'] as Map<String, dynamic>?;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final date = story?['date'] as int? ?? 0;
    final content = story?['content'] as Map<String, dynamic>?;
    final timeStr = _formatDate(date);

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
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                        letterSpacing: 0,
                      )),
                  Text(timeStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8D8D93),
                        letterSpacing: 0,
                      )),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: Color(0xFFAAAAAA), size: 22),
          ]),
          const SizedBox(height: 12),
          _buildMedia(content),
          const SizedBox(height: 12),
          if (_getCaption(content).isNotEmpty)
            Text(_getCaption(content),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111111),
                  letterSpacing: 0,
                  height: 1.4,
                )),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.favorite_border_rounded,
                color: Color(0xFFE53935), size: 22),
            const SizedBox(width: 16),
            const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF888888), size: 22),
          ]),
        ],
      ),
    );
  }

  Widget _buildMedia(Map<String, dynamic>? content) {
    if (content == null) return _mediaPlaceholder();
    final type = content['@type'] as String?;

    if (type == 'storyContentPhoto') {
      final photo = content['photo'] as Map<String, dynamic>?;
      final sizes = photo?['sizes'] as List?;
      String? path;
      if (sizes != null && sizes.isNotEmpty) {
        // Tenta o maior tamanho disponível
        for (int i = sizes.length - 1; i >= 0; i--) {
          final p = sizes[i]['photo']?['local']?['path'] as String?;
          if (p != null && p.isNotEmpty) {
            path = p;
            break;
          }
        }
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
      // Arquivo ainda baixando — mostra placeholder com indicador
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3DAF5C)),
        ),
      );
    }

    if (type == 'storyContentVideo') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _mediaPlaceholder(),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 32),
            ),
          ],
        ),
      );
    }

    return _mediaPlaceholder();
  }

  Widget _mediaPlaceholder() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFCCCCCC)),
      ),
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
