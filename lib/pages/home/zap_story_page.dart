import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF00BFA5);
const _kLineGreen = Color(0xFFAAE063);
const _cloudName = 'dkehyceuc';
const _maxVideoSeconds = 60;
const _maxPhotoBytes = 5 * 1024 * 1024;
const _maxCaptionLength = 280;

class ZapStoryPage extends StatefulWidget {
  const ZapStoryPage({super.key});

  @override
  State<ZapStoryPage> createState() => _ZapStoryPageState();
}

class _ZapStoryPageState extends State<ZapStoryPage> {
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  Map<String, dynamic>? _me;
  StreamSubscription? _storySub;
  StreamSubscription? _fileSub;

  @override
  void initState() {
    super.initState();
    _storySub = TDLibClient.storyUpdates.listen((_) {
      if (mounted) setState(() {});
    });
    _fileSub = TDLibClient.filesUpdates.listen((update) {
      if (update['@type'] == 'UpdateFile') {
        final completed =
            update['file']?['local']?['isDownloadingCompleted'] as bool? ?? false;
        if (completed && mounted) setState(() {});
      }
    });
    _loadStories();
  }

  @override
  void dispose() {
    _storySub?.cancel();
    _fileSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      _me = await TDLibClient.getMe();

      await Supabase.instance.client
          .from('stories')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());

      final response = await Supabase.instance.client
          .from('stories')
          .select()
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _stories = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Erro ao carregar stories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadToCloudinary(String filePath, bool isVideo) async {
    try {
      final resourceType = isVideo ? 'video' : 'image';
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'zapstory'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      if (response.statusCode == 200) return json['secure_url'] as String?;
      logger.e('Cloudinary error: $body');
      return null;
    } catch (e) {
      logger.e('Upload error: $e');
      return null;
    }
  }

  Future<void> _postStory() async {
    // Seletor de privacidade
    final privacy = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quem pode ver?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                letterSpacing: 0, color: Color(0xFF111111))),
        content: const Text(
          'Os stories somem automaticamente em 24 horas.',
          style: TextStyle(fontSize: 14, color: Color(0xFF8D8D93), letterSpacing: 0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'everyone'),
            child: const Text('🌍 Todos',
                style: TextStyle(color: _kLineGreen, fontWeight: FontWeight.w600,
                    fontSize: 15, letterSpacing: 0)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'contacts'),
            child: const Text('👥 Contatos',
                style: TextStyle(color: _kLineGreen, fontWeight: FontWeight.w600,
                    fontSize: 15, letterSpacing: 0)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8D8D93), fontSize: 14,
                    letterSpacing: 0)),
          ),
        ],
      ),
    );
    if (privacy == null) return;

    // Seletor de mídia
    final mediaType = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tipo de mídia',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                letterSpacing: 0, color: Color(0xFF111111))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'photo'),
            child: const Text('📷 Foto',
                style: TextStyle(color: _kLineGreen, fontWeight: FontWeight.w600,
                    fontSize: 15, letterSpacing: 0)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'video'),
            child: const Text('🎥 Vídeo (máx. 60s)',
                style: TextStyle(color: _kLineGreen, fontWeight: FontWeight.w600,
                    fontSize: 15, letterSpacing: 0)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8D8D93), fontSize: 14,
                    letterSpacing: 0)),
          ),
        ],
      ),
    );
    if (mediaType == null) return;

    final picker = ImagePicker();
    XFile? picked;
    if (mediaType == 'photo') {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } else {
      picked = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: _maxVideoSeconds));
    }
    if (picked == null) return;

    if (mediaType == 'photo') {
      final size = await File(picked.path).length();
      if (size > _maxPhotoBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto muito grande! Máximo 5MB.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    // Caption opcional
    String caption = '';
    if (mounted) {
      final captionResult = await showDialog<String>(
        context: context,
        builder: (_) {
          final ctrl = TextEditingController();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Adicionar texto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  maxLength: _maxCaptionLength,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escreva algo... (opcional)',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kGreen),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('Pular', style: TextStyle(color: Color(0xFF888888))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                child: const Text('Adicionar',
                    style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );
      caption = captionResult ?? '';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviando story...'),
            backgroundColor: _kGreen, duration: Duration(seconds: 10)),
      );
    }

    try {
      final isVideo = mediaType == 'video';
      final mediaUrl = await _uploadToCloudinary(picked.path, isVideo);

      if (mediaUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao enviar mídia. Tente novamente.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      final myId = _me?['id']?.toString() ?? '';
      final firstName = _me?['firstName'] as String? ?? '';
      final lastName = _me?['lastName'] as String? ?? '';
      final userName = '$firstName $lastName'.trim();

      await Supabase.instance.client.from('stories').insert({
        'user_id': myId,
        'user_name': userName,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'caption': caption,
        'privacy': privacy,
        'likes': [],
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story postado!'), backgroundColor: _kGreen),
        );
        _loadStories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
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
                text: const TextSpan(children: [
                  TextSpan(text: 'Zap',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400,
                          color: Color(0xFF111111), letterSpacing: 0)),
                  TextSpan(text: 'Story',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                          color: Color(0xFF111111), letterSpacing: 0)),
                ]),
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
                        onRefresh: _loadStories,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _stories.length,
                          separatorBuilder: (_, __) =>
                              Container(height: 8, color: const Color(0xFFF5F5F5)),
                          itemBuilder: (_, i) =>
                              _StoryCard(data: _stories[i], me: _me),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
      ]),
    );
  }
}

class _StoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? me;
  const _StoryCard({required this.data, required this.me});

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    // Verifica se já curtiu
    final myId = widget.me?['id']?.toString() ?? '';
    final likes = (widget.data['likes'] as List?) ?? [];
    _liked = likes.contains(myId);
  }

  Future<void> _toggleLike() async {
    final myId = widget.me?['id']?.toString() ?? '';
    if (myId.isEmpty) return;

    final storyId = widget.data['id'];
    final likes = List<dynamic>.from(widget.data['likes'] ?? []);

    if (_liked) {
      likes.remove(myId);
    } else {
      likes.add(myId);
    }

    setState(() {
      _liked = !_liked;
      widget.data['likes'] = likes;
    });

    try {
      await Supabase.instance.client
          .from('stories')
          .update({'likes': likes}).eq('id', storyId);
    } catch (e) {
      // Reverte se falhar
      setState(() {
        _liked = !_liked;
        if (_liked) likes.add(myId); else likes.remove(myId);
        widget.data['likes'] = likes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['user_name'] as String? ?? '';
    final mediaUrl = widget.data['media_url'] as String? ?? '';
    final mediaType = widget.data['media_type'] as String? ?? 'photo';
    final caption = widget.data['caption'] as String? ?? '';
    final createdAt = widget.data['created_at'] as String? ?? '';
    final isMyStory = widget.data['user_id'] == widget.me?['id']?.toString();
    final likesCount = ((widget.data['likes'] as List?) ?? []).length;

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600, color: Color(0xFF111111), letterSpacing: 0)),
              Text(_formatDate(createdAt),
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF8D8D93), letterSpacing: 0)),
            ]),
          ),
          if (isMyStory)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFAAAAAA), size: 22),
              onPressed: () async {
                await Supabase.instance.client
                    .from('stories')
                    .delete()
                    .eq('id', widget.data['id']);
              },
            )
          else
            const Icon(Icons.more_horiz, color: Color(0xFFAAAAAA), size: 22),
        ]),

        // Caption acima da foto
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(caption,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111111),
                  letterSpacing: 0, height: 1.4)),
        ],

        const SizedBox(height: 12),

        // Mídia
        _buildMedia(mediaUrl, mediaType),

        const SizedBox(height: 12),

        // Reações
        Row(children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(children: [
              Icon(
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: const Color(0xFFE53935), size: 24,
              ),
              if (likesCount > 0) ...[
                const SizedBox(width: 4),
                Text('$likesCount',
                    style: const TextStyle(fontSize: 13,
                        color: Color(0xFF888888), letterSpacing: 0)),
              ],
            ]),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showCommentSheet(context),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF888888), size: 24),
          ),
        ]),
      ]),
    );
  }

  void _showCommentSheet(BuildContext context) {
    final ctrl = TextEditingController();
    final name = widget.data['user_name'] as String? ?? '';
    final userId = int.tryParse(widget.data['user_id'] ?? '');

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
          Text('Responder para $name',
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

  Widget _buildMedia(String url, String type) {
    if (url.isEmpty) return _mediaPlaceholder();
    if (type == 'photo') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url,
          width: double.infinity, height: 280, fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 280,
              decoration: BoxDecoration(color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: CircularProgressIndicator(color: _kLineGreen)),
            );
          },
          errorBuilder: (_, __, ___) => _mediaPlaceholder(),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(alignment: Alignment.center, children: [
        Container(height: 280, width: double.infinity, color: Colors.black),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 32),
        ),
      ]),
    );
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

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
      if (diff.inHours < 24) return '${diff.inHours}h atrás';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }
}
